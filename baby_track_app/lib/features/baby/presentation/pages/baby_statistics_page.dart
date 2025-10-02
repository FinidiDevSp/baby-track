import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:baby_track_app/features/baby/domain/models/baby_daily_log.dart';
import 'package:baby_track_app/features/baby/infrastructure/baby_daily_log_repository_impl.dart';
import 'package:baby_track_app/shared/widgets/app_bars/baby_gradient_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BabyStatisticsPage extends StatefulWidget {
  const BabyStatisticsPage({super.key, required this.baby});

  final Baby baby;

  @override
  State<BabyStatisticsPage> createState() => _BabyStatisticsPageState();
}

class _BabyStatisticsPageState extends State<BabyStatisticsPage> {
  final BabyDailyLogRepositoryImpl _repository = BabyDailyLogRepositoryImpl();

  bool _isLoading = false;
  List<BabyDailyLog> _recentLogs = const [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (widget.baby.id == null) {
      setState(() {
        _recentLogs = const [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await _repository.getRecentLogsForBaby(widget.baby.id!, limit: 180);
      if (!mounted) {
        return;
      }
      setState(() {
        _recentLogs = logs;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const BabyGradientAppBar(
        title: 'Estadísticas',
        subtitle: 'Tendencias de cuidados diarios',
        icon: Icons.query_stats_rounded,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        displacement: 32,
        child: widget.baby.id == null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                children: [
                  _StatsEmptyState(
                    icon: Icons.assignment_ind_outlined,
                    message:
                        'Guarda el perfil de ${widget.baby.name} para poder analizar sus rutinas y hábitos.',
                  ),
                ],
              )
            : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recentLogs.isEmpty
                    ? ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                        children: const [
                          _StatsEmptyState(
                            icon: Icons.insights_outlined,
                            message:
                                'Registra las tomas, pañales y demás actividades para visualizar estadísticas aquí.',
                          ),
                        ],
                      )
                    : ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        children: _buildStatsCards(context),
                      ),
      ),
    );
  }

  List<Widget> _buildStatsCards(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final groupedByDay = <DateTime, List<BabyDailyLog>>{};
    for (final log in _recentLogs) {
      final day = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
      groupedByDay.putIfAbsent(day, () => []).add(log);
    }

    final days = groupedByDay.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final summaries = days.map((day) {
      final logs = groupedByDay[day] ?? [];
      final intakeLogs = logs.where((log) => (log.intakeMl ?? 0) > 0).toList();
      final feedCount = intakeLogs.length;
      final totalIntake = intakeLogs.fold<int>(0, (sum, log) => sum + (log.intakeMl ?? 0));
      final poopCount = logs.where((log) => log.didPoop).length;
      final showerCount = logs.where((log) => log.showered).length;
      final vomitCount = logs.where((log) => log.vomited).length;
      final notesCount = logs.where((log) => (log.notes ?? '').isNotEmpty).length;

      return _DailySummary(
        day: day,
        feedCount: feedCount,
        totalIntake: totalIntake,
        poopCount: poopCount,
        showerCount: showerCount,
        vomitCount: vomitCount,
        notesCount: notesCount,
      );
    }).toList();

    final lastSeven = summaries.take(7).toList();
    final weeklyAverageFeed = lastSeven.isEmpty
        ? 0
        : lastSeven.map((summary) => summary.feedCount).reduce((a, b) => a + b) /
            lastSeven.length;

    final weeklyAverageIntake = lastSeven.isEmpty
        ? 0
        : lastSeven.map((summary) => summary.totalIntake).reduce((a, b) => a + b) /
            lastSeven.length;

    final cards = <Widget>[
      _StatsOverviewCard(
        averageFeeds: weeklyAverageFeed,
        averageIntake: weeklyAverageIntake,
        trendLabel: _buildTrendLabel(weeklyAverageFeed),
      ),
      const SizedBox(height: 24),
      Text(
        'Resumen diario (últimos 30 días)',
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
    ];

    cards.addAll(
      summaries.take(30).map((summary) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _DailyStatsCard(summary: summary, colorScheme: colorScheme),
        );
      }),
    );

    return cards;
  }

  String _buildTrendLabel(double averageFeeds) {
    if (averageFeeds == 0) {
      return 'Aún sin datos suficientes para mostrar tendencias.';
    }
    if (averageFeeds < 5) {
      return 'Rutina tranquila. La media es de ${averageFeeds.toStringAsFixed(1)} tomas por día.';
    }
    if (averageFeeds < 8) {
      return 'Excelente ritmo. ${averageFeeds.toStringAsFixed(1)} tomas diarias en promedio.';
    }
    return 'Alta demanda. ${averageFeeds.toStringAsFixed(1)} tomas al día en la última semana.';
  }
}

class _StatsOverviewCard extends StatelessWidget {
  const _StatsOverviewCard({
    required this.averageFeeds,
    required this.averageIntake,
    required this.trendLabel,
  });

  final double averageFeeds;
  final double averageIntake;
  final String trendLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary.withOpacity(0.12), Colors.white],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Promedios de la última semana',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _OverviewMetric(
                label: 'Tomas diarias',
                value: averageFeeds == 0 ? '—' : averageFeeds.toStringAsFixed(1),
                icon: Icons.local_drink_rounded,
                color: colorScheme.primary,
              ),
              _OverviewMetric(
                label: 'Cantidad promedio',
                value: averageIntake == 0 ? '—' : '${averageIntake.toStringAsFixed(0)} ml',
                icon: Icons.scale_rounded,
                color: colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            trendLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.75),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyStatsCard extends StatelessWidget {
  const _DailyStatsCard({required this.summary, required this.colorScheme});

  final _DailySummary summary;
  final ColorScheme colorScheme;

  String _formatDate(DateTime day) {
    final formatter = DateFormat('EEE d MMM', 'es');
    return formatter.format(day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                _formatDate(summary.day).toUpperCase(),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _StatChip(
                icon: Icons.local_cafe_rounded,
                color: colorScheme.primary,
                label: summary.feedCount == 1
                    ? '1 toma'
                    : '${summary.feedCount} tomas',
              ),
              _StatChip(
                icon: Icons.local_drink_rounded,
                color: colorScheme.secondary,
                label: summary.totalIntake == 0
                    ? 'Sin registro de ml'
                    : '${summary.totalIntake} ml',
              ),
              _StatChip(
                icon: Icons.baby_changing_station_rounded,
                color: colorScheme.tertiary,
                label: summary.poopCount == 1
                    ? '1 pañal'
                    : '${summary.poopCount} pañales',
              ),
              _StatChip(
                icon: Icons.bathtub_rounded,
                color: colorScheme.primaryContainer,
                label: summary.showerCount == 1
                    ? '1 baño'
                    : '${summary.showerCount} baños',
              ),
              _StatChip(
                icon: Icons.sick_rounded,
                color: colorScheme.error,
                label: summary.vomitCount == 0
                    ? 'Sin vómitos'
                    : '${summary.vomitCount} ${summary.vomitCount == 1 ? 'vómito' : 'vómitos'}',
              ),
              if (summary.notesCount > 0)
                _StatChip(
                  icon: Icons.sticky_note_2_rounded,
                  color: colorScheme.outline,
                  label: summary.notesCount == 1
                      ? '1 nota registrada'
                      : '${summary.notesCount} notas registradas',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _DailySummary {
  const _DailySummary({
    required this.day,
    required this.feedCount,
    required this.totalIntake,
    required this.poopCount,
    required this.showerCount,
    required this.vomitCount,
    required this.notesCount,
  });

  final DateTime day;
  final int feedCount;
  final int totalIntake;
  final int poopCount;
  final int showerCount;
  final int vomitCount;
  final int notesCount;
}

class _StatsEmptyState extends StatelessWidget {
  const _StatsEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Sin estadísticas por ahora',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
