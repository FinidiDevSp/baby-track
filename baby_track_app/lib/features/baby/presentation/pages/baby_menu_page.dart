import 'dart:io';

import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:baby_track_app/features/baby/domain/models/baby_daily_log.dart';
import 'package:baby_track_app/features/baby/infrastructure/baby_daily_log_repository_impl.dart';
import 'package:baby_track_app/features/baby/presentation/pages/baby_daily_log_page.dart';
import 'package:baby_track_app/features/baby/presentation/pages/baby_history_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BabyMenuPage extends StatefulWidget {
  const BabyMenuPage({super.key, required this.baby});

  final Baby baby;

  @override
  State<BabyMenuPage> createState() => _BabyMenuPageState();
}

class _BabyMenuPageState extends State<BabyMenuPage> {
  final BabyDailyLogRepositoryImpl _dailyLogRepository = BabyDailyLogRepositoryImpl();

  bool _isLoadingStats = false;
  List<BabyDailyLog> _todayLogs = const [];
  List<BabyDailyLog> _recentLogs = const [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) {
      return;
    }

    if (widget.baby.id == null) {
      setState(() {
        _todayLogs = const [];
        _recentLogs = const [];
        _isLoadingStats = false;
      });
      return;
    }

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayLogs = await _dailyLogRepository.getLogsForBabyOnDate(widget.baby.id!, today);
      final recentLogs =
          await _dailyLogRepository.getRecentLogsForBaby(widget.baby.id!, limit: 60);

      if (!mounted) {
        return;
      }

      setState(() {
        _todayLogs = todayLogs;
        _recentLogs = recentLogs;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  LinearGradient _buildAppBarGradient(ColorScheme colorScheme) {
    final blendedColor =
        Color.lerp(colorScheme.primary, colorScheme.secondary, 0.5) ?? colorScheme.primary;

    return LinearGradient(
      colors: [colorScheme.primary, blendedColor, colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _formatAge() {
    final now = DateTime.now();
    final difference = now.difference(widget.baby.birthDate);

    if (difference.inDays < 30) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    }

    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mes' : 'meses'}';
    }

    final years = (difference.inDays / 365).floor();
    final remainingMonths = ((difference.inDays % 365) / 30).floor();
    if (remainingMonths == 0) {
      return '$years ${years == 1 ? 'año' : 'años'}';
    }
    return '$years ${years == 1 ? 'año' : 'años'} y $remainingMonths ${remainingMonths == 1 ? 'mes' : 'meses'}';
  }

  Color _genderColor(ColorScheme colorScheme) {
    switch (widget.baby.gender) {
      case 'M':
        return colorScheme.primary;
      case 'F':
        return colorScheme.secondary;
      default:
        return colorScheme.tertiary;
    }
  }

  BabyDailyLog? _findLastLog(bool Function(BabyDailyLog) predicate) {
    for (final log in _recentLogs) {
      if (predicate(log)) {
        return log;
      }
    }
    return null;
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'hace instantes';
    }

    if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      if (minutes == 0) {
        return 'hace ${hours} h';
      }
      return 'hace ${hours} h ${minutes} min';
    }

    final days = difference.inDays;
    if (days == 1) {
      return 'hace 1 día';
    }
    return 'hace $days días';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatEventSubtitle(BabyDailyLog? log, {String? detail}) {
    if (log == null) {
      return 'Aún no hay registros.';
    }

    final base = _timeAgo(log.loggedAt);
    final now = DateTime.now();
    final dateLabel = _isSameDay(now, log.loggedAt)
        ? DateFormat('HH:mm').format(log.loggedAt)
        : DateFormat('dd/MM HH:mm').format(log.loggedAt);

    if (detail != null && detail.isNotEmpty) {
      return '$base · $dateLabel · $detail';
    }
    return '$base · $dateLabel';
  }

  String _formatCountLabel(int count, {required String singular, required String plural}) {
    return '$count ${count == 1 ? singular : plural}';
  }

  @override
  Widget build(BuildContext context) {
    final baby = widget.baby;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
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
            gradient: _buildAppBarGradient(colorScheme),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.child_friendly_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Panel del bebé',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Organiza sus cuidados diarios',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.surface, colorScheme.surface.withOpacity(0.85)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -20,
                child: _DecorativeBubble(
                  size: 180,
                  color: colorScheme.secondary.withOpacity(0.25),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -30,
                child: _DecorativeBubble(
                  size: 140,
                  color: colorScheme.primary.withOpacity(0.18),
                ),
              ),
              RefreshIndicator(
                onRefresh: _loadStats,
                displacement: 32,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BabySummaryCard(
                        baby: baby,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        genderColor: _genderColor(colorScheme),
                        ageLabel: _formatAge(),
                      ),
                      const SizedBox(height: 24),
                      _BabyQuickActions(
                        onCreateLog: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BabyDailyLogPage(baby: baby),
                            ),
                          );
                          if (!mounted) {
                            return;
                          }
                          await _loadStats();
                        },
                        onViewHistory: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BabyHistoryPage(baby: baby),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      _buildStatsSection(colorScheme, textTheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(ColorScheme colorScheme, TextTheme textTheme) {
    if (widget.baby.id == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: colorScheme.outline),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Guarda primero el perfil de ${widget.baby.name} para comenzar a ver estadísticas.',
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    final lastIntake = _findLastLog((log) => (log.intakeMl ?? 0) > 0);
    final lastPoop = _findLastLog((log) => log.didPoop);
    final lastVomit = _findLastLog((log) => log.vomited);
    final lastShower = _findLastLog((log) => log.showered);

    String? intakeDetail;
    if (lastIntake != null && lastIntake.intakeMl != null) {
      intakeDetail = '${lastIntake.intakeMl} ml';
    }

    final todayIntakes =
        _todayLogs.where((log) => (log.intakeMl ?? 0) > 0).toList(growable: false);
    final feedCount = todayIntakes.length;
    final totalIntake = todayIntakes.fold<int>(0, (sum, log) => sum + (log.intakeMl ?? 0));
    final poopCount = _todayLogs.where((log) => log.didPoop).length;
    final vomitCount = _todayLogs.where((log) => log.vomited).length;
    final showerCount = _todayLogs.where((log) => log.showered).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BabyStatsCard(
          title: 'Última actividad',
          children: [
            _BabyStatTile(
              icon: Icons.local_drink_rounded,
              iconColor: colorScheme.primary,
              title: 'Tomas',
              subtitle: _formatEventSubtitle(lastIntake, detail: intakeDetail),
            ),
            const SizedBox(height: 12),
            _BabyStatTile(
              icon: Icons.baby_changing_station_rounded,
              iconColor: colorScheme.secondary,
              title: 'Pañales',
              subtitle: _formatEventSubtitle(lastPoop),
            ),
            const SizedBox(height: 12),
            _BabyStatTile(
              icon: Icons.sick_rounded,
              iconColor: colorScheme.error,
              title: 'Vómito',
              subtitle: _formatEventSubtitle(lastVomit),
            ),
            const SizedBox(height: 12),
            _BabyStatTile(
              icon: Icons.bathtub_rounded,
              iconColor: colorScheme.tertiary,
              title: 'Baños',
              subtitle: _formatEventSubtitle(lastShower),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _BabyStatsCard(
          title: 'Resumen de hoy',
          children: [
            _BabyStatTile(
              icon: Icons.local_cafe_rounded,
              iconColor: colorScheme.primary,
              title: 'Tomas registradas',
              subtitle: feedCount == 0
                  ? 'Aún no hay tomas registradas hoy.'
                  : '${_formatCountLabel(feedCount, singular: 'toma', plural: 'tomas')} · ${totalIntake} ml',
            ),
            const SizedBox(height: 12),
            _BabyStatTile(
              icon: Icons.eco_rounded,
              iconColor: colorScheme.secondary,
              title: 'Pañales sucios',
              subtitle: poopCount == 0
                  ? 'Sin pañales registrados por ahora.'
                  : _formatCountLabel(poopCount, singular: 'vez', plural: 'veces'),
            ),
            const SizedBox(height: 12),
            _BabyStatTile(
              icon: Icons.sick_rounded,
              iconColor: colorScheme.error,
              title: 'Vómitos',
              subtitle: vomitCount == 0
                  ? 'Sin vómitos registrados hoy.'
                  : _formatCountLabel(vomitCount, singular: 'vez', plural: 'veces'),
            ),
            const SizedBox(height: 12),
            _BabyStatTile(
              icon: Icons.water_drop_rounded,
              iconColor: colorScheme.tertiary,
              title: 'Baños',
              subtitle: showerCount == 0
                  ? 'Sin baños registrados hoy.'
                  : _formatCountLabel(showerCount, singular: 'baño', plural: 'baños'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BabySummaryCard extends StatelessWidget {
  const _BabySummaryCard({
    required this.baby,
    required this.colorScheme,
    required this.textTheme,
    required this.genderColor,
    required this.ageLabel,
  });

  final Baby baby;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Color genderColor;
  final String ageLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [colorScheme.primary.withOpacity(0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BabyAvatar(
                  baby: baby,
                  genderColor: genderColor,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        baby.name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoPill(
                        icon: Icons.calendar_month_rounded,
                        label: ageLabel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BabyQuickActions extends StatelessWidget {
  const _BabyQuickActions({
    required this.onCreateLog,
    required this.onViewHistory,
  });

  final VoidCallback onCreateLog;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.edit_note_rounded,
            label: 'Registro',
            color: colorScheme.primary,
            onTap: onCreateLog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.history_rounded,
            label: 'Historial',
            color: colorScheme.secondary,
            onTap: onViewHistory,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = color.withOpacity(0.12);
    final borderColor = color.withOpacity(0.25);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BabyAvatar extends StatelessWidget {
  const _BabyAvatar({
    required this.baby,
    required this.genderColor,
  });

  final Baby baby;
  final Color genderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: genderColor.withOpacity(0.15),
        border: Border.all(color: genderColor.withOpacity(0.25), width: 2),
      ),
      child: ClipOval(
        child: baby.photoPath != null && baby.photoPath!.isNotEmpty
            ? Image.file(
                File(baby.photoPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  baby.gender == 'M'
                      ? Icons.boy_rounded
                      : baby.gender == 'F'
                          ? Icons.girl_rounded
                          : Icons.child_care,
                  color: genderColor,
                  size: 36,
                ),
              )
            : Icon(
                baby.gender == 'M'
                    ? Icons.boy_rounded
                    : baby.gender == 'F'
                        ? Icons.girl_rounded
                        : Icons.child_care,
                color: genderColor,
                size: 36,
              ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
          ),
        ],
      ),
    );
  }
}

class _BabyStatsCard extends StatelessWidget {
  const _BabyStatsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _BabyStatTile extends StatelessWidget {
  const _BabyStatTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DecorativeBubble extends StatelessWidget {
  const _DecorativeBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
