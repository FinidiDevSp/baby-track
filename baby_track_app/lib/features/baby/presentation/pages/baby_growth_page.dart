import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:baby_track_app/features/baby/domain/models/baby_growth_record.dart';
import 'package:baby_track_app/features/baby/infrastructure/baby_growth_record_repository_impl.dart';
import 'package:baby_track_app/shared/widgets/app_bars/baby_gradient_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BabyGrowthPage extends StatefulWidget {
  const BabyGrowthPage({super.key, required this.baby});

  final Baby baby;

  @override
  State<BabyGrowthPage> createState() => _BabyGrowthPageState();
}

class _BabyGrowthPageState extends State<BabyGrowthPage> {
  final BabyGrowthRecordRepositoryImpl _repository = BabyGrowthRecordRepositoryImpl();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _headCircumferenceController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  List<BabyGrowthRecord> _records = const [];
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadRecords();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _headCircumferenceController.dispose();
    super.dispose();
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
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                children: [
                  _buildFormCard(theme, colorScheme),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_records.isEmpty)
                    const _EmptyStateCard(
                      icon: Icons.auto_graph_rounded,
                      title: 'Aún no hay mediciones',
                      message:
                          'Registra las revisiones pediátricas para ver aquí la evolución de peso, talla y perímetro craneal.',
                    )
                  else
                    ..._buildGroupedRecords(theme),
                ],
              ),
      ),
    );
  }

  Widget _buildFormCard(ThemeData theme, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Registrar nueva medición',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Selecciona la fecha de control y captura los valores entregados por el pediatra.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: _isSaving ? null : _pickDate,
              icon: const Icon(Icons.calendar_today_rounded),
              label: Text(_formatSelectedDate(_selectedDate)),
            ),
            const SizedBox(height: 24),
            _MeasurementInputField(
              controller: _heightController,
              label: 'Estatura (cm)',
              helper: 'Ej. 68.4',
              icon: Icons.height_rounded,
            ),
            const SizedBox(height: 16),
            _MeasurementInputField(
              controller: _headCircumferenceController,
              label: 'Perímetro craneal (cm)',
              helper: 'Ej. 41.2',
              icon: Icons.circle_outlined,
            ),
            const SizedBox(height: 16),
            _MeasurementInputField(
              controller: _weightController,
              label: 'Peso (kg)',
              helper: 'Ej. 7.25',
              icon: Icons.scale_rounded,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveRecord,
              icon: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar medición'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
      helpText: 'Selecciona la fecha del control',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _saveRecord() async {
    if (widget.baby.id == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Debes registrar al bebé antes de guardar mediciones.'),
          ),
        );
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    FocusScope.of(context).unfocus();

    final height = _parseMeasurement(_heightController.text);
    final head = _parseMeasurement(_headCircumferenceController.text);
    final weight = _parseMeasurement(_weightController.text);

    final record = BabyGrowthRecord(
      babyId: widget.baby.id!,
      recordedAt: _selectedDate,
      heightCm: height,
      headCircumferenceCm: head,
      weightKg: weight,
      createdAt: DateTime.now(),
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.createRecord(record);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Medición guardada para ${_formatSelectedDate(_selectedDate)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );

      _resetForm();
      await _loadRecords();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Error al guardar la medición: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _heightController.clear();
    _headCircumferenceController.clear();
    _weightController.clear();
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  double? _parseMeasurement(String raw) {
    final normalized = raw.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _formatSelectedDate(DateTime date) {
    final formatter = DateFormat("d 'de' MMMM yyyy", 'es');
    final formatted = formatter.format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}

class _MeasurementInputField extends StatelessWidget {
  const _MeasurementInputField({
    required this.controller,
    required this.label,
    required this.helper,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String helper;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Ingresa un valor válido';
        }
        final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
        if (parsed == null || parsed <= 0) {
          return 'El valor debe ser mayor a 0';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
      ),
    );
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
