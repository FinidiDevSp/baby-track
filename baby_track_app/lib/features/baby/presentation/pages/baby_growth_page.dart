import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:baby_track_app/features/baby/domain/models/baby_growth_record.dart';
import 'package:baby_track_app/features/baby/infrastructure/baby_growth_record_repository_impl.dart';
import 'package:baby_track_app/shared/widgets/app_bars/baby_gradient_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BabyGrowthPage extends StatefulWidget {
  const BabyGrowthPage({super.key, required this.baby});

  final Baby baby;

  @override
  State<BabyGrowthPage> createState() => _BabyGrowthPageState();
}

class _BabyGrowthPageState extends State<BabyGrowthPage> {
  final BabyGrowthRecordRepositoryImpl _repository = BabyGrowthRecordRepositoryImpl();

  bool _isLoading = false;
  List<BabyGrowthRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    if (widget.baby.id == null) {
      setState(() {
        _records = const [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final records = await _repository.getRecordsForBaby(widget.baby.id!);
      if (!mounted) {
        return;
      }
      setState(() {
        _records = records;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const BabyGradientAppBar(
        title: 'Crecimiento',
        subtitle: 'Seguimiento de medidas y percentiles',
        icon: Icons.monitor_weight_rounded,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        displacement: 32,
        child: widget.baby.id == null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                children: [
                  _EmptyStateCard(
                    icon: Icons.assignment_ind_rounded,
                    title: 'Registra primero a tu bebé',
                    message:
                        'Guarda el perfil de ${widget.baby.name} para comenzar a documentar su crecimiento.',
                  ),
                ],
              )
            : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                        children: const [
                          _EmptyStateCard(
                            icon: Icons.auto_graph_rounded,
                            title: 'Aún no hay mediciones',
                            message:
                                'Registra las revisiones pediátricas para ver aquí la evolución de peso, talla y perímetro craneal.',
                          ),
                        ],
                      )
                    : ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        children: _buildGroupedRecords(theme),
                      ),
      ),
    );
  }

  List<Widget> _buildGroupedRecords(ThemeData theme) {
    final formatter = DateFormat('MMMM yyyy', 'es');
    final grouped = <String, List<BabyGrowthRecord>>{};
    for (final record in _records) {
      final key = formatter.format(record.recordedAt).toUpperCase();
      grouped.putIfAbsent(key, () => []).add(record);
    }

    return grouped.entries
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...entry.value.map((record) => _GrowthRecordCard(record: record)).toList(),
              ],
            ),
          ),
        )
        .toList(growable: false);
  }
}

class _GrowthRecordCard extends StatelessWidget {
  const _GrowthRecordCard({required this.record});

  final BabyGrowthRecord record;

  String _formatDate(DateTime date) {
    final formatter = DateFormat('d MMM yyyy', 'es');
    return formatter.format(date);
  }

  String _formatMeasurement(double? value, String unit) {
    if (value == null) {
      return 'Sin dato';
    }
    return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                _formatDate(record.recordedAt),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _MeasurementBlock(
            title: 'Perímetro craneal',
            valueLabel: _formatMeasurement(record.headCircumferenceCm, 'cm'),
            percentile: record.headCircumferencePercentile,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _MeasurementBlock(
            title: 'Altura',
            valueLabel: _formatMeasurement(record.heightCm, 'cm'),
            percentile: record.heightPercentile,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          _MeasurementBlock(
            title: 'Peso',
            valueLabel: _formatMeasurement(record.weightKg, 'kg'),
            percentile: record.weightPercentile,
            color: colorScheme.tertiary,
          ),
        ],
      ),
    );
  }
}

class _MeasurementBlock extends StatelessWidget {
  const _MeasurementBlock({
    required this.title,
    required this.valueLabel,
    required this.percentile,
    required this.color,
  });

  final String title;
  final String valueLabel;
  final double? percentile;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.stacked_line_chart_rounded, color: color),
            const SizedBox(width: 8),
            Text(
              valueLabel,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (percentile != null)
          _PercentileBar(percentile: percentile!, color: color)
        else
          Text(
            'Añade los percentiles para visualizar la curva de crecimiento.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
      ],
    );
  }
}

class _PercentileBar extends StatelessWidget {
  const _PercentileBar({required this.percentile, required this.color});

  final double percentile;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final clamped = percentile.clamp(0, 100).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widthFactor = constraints.maxWidth == 0
                  ? 0.0
                  : (clamped / 100).clamp(0.0, 1.0);
              final markerPosition = constraints.maxWidth * widthFactor;

              return Stack(
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                      ),
                      border: Border.all(color: color.withOpacity(0.35)),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: widthFactor,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [color, color.withOpacity(0.6)],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: markerPosition.clamp(12.0, constraints.maxWidth - 12),
                    top: 8,
                    child: _PercentileMarker(color: color),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Percentil ${clamped.toStringAsFixed(0)}',
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PercentileMarker extends StatelessWidget {
  const _PercentileMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
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
          Icon(icon, size: 44, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
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
