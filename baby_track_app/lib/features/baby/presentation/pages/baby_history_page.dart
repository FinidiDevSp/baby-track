import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:baby_track_app/features/baby/domain/models/baby_daily_log.dart';
import 'package:baby_track_app/features/baby/domain/repositories/baby_daily_log_repository.dart';
import 'package:baby_track_app/features/baby/infrastructure/baby_daily_log_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BabyHistoryPage extends StatefulWidget {
  const BabyHistoryPage({super.key, required this.baby});

  final Baby baby;

  @override
  State<BabyHistoryPage> createState() => _BabyHistoryPageState();
}

class _BabyHistoryPageState extends State<BabyHistoryPage> {
  final BabyDailyLogRepository _logRepository = BabyDailyLogRepositoryImpl();
  List<BabyDailyLog> _allLogs = [];
  final Map<String, List<BabyDailyLog>> _groupedLogs = {};
  final Set<String> _collapsedDays = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllLogs();
  }

  Future<void> _loadAllLogs() async {
    if (widget.baby.id == null) return;

    setState(() => _isLoading = true);

    try {
      final logs = await _logRepository.getAllLogsForBaby(widget.baby.id!);
      _allLogs = logs;
      _groupLogsByDay();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar el historial: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _groupLogsByDay() {
    _groupedLogs.clear();

    for (final log in _allLogs) {
      final dayKey = DateFormat('yyyy-MM-dd').format(log.logDay);
      if (_groupedLogs.containsKey(dayKey)) {
        _groupedLogs[dayKey]!.add(log);
      } else {
        _groupedLogs[dayKey] = [log];
      }
    }

    // Ordenar logs dentro de cada día por hora
    for (final dayLogs in _groupedLogs.values) {
      dayLogs.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    }

    _collapsedDays.removeWhere((day) => !_groupedLogs.containsKey(day));
  }

  String _formatDayHeader(String dayKey) {
    final date = DateTime.parse(dayKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Hoy - ${DateFormat('d MMM yyyy', 'es').format(date)}';
    } else if (targetDate == yesterday) {
      return 'Ayer - ${DateFormat('d MMM yyyy', 'es').format(date)}';
    } else {
      return DateFormat('EEEE, d MMM yyyy', 'es').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildCustomAppBar(context, colorScheme),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.surface, colorScheme.surface.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _groupedLogs.isEmpty
              ? _buildEmptyState(colorScheme, textTheme)
              : _buildHistoryList(colorScheme, textTheme),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 72,
      leadingWidth: 64,
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.history_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Historial',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Registro de ${widget.baby.name}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 64,
                color: colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin registros aún',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Comienza a crear registros diarios para ${widget.baby.name} y aparecerán aquí organizados por días.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(ColorScheme colorScheme, TextTheme textTheme) {
    final sortedDays = _groupedLogs.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Días más recientes primero

    return RefreshIndicator(
      onRefresh: _loadAllLogs,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: sortedDays.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final dayKey = sortedDays[index];
          final dayLogs = _groupedLogs[dayKey]!;
          return _buildDaySection(dayKey, dayLogs, colorScheme, textTheme);
        },
      ),
    );
  }

  Widget _buildDaySection(
    String dayKey,
    List<BabyDailyLog> dayLogs,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isCollapsed = _collapsedDays.contains(dayKey);
    final summaryChips = <Widget>[];
    List<BabyDailyLog> timelineLogs = const <BabyDailyLog>[];

    if (!isCollapsed) {
      final feedLogs = dayLogs.where((log) => (log.intakeMl ?? 0) > 0).toList();
      final totalMl = feedLogs.fold<int>(0, (sum, log) => sum + (log.intakeMl ?? 0));
      final diaperCount = dayLogs.where((log) => log.didPoop).length;
      final vomitCount = dayLogs.where((log) => log.vomited).length;
      final showerCount = dayLogs.where((log) => log.showered).length;
      final notesCount = dayLogs.where((log) => log.notes?.isNotEmpty == true).length;

      summaryChips.addAll([
        _buildSummaryChip(
          icon: Icons.event_note_rounded,
          label: _pluralize(dayLogs.length, singular: 'registro', plural: 'registros'),
          color: colorScheme.primary,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        if (feedLogs.isNotEmpty)
          _buildSummaryChip(
            icon: Icons.local_drink_rounded,
            label:
                '${_pluralize(feedLogs.length, singular: 'toma', plural: 'tomas')} · ${totalMl} ml',
            color: colorScheme.primary,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        if (diaperCount > 0)
          _buildSummaryChip(
            icon: Icons.baby_changing_station_rounded,
            label:
                _pluralize(diaperCount, singular: 'pañal sucio', plural: 'pañales sucios'),
            color: colorScheme.secondary,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        if (showerCount > 0)
          _buildSummaryChip(
            icon: Icons.bathtub_rounded,
            label: _pluralize(showerCount, singular: 'baño', plural: 'baños'),
            color: colorScheme.tertiary,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        if (vomitCount > 0)
          _buildSummaryChip(
            icon: Icons.sick_rounded,
            label: _pluralize(vomitCount, singular: 'vómito', plural: 'vómitos'),
            color: colorScheme.error,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        if (notesCount > 0)
          _buildSummaryChip(
            icon: Icons.sticky_note_2_rounded,
            label: _pluralize(notesCount, singular: 'nota', plural: 'notas'),
            color: colorScheme.outline,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
      ]);

      timelineLogs = [...dayLogs]
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    if (isCollapsed) {
                      _collapsedDays.remove(dayKey);
                    } else {
                      _collapsedDays.add(dayKey);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDayHeader(dayKey),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              DateFormat('d MMM yyyy', 'es').format(DateTime.parse(dayKey)),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isCollapsed ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!isCollapsed && summaryChips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summaryChips,
              ),
            ],
            if (!isCollapsed) ...[
              const SizedBox(height: 20),
              ...List.generate(timelineLogs.length, (index) {
                final log = timelineLogs[index];
                final isLast = index == timelineLogs.length - 1;
                return _buildTimelineEntry(log, isLast, colorScheme, textTheme);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineEntry(
    BabyDailyLog log,
    bool isLast,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final indicatorColor = _timelineColor(log, colorScheme);
    final eventChips = _buildEventChips(log, colorScheme, textTheme);
    final notes = log.notes;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: indicatorColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant.withOpacity(0.4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('HH:mm').format(log.loggedAt),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (eventChips.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: eventChips,
                      ),
                    ],
                    if (eventChips.isEmpty && (notes?.isNotEmpty != true)) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Registro sin detalles adicionales.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                    if (notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.sticky_note_2_rounded,
                              size: 16,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notes!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.75),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEventChips(
    BabyDailyLog log,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final chips = <Widget>[];
    final intake = log.intakeMl ?? 0;

    if (intake > 0) {
      chips.add(
        _buildEventChip(
          icon: Icons.local_drink_rounded,
          label: '${intake} ml',
          color: colorScheme.primary,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      );
    }
    if (log.didPoop) {
      chips.add(
        _buildEventChip(
          icon: Icons.baby_changing_station_rounded,
          label: 'Pañal sucio',
          color: colorScheme.secondary,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      );
    }
    if (log.showered) {
      chips.add(
        _buildEventChip(
          icon: Icons.bathtub_rounded,
          label: 'Baño',
          color: colorScheme.tertiary,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      );
    }
    if (log.vomited) {
      chips.add(
        _buildEventChip(
          icon: Icons.sick_rounded,
          label: 'Vómito',
          color: colorScheme.error,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      );
    }

    return chips;
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required Color color,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventChip({
    required IconData icon,
    required String label,
    required Color color,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _pluralize(
    int count, {
    required String singular,
    required String plural,
  }) {
    return '$count ${count == 1 ? singular : plural}';
  }

  Color _timelineColor(BabyDailyLog log, ColorScheme colorScheme) {
    if (log.vomited) {
      return colorScheme.error;
    }
    if (log.didPoop) {
      return colorScheme.secondary;
    }
    if (log.showered) {
      return colorScheme.tertiary;
    }
    if ((log.intakeMl ?? 0) > 0) {
      return colorScheme.primary;
    }
    return colorScheme.outline;
  }
}
