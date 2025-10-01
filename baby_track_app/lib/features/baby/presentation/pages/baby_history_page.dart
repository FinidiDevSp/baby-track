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
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
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
        title: Row(
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
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: sortedDays.length,
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
    final totalMl = dayLogs.fold<int>(0, (sum, log) => sum + (log.intakeMl ?? 0));
    final avgMl = dayLogs.isNotEmpty ? (totalMl / dayLogs.length).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del día
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatDayHeader(dayKey),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${dayLogs.length} registro${dayLogs.length != 1 ? 's' : ''}',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (totalMl > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.local_drink, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Total: ${totalMl}ml • Promedio: ${avgMl}ml',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Lista de registros del día
          ...dayLogs.asMap().entries.map((entry) {
            final index = entry.key;
            final log = entry.value;
            final isLast = index == dayLogs.length - 1;
            return _buildLogItem(log, colorScheme, textTheme, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildLogItem(
    BabyDailyLog log,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isLast,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3), width: 1),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.access_time, color: colorScheme.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('HH:mm').format(log.loggedAt),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (log.intakeMl != null && log.intakeMl! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.local_drink, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${log.intakeMl} ml',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
                if (log.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.notes!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
