import 'package:baby_track_app/features/baby/domain/growth/who_growth_standards.dart';
import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:baby_track_app/features/baby/domain/models/baby_growth_record.dart';
import 'package:baby_track_app/features/baby/infrastructure/baby_growth_record_repository_impl.dart';
import 'package:baby_track_app/features/baby/presentation/widgets/who_percentile_chart.dart';
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

  final _createFormKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();
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
      key: _createFormKey,
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
              onPressed: _isSaving
                  ? null
                  : () async {
                      await _saveRecord(formKey: _createFormKey);
                    },
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
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
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
                ...entry.value.map(
                  (record) => _GrowthRecordCard(
                    record: record,
                    baby: widget.baby,
                    onEdit: () => _editRecord(record),
                    onDelete: () => _deleteRecord(record),
                  ),
                ),
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

  Future<bool> _saveRecord({
    BabyGrowthRecord? editingRecord,
    required GlobalKey<FormState> formKey,
  }) async {
    if (widget.baby.id == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Debes registrar al bebé antes de guardar mediciones.')),
        );
      return false;
    }

    if (formKey.currentState?.validate() != true) {
      return false;
    }

    FocusScope.of(context).unfocus();

    final height = _parseMeasurement(_heightController.text);
    final head = _parseMeasurement(_headCircumferenceController.text);
    final weight = _parseMeasurement(_weightController.text);

    final record = BabyGrowthRecord(
      id: editingRecord?.id,
      babyId: widget.baby.id!,
      recordedAt: _selectedDate,
      heightCm: height,
      headCircumferenceCm: head,
      weightKg: weight,
      createdAt: editingRecord?.createdAt ?? DateTime.now(),
    );

    setState(() {
      _isSaving = true;
    });

    try {
      if (editingRecord != null) {
        await _repository.updateRecord(record);
      } else {
        await _repository.createRecord(record);
      }
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              editingRecord != null
                  ? 'Medición actualizada exitosamente'
                  : 'Medición guardada para ${_formatSelectedDate(_selectedDate)}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      _resetForm();
      await _loadRecords();
      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Error al guardar la medición: $e'), backgroundColor: Colors.red),
        );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
    return false;
  }

  void _resetForm() {
    _createFormKey.currentState?.reset();
    _editFormKey.currentState?.reset();
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

  String _formatMeasurementForInput(double? value) {
    if (value == null) {
      return '';
    }
    final decimals = value % 1 == 0 ? 0 : 2;
    return value.toStringAsFixed(decimals);
  }

  String _formatSelectedDate(DateTime date) {
    final formatter = DateFormat("d 'de' MMMM yyyy", 'es');
    final formatted = formatter.format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  Widget _buildGrowthForm(BuildContext modalContext, {BabyGrowthRecord? editingRecord}) {
    final theme = Theme.of(modalContext);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.monitor_weight_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  editingRecord != null ? 'Editar medición' : 'Registrar nueva medición',
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
            Form(
              key: _editFormKey,
              child: Column(
                children: [
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final saved = await _saveRecord(
                        editingRecord: editingRecord,
                        formKey: _editFormKey,
                      );
                      if (saved && modalContext.mounted) {
                        Navigator.of(modalContext).pop();
                      }
                    },
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
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editRecord(BabyGrowthRecord record) async {
    _heightController.text = _formatMeasurementForInput(record.heightCm);
    _weightController.text = _formatMeasurementForInput(record.weightKg);
    _headCircumferenceController.text = _formatMeasurementForInput(record.headCircumferenceCm);
    setState(() {
      _selectedDate = record.recordedAt;
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _buildGrowthForm(modalContext, editingRecord: record),
    );

    if (mounted) {
      _resetForm();
    }
  }

  Future<void> _deleteRecord(BabyGrowthRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el registro del ${_formatDate(record.recordedAt)}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && record.id != null) {
      try {
        await _repository.deleteRecord(record.id!);
        await _loadRecords();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Registro eliminado exitosamente')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar registro: $e')));
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('d MMM yyyy', 'es');
    return formatter.format(date);
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
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
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

class _GrowthRecordCard extends StatefulWidget {
  const _GrowthRecordCard({
    required this.record,
    required this.baby,
    required this.onEdit,
    required this.onDelete,
  });

  final BabyGrowthRecord record;
  final Baby baby;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_GrowthRecordCard> createState() => _GrowthRecordCardState();
}

class _GrowthRecordCardState extends State<_GrowthRecordCard> {
  bool _isExpanded = false;

  BabyGender get _babyGender =>
      widget.baby.gender.toUpperCase() == 'F' ? BabyGender.female : BabyGender.male;

  String _formatMeasurement(double? value, String unit) {
    if (value == null) {
      return 'Sin dato';
    }
    return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} $unit';
  }

  String _formatAgeDetail() {
    final birth = widget.baby.birthDate;
    final measurementDate = widget.record.recordedAt;
    if (measurementDate.isBefore(birth)) {
      return 'Edad no disponible';
    }

    var years = measurementDate.year - birth.year;
    var months = measurementDate.month - birth.month;
    var days = measurementDate.day - birth.day;

    if (days < 0) {
      final previousMonth = DateTime(measurementDate.year, measurementDate.month, 0);
      days += previousMonth.day;
      months -= 1;
    }

    if (months < 0) {
      years -= 1;
      months += 12;
    }

    final parts = <String>[];
    if (years > 0) {
      parts.add('$years ${years == 1 ? 'año' : 'años'}');
    }
    if (months > 0) {
      parts.add('$months ${months == 1 ? 'mes' : 'meses'}');
    }
    if (days > 0 || parts.isEmpty) {
      parts.add('$days ${days == 1 ? 'día' : 'días'}');
    }
    return parts.join(', ');
  }

  double _ageInMonths() {
    final difference = widget.record.recordedAt.difference(widget.baby.birthDate);
    if (difference.isNegative) {
      return 0;
    }
    return difference.inDays / 30.4375;
  }

  double? _percentileFor(double? measurement, GrowthMetric metric) {
    return WhoGrowthStandards.percentileForMeasurement(
      measurement: measurement,
      ageMonths: _ageInMonths(),
      gender: _babyGender,
      metric: metric,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ageDetail = _formatAgeDetail();
    final ageMonths = _ageInMonths();

    final headPercentile = _percentileFor(
      widget.record.headCircumferenceCm,
      GrowthMetric.headCircumference,
    );
    final heightPercentile = _percentileFor(widget.record.heightCm, GrowthMetric.height);
    final weightPercentile = _percentileFor(widget.record.weightKg, GrowthMetric.weight);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_formatDate(widget.record.recordedAt)} · $ageDetail',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: widget.onEdit,
                        icon: Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Editar',
                        color: colorScheme.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Eliminar',
                        color: colorScheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    TabBar(
                      labelColor: colorScheme.primary,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                      indicatorColor: colorScheme.primary,
                      indicatorWeight: 2.5,
                      isScrollable: true,
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      tabs: const [
                        Tab(text: 'Perímetro craneal'),
                        Tab(text: 'Altura'),
                        Tab(text: 'Peso'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 360,
                      child: TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _GrowthMetricTab(
                            metric: GrowthMetric.headCircumference,
                            title: 'Perímetro craneal',
                            unit: 'cm',
                            icon: Icons.circle_outlined,
                            measurement: widget.record.headCircumferenceCm,
                            measurementLabel: _formatMeasurement(
                              widget.record.headCircumferenceCm,
                              'cm',
                            ),
                            percentile: headPercentile,
                            gender: _babyGender,
                            ageMonths: ageMonths,
                            color: colorScheme.primary,
                          ),
                          _GrowthMetricTab(
                            metric: GrowthMetric.height,
                            title: 'Altura',
                            unit: 'cm',
                            icon: Icons.height_rounded,
                            measurement: widget.record.heightCm,
                            measurementLabel: _formatMeasurement(widget.record.heightCm, 'cm'),
                            percentile: heightPercentile,
                            gender: _babyGender,
                            ageMonths: ageMonths,
                            color: colorScheme.secondary,
                          ),
                          _GrowthMetricTab(
                            metric: GrowthMetric.weight,
                            title: 'Peso',
                            unit: 'kg',
                            icon: Icons.scale_rounded,
                            measurement: widget.record.weightKg,
                            measurementLabel: _formatMeasurement(widget.record.weightKg, 'kg'),
                            percentile: weightPercentile,
                            gender: _babyGender,
                            ageMonths: ageMonths,
                            color: colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('d MMM yyyy', 'es');
    return formatter.format(date);
  }
}

class _GrowthMetricTab extends StatelessWidget {
  const _GrowthMetricTab({
    required this.metric,
    required this.title,
    required this.unit,
    required this.icon,
    required this.measurement,
    required this.measurementLabel,
    required this.percentile,
    required this.gender,
    required this.ageMonths,
    required this.color,
  });

  final GrowthMetric metric;
  final String title;
  final String unit;
  final IconData icon;
  final double? measurement;
  final String measurementLabel;
  final double? percentile;
  final BabyGender gender;
  final double ageMonths;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final percentileLabel = percentile == null
        ? 'Sin percentil disponible'
        : 'Percentil ${percentile!.clamp(0, 100).round()} (OMS)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Medición: $measurementLabel', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          percentileLabel,
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: WhoPercentileChart(
                  metric: metric,
                  gender: gender,
                  measurement: measurement,
                  ageMonths: ageMonths,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Fuente: Estándares de crecimiento OMS 2006.',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.icon, required this.title, required this.message});

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
