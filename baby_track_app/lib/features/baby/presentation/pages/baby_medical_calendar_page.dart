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
          .map((event) => triggeredEvents.any((triggered) => triggered.id == event.id)
              ? event.copyWith(reminderSentAt: DateTime.now())
              : event)
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
    return _events
        .where((event) => event.scheduledAt.isAfter(now))
        .toList()
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

    final baseEvent = event ??
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _EventFormSheet(
            baby: widget.baby,
            event: baseEvent,
            eventLabels: _eventLabels,
          ),
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
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agenda médica'),
            Text(
              widget.baby.name,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.baby.id == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openEventForm,
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Nuevo evento'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 20),
                  _buildCalendar(theme),
                  const SizedBox(height: 24),
                  if (_upcomingEvents.isNotEmpty) _buildUpcomingSection(theme),
                  if (_upcomingEvents.isNotEmpty) const SizedBox(height: 24),
                  _buildSelectedDaySection(theme, colorScheme),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final textTheme = theme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planifica vacunas y citas de ${widget.baby.name}',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Activa recordatorios automáticos para preparar con antelación cada visita médica.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    final firstDate = widget.baby.birthDate.subtract(const Duration(days: 30));
    final lastDate = DateTime.now().add(const Duration(days: 365 * 5));
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: CalendarDatePicker(
          key: ValueKey(_selectedDay.millisecondsSinceEpoch),
          firstDate: firstDate,
          lastDate: lastDate,
          initialDate: _selectedDay,
          onDateChanged: (date) {
            setState(() {
              _selectedDay = DateTime(date.year, date.month, date.day);
            });
          },
          currentDate: DateTime.now(),
          onDisplayedMonthChanged: (date) {
            setState(() {
              _focusedDay = date;
            });
          },
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(ThemeData theme) {
    final textTheme = theme.textTheme;
    final events = _upcomingEvents.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos recordatorios',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...events.map((event) => _UpcomingEventTile(
              event: event,
              label: _eventLabels[event.eventType] ?? 'Evento',
              color: _eventColor(event.eventType, theme),
              onTap: () {
                setState(() {
                  _selectedDay = DateTime(
                    event.scheduledAt.year,
                    event.scheduledAt.month,
                    event.scheduledAt.day,
                  );
                  _focusedDay = _selectedDay;
                });
              },
            )),
      ],
    );
  }

  Widget _buildSelectedDaySection(ThemeData theme, ColorScheme colorScheme) {
    final textTheme = theme.textTheme;
    final events = _eventsForSelectedDay;

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDayLabel(_selectedDay),
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'No hay eventos médicos registrados para este día.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: widget.baby.id == null ? null : _openEventForm,
              icon: const Icon(Icons.add),
              label: const Text('Crear evento'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_available_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              _formatDayLabel(_selectedDay),
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...events.map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Dismissible(
              key: ValueKey(event.id ?? event.title + event.scheduledAt.toIso8601String()),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                await _deleteEvent(event);
                return false;
              },
              child: _EventCard(
                event: event,
                label: _eventLabels[event.eventType] ?? 'Evento',
                color: _eventColor(event.eventType, theme),
                onTap: () => _openEventForm(event: event),
              ),
            ),
          ),
        ),
      ],
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
                    Expanded(
                      child: Text(event.location!, style: textTheme.bodyMedium),
                    ),
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
  const _EventFormSheet({
    required this.baby,
    required this.event,
    required this.eventLabels,
  });

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
        _scheduledAt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, _scheduledAt.hour, _scheduledAt.minute);
        _dateController.text = DateFormat('d MMMM yyyy · HH:mm', 'es').format(_scheduledAt);
      });
      return;
    }

    setState(() {
      _scheduledAt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
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
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
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
