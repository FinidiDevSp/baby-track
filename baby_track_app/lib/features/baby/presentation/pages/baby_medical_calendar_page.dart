import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:baby_track_app/features/baby/domain/models/baby_medical_event.dart';
import 'package:baby_track_app/features/baby/infrastructure/baby_medical_event_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BabyMedicalCalendarPage extends StatefulWidget {
  const BabyMedicalCalendarPage({super.key, required this.baby});

  final Baby baby;

  @override
  State<BabyMedicalCalendarPage> createState() => _BabyMedicalCalendarPageState();
}

class _BabyMedicalCalendarPageState extends State<BabyMedicalCalendarPage> {
  final BabyMedicalEventRepositoryImpl _repository = BabyMedicalEventRepositoryImpl();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = false;
  List<BabyMedicalEvent> _events = const [];

  final Map<String, String> _eventLabels = const {
    'vaccine': 'Vacuna',
    'checkup': 'Chequeo pediátrico',
    'other': 'Otro',
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (widget.baby.id == null) {
      setState(() {
        _events = const [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final events = await _repository.getEventsForBaby(widget.baby.id!);
      if (!mounted) {
        return;
      }
      setState(() {
        _events = events;
      });
      await _checkUpcomingReminders(events);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkUpcomingReminders(List<BabyMedicalEvent> events) async {
    final now = DateTime.now();
    final triggeredEvents = <BabyMedicalEvent>[];

    for (final event in events) {
      if (!event.reminderEnabled || event.id == null) {
        continue;
      }
      if (event.reminderSentAt != null) {
        continue;
      }
      final reminderTime = event.scheduledAt.subtract(
        Duration(minutes: event.reminderMinutesBefore),
      );
      if (!now.isBefore(reminderTime) && now.isBefore(event.scheduledAt)) {
        triggeredEvents.add(event);
        await _repository.markReminderSent(event.id!);
      }
    }

    if (triggeredEvents.isEmpty || !mounted) {
      return;
    }

    final snackBar = SnackBar(
      content: Text(
        triggeredEvents.length == 1
            ? 'Recordatorio automático: ${triggeredEvents.first.title} hoy a las '
                  '${DateFormat('HH:mm').format(triggeredEvents.first.scheduledAt)}'
            : 'Tienes ${triggeredEvents.length} cuidados médicos próximos. Revísalos en la agenda.',
      ),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Ver',
        onPressed: () {
          final upcomingDay = triggeredEvents.first.scheduledAt;
          setState(() {
            _selectedDay = DateTime(upcomingDay.year, upcomingDay.month, upcomingDay.day);
            _focusedDay = _selectedDay;
          });
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    setState(() {
      _events = _events
          .map(
            (event) => triggeredEvents.any((triggered) => triggered.id == event.id)
                ? event.copyWith(reminderSentAt: DateTime.now())
                : event,
          )
          .toList();
    });
  }

  List<BabyMedicalEvent> get _eventsForSelectedDay {
    return _events
        .where((event) => _isSameDay(event.scheduledAt, _selectedDay))
        .toList(growable: false);
  }

  List<BabyMedicalEvent> get _upcomingEvents {
    final now = DateTime.now();
    return _events.where((event) => event.scheduledAt.isAfter(now)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDayLabel(DateTime date) {
    final formatter = DateFormat('EEEE d MMMM', 'es');
    return formatter.format(date);
  }

  Color _eventColor(String type, ThemeData theme) {
    switch (type) {
      case 'vaccine':
        return theme.colorScheme.primary;
      case 'checkup':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.tertiary;
    }
  }

  Future<void> _openEventForm({BabyMedicalEvent? event}) async {
    if (widget.baby.id == null) {
      return;
    }

    final baseEvent =
        event ??
        BabyMedicalEvent(
          babyId: widget.baby.id!,
          title: '',
          eventType: 'vaccine',
          scheduledAt: _selectedDay,
          reminderEnabled: true,
          reminderMinutesBefore: 1440,
          createdAt: DateTime.now(),
        );

    final result = await showModalBottomSheet<BabyMedicalEvent>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _EventFormSheet(baby: widget.baby, event: baseEvent, eventLabels: _eventLabels),
        );
      },
    );

    if (result == null) {
      return;
    }

    if (event == null) {
      await _repository.createEvent(result);
    } else {
      await _repository.updateEvent(result);
    }

    await _loadEvents();
  }

  Future<void> _deleteEvent(BabyMedicalEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar evento'),
          content: Text('¿Quieres eliminar "${event.title}" de la agenda médica?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    if (event.id != null) {
      await _repository.deleteEvent(event.id!);
      await _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildCustomAppBar(context, colorScheme),
      floatingActionButton: widget.baby.id == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openEventForm,
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Nueva cita'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildCompactCalendar(colorScheme),
                    const SizedBox(height: 24),
                    _buildAppointmentsSections(colorScheme),
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 50,
      leadingWidth: 56,
      titleSpacing: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          tooltip: 'Volver',
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.85),
              colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Agenda Médica',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              widget.baby.name,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(ColorScheme colorScheme) {
    final now = DateTime.now();
    final upcomingEvents = _events.where((e) => e.scheduledAt.isAfter(now)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final pastEvents = _events.where((e) => e.scheduledAt.isBefore(now)).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorScheme.primary.withOpacity(0.1), colorScheme.surface],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    title: 'Próximas',
                    count: upcomingEvents.length,
                    icon: Icons.schedule_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOverviewCard(
                    title: 'Realizadas',
                    count: pastEvents.length,
                    icon: Icons.check_circle_rounded,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            if (upcomingEvents.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildNextAppointmentCard(upcomingEvents.first, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentCard(BabyMedicalEvent event, ColorScheme colorScheme) {
    final color = _eventColor(event.eventType, Theme.of(context));
    final daysUntil = event.scheduledAt.difference(DateTime.now()).inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Icon(
              event.eventType == 'vaccine' ? Icons.vaccines : Icons.medical_services,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próxima cita',
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                ),
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${DateFormat('d MMM yyyy · HH:mm', 'es').format(event.scheduledAt)} ${daysUntil > 0 ? '($daysUntil días)' : '(Hoy)'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCalendar(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'es').format(_focusedDay),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                      });
                    },
                    icon: Icon(Icons.chevron_left, color: colorScheme.primary),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                      });
                    },
                    icon: Icon(Icons.chevron_right, color: colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCompactCalendarGrid(colorScheme),
        ],
      ),
    );
  }

  Widget _buildCompactCalendarGrid(ColorScheme colorScheme) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return Column(
      children: [
        // Week headers
        Row(
          children: ['D', 'L', 'M', 'X', 'J', 'V', 'S']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        ...List.generate(6, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstDayWeekday + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }

              final date = DateTime(_focusedDay.year, _focusedDay.month, dayNumber);
              final hasEvents = _events.any((e) => _isSameDay(e.scheduledAt, date));
              final isSelected = _isSameDay(date, _selectedDay);
              final isToday = _isSameDay(date, now);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = date;
                    });
                  },
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : isToday
                          ? colorScheme.primary.withOpacity(0.1)
                          : hasEvents
                          ? colorScheme.secondary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: hasEvents && !isSelected
                          ? Border.all(color: colorScheme.secondary, width: 1.5)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                  ? colorScheme.primary
                                  : hasEvents
                                  ? colorScheme.secondary
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (hasEvents && !isSelected)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colorScheme.secondary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }).where((row) {
          // Only show weeks that have days from current month
          return row.children.any((child) => (child as Expanded).child is! SizedBox);
        }),
      ],
    );
  }

  Widget _buildAppointmentsSections(ColorScheme colorScheme) {
    final now = DateTime.now();
    final upcomingEvents = _events.where((e) => e.scheduledAt.isAfter(now)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final pastEvents = _events.where((e) => e.scheduledAt.isBefore(now)).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upcomingEvents.isNotEmpty) ...[
            _buildSectionTitle('Próximas Citas', upcomingEvents.length, colorScheme.primary),
            const SizedBox(height: 12),
            ...upcomingEvents.take(3).map((event) => _buildEventCard(event, colorScheme, true)),
            if (upcomingEvents.length > 3) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to full upcoming list
                  },
                  child: Text('Ver todas (${upcomingEvents.length - 3} más)'),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
          if (pastEvents.isNotEmpty) ...[
            _buildSectionTitle('Historial', pastEvents.length, colorScheme.secondary),
            const SizedBox(height: 12),
            ...pastEvents.take(3).map((event) => _buildEventCard(event, colorScheme, false)),
            if (pastEvents.length > 3) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to full past list
                  },
                  child: Text('Ver todo el historial (${pastEvents.length - 3} más)'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            title.contains('Próximas') ? Icons.schedule : Icons.history,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BabyMedicalEvent event, ColorScheme colorScheme, bool isUpcoming) {
    final color = _eventColor(event.eventType, Theme.of(context));
    final now = DateTime.now();
    final daysDiff = isUpcoming
        ? event.scheduledAt.difference(now).inDays
        : now.difference(event.scheduledAt).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              event.eventType == 'vaccine' ? Icons.vaccines : Icons.medical_services,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy · HH:mm', 'es').format(event.scheduledAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (daysDiff >= 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    isUpcoming
                        ? (daysDiff == 0 ? 'Hoy' : 'En $daysDiff días')
                        : (daysDiff == 0 ? 'Hoy' : 'Hace $daysDiff días'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUpcoming ? color : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                _openEventForm(event: event);
              } else if (action == 'delete') {
                _deleteEvent(event);
              }
            },
            itemBuilder: (context) {
              final now = DateTime.now();
              final canDelete = isUpcoming || now.difference(event.scheduledAt).inDays >= 7;

              return [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Editar')],
                  ),
                ),
                if (canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16),
                        SizedBox(width: 8),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
              ];
            },
            child: Icon(Icons.more_vert, color: Colors.grey[400], size: 18),
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventTile extends StatelessWidget {
  const _UpcomingEventTile({
    required this.event,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final BabyMedicalEvent event;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('d MMM · HH:mm', 'es').format(event.scheduledAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
          child: const Icon(Icons.vaccines_outlined),
        ),
        title: Text(event.title.isEmpty ? label : event.title),
        subtitle: Text('$dateLabel · $label'),
        trailing: event.reminderEnabled
            ? Icon(Icons.alarm, color: theme.colorScheme.primary)
            : null,
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final BabyMedicalEvent event;
  final String label;
  final Color color;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.vaccines, color: color, size: 18),
                        const SizedBox(width: 6),
                        Text(label, style: textTheme.bodyMedium?.copyWith(color: color)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (event.reminderEnabled)
                    Row(
                      children: [
                        Icon(Icons.alarm, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('Recordatorio', style: textTheme.labelMedium),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                event.title.isEmpty ? 'Sin título' : event.title,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (event.location != null && event.location!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(event.location!, style: textTheme.bodyMedium)),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 6),
                  Text(_formatDate(event.scheduledAt), style: textTheme.bodyMedium),
                ],
              ),
              if (event.notes != null && event.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(event.notes!, style: textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EventFormSheet extends StatefulWidget {
  const _EventFormSheet({required this.baby, required this.event, required this.eventLabels});

  final Baby baby;
  final BabyMedicalEvent event;
  final Map<String, String> eventLabels;

  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  late final TextEditingController _dateController;
  late DateTime _scheduledAt;
  late String _eventType;
  late bool _reminderEnabled;
  late int _reminderMinutesBefore;

  final _formKey = GlobalKey<FormState>();

  final List<int> _reminderOptions = const [60, 180, 720, 1440, 2880];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _locationController = TextEditingController(text: widget.event.location ?? '');
    _notesController = TextEditingController(text: widget.event.notes ?? '');
    _scheduledAt = widget.event.scheduledAt;
    _eventType = widget.event.eventType;
    _reminderEnabled = widget.event.reminderEnabled;
    _reminderMinutesBefore = widget.event.reminderMinutesBefore;
    _dateController = TextEditingController(
      text: DateFormat('d MMMM yyyy · HH:mm', 'es').format(_scheduledAt),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: widget.baby.birthDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('es'),
    );

    if (pickedDate == null) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );

    if (pickedTime == null) {
      setState(() {
        _scheduledAt = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _scheduledAt.hour,
          _scheduledAt.minute,
        );
        _dateController.text = DateFormat('d MMMM yyyy · HH:mm', 'es').format(_scheduledAt);
      });
      return;
    }

    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _dateController.text = DateFormat('d MMMM yyyy · HH:mm', 'es').format(_scheduledAt);
    });
  }

  String _formatReminderLabel(int minutes) {
    if (minutes >= 1440) {
      final days = (minutes / 1440).round();
      return '$days ${days == 1 ? 'día' : 'días'} antes';
    }
    if (minutes >= 60) {
      final hours = (minutes / 60).round();
      return '$hours ${hours == 1 ? 'hora' : 'horas'} antes';
    }
    return '$minutes min antes';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final event = widget.event.copyWith(
      babyId: widget.baby.id,
      title: _titleController.text.trim(),
      eventType: _eventType,
      scheduledAt: _scheduledAt,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      reminderEnabled: _reminderEnabled,
      reminderMinutesBefore: _reminderMinutesBefore,
      reminderSentAt: _reminderEnabled ? null : widget.event.reminderSentAt,
    );

    Navigator.of(context).pop(event);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.event.id == null ? 'Nuevo evento médico' : 'Editar evento',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej. Vacuna pentavalente',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un título para el evento';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _eventType,
              decoration: const InputDecoration(labelText: 'Tipo de evento'),
              items: widget.eventLabels.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _eventType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Fecha y hora',
                suffixIcon: Icon(Icons.calendar_month),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lugar (opcional)',
                hintText: 'Ej. Centro de salud',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Indicaciones o preparación previa',
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _reminderEnabled,
              title: const Text('Activar recordatorio automático'),
              subtitle: const Text('Recibirás una alerta antes del evento.'),
              onChanged: (value) {
                setState(() {
                  _reminderEnabled = value;
                });
              },
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _reminderMinutesBefore,
                decoration: const InputDecoration(labelText: 'Anticipación del recordatorio'),
                items: _reminderOptions
                    .map(
                      (minutes) => DropdownMenuItem<int>(
                        value: minutes,
                        child: Text(_formatReminderLabel(minutes)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _reminderMinutesBefore = value;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
