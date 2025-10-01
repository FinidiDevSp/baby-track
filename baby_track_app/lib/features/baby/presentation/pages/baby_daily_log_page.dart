import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:baby_track_app/features/baby/domain/models/baby_daily_log.dart';
import 'package:baby_track_app/features/baby/infrastructure/baby_daily_log_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BabyDailyLogPage extends StatefulWidget {
  const BabyDailyLogPage({super.key, required this.baby});

  final Baby baby;

  @override
  State<BabyDailyLogPage> createState() => _BabyDailyLogPageState();
}

class _BabyDailyLogPageState extends State<BabyDailyLogPage> {
  final _formKey = GlobalKey<FormState>();
  final _mlController = TextEditingController();
  final _notesController = TextEditingController();
  final _repository = BabyDailyLogRepositoryImpl();

  late DateTime _selectedDay;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _didPoop = false;
  bool _showered = false;
  bool _vomited = false;
  bool _isSaving = false;
  bool _isLoadingLogs = false;
  List<BabyDailyLog> _logs = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    if (widget.baby.id != null) {
      _loadLogs();
    }
  }

  @override
  void dispose() {
    _mlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    if (widget.baby.id == null) {
      return;
    }

    setState(() {
      _isLoadingLogs = true;
    });

    try {
      final logs = await _repository.getLogsForBabyOnDate(widget.baby.id!, _selectedDay);
      if (!mounted) {
        return;
      }

      setState(() {
        _logs = logs;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLogs = false;
        });
      }
    }
  }

  void _changeDay(int offset) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: offset));
    });
    _loadLogs();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveLog() async {
    if (widget.baby.id == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Debes guardar al bebé antes de crear registros diarios.')),
        );
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    FocusScope.of(context).unfocus();

    final intakeText = _mlController.text.trim();
    final notesText = _notesController.text.trim();
    final normalizedDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final logDateTime = DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final log = BabyDailyLog(
      babyId: widget.baby.id!,
      logDay: normalizedDay,
      loggedAt: logDateTime,
      intakeMl: intakeText.isEmpty ? null : int.parse(intakeText),
      didPoop: _didPoop,
      showered: _showered,
      vomited: _vomited,
      notes: notesText.isEmpty ? null : notesText,
      createdAt: DateTime.now(),
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.createLog(log);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Registro guardado para ${_formatDayLabel(_selectedDay)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );

      _resetForm();
      await _loadLogs();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Error al guardar el registro: $e'), backgroundColor: Colors.red),
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
    setState(() {
      _mlController.clear();
      _notesController.clear();
      _didPoop = false;
      _showered = false;
      _vomited = false;
      _selectedTime = TimeOfDay.now();
    });
  }

  String _formatDayLabel(DateTime date) {
    return toBeginningOfSentenceCase(DateFormat("EEEE d 'de' MMMM", 'es').format(date)) ??
        DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTimeLabel(TimeOfDay timeOfDay) {
    final date = DateTime(0, 1, 1, timeOfDay.hour, timeOfDay.minute);
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Registro diario de ${widget.baby.name}')),
      body: SafeArea(
        child: widget.baby.id == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Guarda primero la información de ${widget.baby.name} para comenzar a registrar sus actividades diarias.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DayNavigator(
                      dayLabel: _formatDayLabel(_selectedDay),
                      onPrevious: () => _changeDay(-1),
                      onNext: () => _changeDay(1),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 24),
                    _buildFormCard(colorScheme, textTheme),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFormCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nuevo registro',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: 'Hora del registro',
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time_filled_rounded),
                  label: Text(_formatTimeLabel(_selectedTime)),
                ),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: 'Toma (ml)',
                subtitle: 'Introduce los mililitros ingeridos si aplica.',
                child: TextFormField(
                  controller: _mlController,
                  decoration: const InputDecoration(hintText: 'Ej. 120'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null) {
                      return 'Introduce solo números';
                    }
                    if (parsed < 0) {
                      return 'El valor no puede ser negativo';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('¿Ha hecho caca?'),
                value: _didPoop,
                onChanged: (value) => setState(() => _didPoop = value),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('¿Ha vomitado?'),
                value: _vomited,
                onChanged: (value) => setState(() => _vomited = value),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('¿Le hemos duchado?'),
                value: _showered,
                onChanged: (value) => setState(() => _showered = value),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: 'Notas',
                subtitle: 'Escribe cualquier observación adicional.',
                child: TextFormField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(hintText: 'Ej. Durmió muy bien.'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveLog,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayNavigator extends StatelessWidget {
  const _DayNavigator({
    required this.dayLabel,
    required this.onPrevious,
    required this.onNext,
    required this.colorScheme,
  });

  final String dayLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [colorScheme.primary.withOpacity(0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _CircleButton(icon: Icons.chevron_left, onPressed: onPrevious),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              dayLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          _CircleButton(icon: Icons.chevron_right, onPressed: onNext),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 26)),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DailyLogCard extends StatelessWidget {
  const _DailyLogCard({required this.log, required this.colorScheme, required this.textTheme});

  final BabyDailyLog log;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (log.intakeMl != null) {
      chips.add(
        _InfoChip(
          icon: Icons.local_drink_rounded,
          label: 'Toma: ${log.intakeMl} ml',
          color: colorScheme.primary,
        ),
      );
    }
    if (log.didPoop) {
      chips.add(
        _InfoChip(
          icon: Icons.baby_changing_station_rounded,
          label: 'Pañal sucio',
          color: colorScheme.secondary,
        ),
      );
    }
    if (log.showered) {
      chips.add(_InfoChip(icon: Icons.shower_rounded, label: 'Ducha', color: colorScheme.tertiary));
    }
    if (log.vomited) {
      chips.add(_InfoChip(icon: Icons.sick_rounded, label: 'Vómito', color: colorScheme.error));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.schedule_rounded, color: colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat('HH:mm').format(log.loggedAt),
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (chips.isNotEmpty) Wrap(spacing: 12, runSpacing: 12, children: chips),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              if (chips.isNotEmpty) const SizedBox(height: 16),
              Text(log.notes!, style: textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: color.withOpacity(0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
