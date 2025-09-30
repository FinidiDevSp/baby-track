import 'dart:io';

import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:baby_track_app/features/baby/infrastructure/baby_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class BabyRegistrationPage extends StatefulWidget {
  const BabyRegistrationPage({super.key, this.babyToEdit});

  final Baby? babyToEdit;

  @override
  State<BabyRegistrationPage> createState() => _BabyRegistrationPageState();
}

class _BabyRegistrationPageState extends State<BabyRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _repository = BabyRepositoryImpl();
  final _imagePicker = ImagePicker();

  DateTime? _selectedDate;
  String? _selectedGender;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.babyToEdit != null) {
      _nameController.text = widget.babyToEdit!.name;
      _selectedDate = widget.babyToEdit!.birthDate;
      _selectedGender = widget.babyToEdit!.gender;
      if (widget.babyToEdit!.photoPath != null) {
        _selectedImage = File(widget.babyToEdit!.photoPath!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Theme.of(context).colorScheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar foto: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _selectImage();
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Quitar foto'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBaby() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedGender == null) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona la fecha de nacimiento'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona el sexo del bebé'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final baby = Baby(
        id: widget.babyToEdit?.id,
        name: _nameController.text.trim(),
        birthDate: _selectedDate!,
        gender: _selectedGender!,
        photoPath: _selectedImage?.path,
        createdAt: widget.babyToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.babyToEdit != null) {
        await _repository.updateBaby(baby);
      } else {
        await _repository.createBaby(baby);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.babyToEdit != null
                  ? '¡Bebé actualizado exitosamente!'
                  : '¡Bebé registrado exitosamente!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
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
      backgroundColor: const Color(0xFFFFF4F0),
      appBar: _buildCustomAppBar(context, colorScheme),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF4F0), Color(0xFFFFFDF7)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative bubbles
              Positioned(
                top: -60,
                right: -20,
                child: _DecorativeBubble(size: 180, color: colorScheme.secondary.withOpacity(0.25)),
              ),
              Positioned(
                bottom: -40,
                left: -30,
                child: _DecorativeBubble(size: 140, color: colorScheme.primary.withOpacity(0.18)),
              ),
              // Content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _RegistrationCard(
                            colorScheme: colorScheme,
                            nameController: _nameController,
                            selectedDate: _selectedDate,
                            selectedGender: _selectedGender,
                            selectedImage: _selectedImage,
                            onSelectDate: () => _selectDate(context),
                            onSelectGender: (gender) => setState(() => _selectedGender = gender),
                            onSelectImage: _showImageOptions,
                            isLoading: _isLoading,
                            isEditing: widget.babyToEdit != null,
                            onSave: _saveBaby,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// AppBar personalizado siguiendo estándares UI/UX de AGENTS.md
  PreferredSizeWidget _buildCustomAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: colorScheme.primary,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
            child: Icon(Icons.baby_changing_station, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.babyToEdit != null ? '¡Editar bebé!' : '¡Registrar bebé!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Información básica',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          tooltip: 'Cerrar',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({
    required this.colorScheme,
    required this.nameController,
    required this.selectedDate,
    required this.selectedGender,
    required this.selectedImage,
    required this.onSelectDate,
    required this.onSelectGender,
    required this.onSelectImage,
    required this.isLoading,
    required this.isEditing,
    required this.onSave,
  });

  final ColorScheme colorScheme;
  final TextEditingController nameController;
  final DateTime? selectedDate;
  final String? selectedGender;
  final File? selectedImage;
  final VoidCallback onSelectDate;
  final Function(String) onSelectGender;
  final VoidCallback onSelectImage;
  final bool isLoading;
  final bool isEditing;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [colorScheme.primary.withOpacity(0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Photo section
            GestureDetector(
              onTap: onSelectImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.secondary.withOpacity(0.3), width: 2),
                ),
                child: selectedImage != null
                    ? ClipOval(child: Image.file(selectedImage!, fit: BoxFit.cover))
                    : Icon(Icons.add_a_photo_rounded, size: 40, color: colorScheme.secondary),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onSelectImage,
              child: Text(
                selectedImage != null ? 'Cambiar foto' : 'Agregar foto (opcional)',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 32),

            // Name field
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del bebé',
                hintText: 'Ej: Sofía, Mateo...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                prefixIcon: Icon(Icons.child_care_rounded, color: colorScheme.primary),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el nombre del bebé';
                }
                if (value.trim().length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            // Birth date field with improved design
            GestureDetector(
              onTap: onSelectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: selectedDate != null
                        ? colorScheme.primary.withOpacity(0.3)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha de nacimiento',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedDate != null
                                ? DateFormat('dd MMMM yyyy', 'es_ES').format(selectedDate!)
                                : 'Selecciona una fecha',
                            style: textTheme.bodyLarge?.copyWith(
                              color: selectedDate != null ? Colors.black87 : Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down_rounded, color: Colors.grey[600], size: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Gender selection with pastel colors
            Text(
              'Sexo del bebé',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _GenderOption(
                    isSelected: selectedGender == 'M',
                    onTap: () => onSelectGender('M'),
                    icon: Icons.boy_rounded,
                    label: 'Niño',
                    selectedColor: const Color(0xFF87CEEB), // Sky blue pastel
                    baseColor: const Color(0xFFE6F3FF),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _GenderOption(
                    isSelected: selectedGender == 'F',
                    onTap: () => onSelectGender('F'),
                    icon: Icons.girl_rounded,
                    label: 'Niña',
                    selectedColor: const Color(0xFFFFB6C1), // Light pink pastel
                    baseColor: const Color(0xFFFFF0F5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'Actualizar bebé' : 'Guardar bebé',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget personalizado para opciones de género con colores pastel
class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.selectedColor,
    required this.baseColor,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color selectedColor;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.2) : baseColor,
          border: Border.all(color: isSelected ? selectedColor : Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor.withOpacity(0.3) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? selectedColor.withOpacity(0.8) : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? selectedColor.withOpacity(0.9) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
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
