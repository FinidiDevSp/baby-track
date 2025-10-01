import 'dart:io';

import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:baby_track_app/features/baby/infrastructure/baby_repository_impl.dart';
import 'package:baby_track_app/features/baby/presentation/pages/baby_menu_page.dart';
import 'package:baby_track_app/features/baby/presentation/pages/baby_registration_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BabyListPage extends StatefulWidget {
  const BabyListPage({super.key});

  @override
  State<BabyListPage> createState() => _BabyListPageState();
}

class _BabyListPageState extends State<BabyListPage> {
  final _repository = BabyRepositoryImpl();
  List<Baby> _babies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBabies();
  }

  Future<void> _loadBabies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final babies = await _repository.getAllBabies();
      setState(() {
        _babies = babies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar bebés: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editBaby(Baby baby) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => BabyRegistrationPage(babyToEdit: baby)),
    );

    if (result == true) {
      _loadBabies();
    }
  }

  Future<void> _deleteBaby(Baby baby) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar bebé'),
        content: Text('¿Estás seguro de que deseas eliminar el perfil de ${baby.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteBaby(baby.id!);
        _loadBabies();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${baby.name} ha sido eliminado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  LinearGradient _buildAppBarGradient(ColorScheme colorScheme) {
    final blendedColor =
        Color.lerp(colorScheme.primary, colorScheme.secondary, 0.5) ??
            colorScheme.primary;

    return LinearGradient(
      colors: [colorScheme.primary, blendedColor, colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Future<void> _openBabyMenu(Baby baby) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BabyMenuPage(baby: baby)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _babies.isEmpty
                  ? _EmptyState(colorScheme: colorScheme)
                  : _BabyGrid(
                      babies: _babies,
                      colorScheme: colorScheme,
                      onEdit: _editBaby,
                      onDelete: _deleteBaby,
                      onOpen: _openBabyMenu,
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const BabyRegistrationPage()),
          );
          if (result == true) _loadBabies();
        },
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// AppBar personalizado siguiendo estándares UI/UX de AGENTS.md
  PreferredSizeWidget _buildCustomAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(Icons.family_restroom_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mis bebés',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${_babies.length} ${_babies.length == 1 ? 'bebé' : 'bebés'} registrados',
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
    );
  }
}

class _BabyGrid extends StatelessWidget {
  const _BabyGrid({
    required this.babies,
    required this.colorScheme,
    required this.onEdit,
    required this.onDelete,
    required this.onOpen,
  });

  final List<Baby> babies;
  final ColorScheme colorScheme;
  final Function(Baby) onEdit;
  final Function(Baby) onDelete;
  final Function(Baby) onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 40, // Más espacio desde la AppBar
        bottom: 24,
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9, // Aumentado para más altura
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: babies.length,
        itemBuilder: (context, index) {
          return _BabyCard(
            baby: babies[index],
            colorScheme: colorScheme,
            onEdit: () => onEdit(babies[index]),
            onDelete: () => onDelete(babies[index]),
            onOpen: () => onOpen(babies[index]),
          );
        },
      ),
    );
  }
}

class _BabyCard extends StatelessWidget {
  const _BabyCard({
    required this.baby,
    required this.colorScheme,
    required this.onEdit,
    required this.onDelete,
    required this.onOpen,
  });

  final Baby baby;
  final ColorScheme colorScheme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  String _getAge() {
    final now = DateTime.now();
    final difference = now.difference(baby.birthDate);

    if (difference.inDays < 30) {
      return '${difference.inDays} días';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mes' : 'meses'}';
    } else {
      final years = (difference.inDays / 365).floor();
      final remainingMonths = ((difference.inDays % 365) / 30).floor();
      if (remainingMonths == 0) {
        return '$years ${years == 1 ? 'año' : 'años'}';
      }
      return '$years ${years == 1 ? 'año' : 'años'} $remainingMonths ${remainingMonths == 1 ? 'mes' : 'meses'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [colorScheme.primary.withOpacity(0.12), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14), // Reducido padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Importante para evitar overflow
              children: [
                // Photo
                Container(
                  width: 60, // Reducido tamaño
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baby.gender == 'M'
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.pink.withOpacity(0.2),
                    border: Border.all(
                      color: baby.gender == 'M'
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.pink.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: baby.photoPath != null && baby.photoPath!.isNotEmpty
                      ? ClipOval(
                          child: Image.file(
                            File(baby.photoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              baby.gender == 'M' ? Icons.boy : Icons.girl,
                              size: 28, // Reducido tamaño
                              color: baby.gender == 'M' ? Colors.blue : Colors.pink,
                            ),
                          ),
                        )
                      : Icon(
                          baby.gender == 'M' ? Icons.boy : Icons.girl,
                          size: 28, // Reducido tamaño
                          color: baby.gender == 'M' ? Colors.blue : Colors.pink,
                        ),
                ),
                const SizedBox(height: 8), // Reducido espaciado
                // Name
                Text(
                  baby.name,
                  style: textTheme.titleSmall?.copyWith(
                    // Cambiado a titleSmall
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // Reducido espaciado
                // Age
                Text(
                  _getAge(),
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 11, // Tamaño específico más pequeño
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Permitir 2 líneas para edad
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4), // Reducido espaciado
                // Birth date
                Text(
                  DateFormat('dd/MM/yyyy').format(baby.birthDate),
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 10, // Tamaño más pequeño
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8), // Espacio fijo en lugar de Spacer
                // Action buttons - Compactos
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32, // Altura fija más pequeña
                        child: IconButton(
                          onPressed: onEdit,
                          icon: Icon(
                            Icons.edit_rounded,
                            color: colorScheme.primary,
                            size: 16,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero, // Sin padding extra
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6), // Reducido espaciado
                    Expanded(
                      child: SizedBox(
                        height: 32, // Altura fija más pequeña
                        child: IconButton(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                            size: 16,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero, // Sin padding extra
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.baby_changing_station, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay bebés registrados',
              style: textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Regresa y crea el primer perfil',
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
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
