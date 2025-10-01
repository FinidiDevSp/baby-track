import 'dart:io';

import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BabyMenuPage extends StatelessWidget {
  const BabyMenuPage({super.key, required this.baby});

  final Baby baby;

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

  String _formatAge() {
    final now = DateTime.now();
    final difference = now.difference(baby.birthDate);

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

  String _genderLabel() {
    switch (baby.gender) {
      case 'M':
        return 'Niño';
      case 'F':
        return 'Niña';
      default:
        return 'Sin especificar';
    }
  }

  Color _genderColor(ColorScheme colorScheme) {
    switch (baby.gender) {
      case 'M':
        return colorScheme.primary;
      case 'F':
        return colorScheme.secondary;
      default:
        return colorScheme.tertiary;
    }
  }

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$featureName estará disponible muy pronto.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final actions = [
      _BabyActionCardData(
        title: 'REGISTRO',
        description:
            'Anota tomas, pañales, siestas y observaciones importantes del día a día.',
        icon: Icons.edit_note_rounded,
        accentColor: colorScheme.primary,
        backgroundColors: [
          colorScheme.primary.withOpacity(0.18),
          colorScheme.primary.withOpacity(0.08),
        ],
      ),
      _BabyActionCardData(
        title: 'HISTORIAL',
        description: 'Revisa los registros anteriores y detecta patrones fácilmente.',
        icon: Icons.history_rounded,
        accentColor: colorScheme.secondary,
        backgroundColors: [
          colorScheme.secondary.withOpacity(0.18),
          colorScheme.secondary.withOpacity(0.08),
        ],
      ),
    ];

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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.child_friendly_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    baby.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Edad: ${_formatAge()}',
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
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BabySummaryCard(
                      baby: baby,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      genderLabel: _genderLabel(),
                      genderColor: _genderColor(colorScheme),
                      ageLabel: _formatAge(),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Acciones rápidas',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Selecciona una opción para gestionar la información de ${baby.name}.',
                      style: textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 600;
                        final cardWidth = isWide
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: actions
                              .map(
                                (action) => SizedBox(
                                  width: cardWidth,
                                  child: _BabyActionCard(
                                    data: action,
                                    onTap: () => _showComingSoon(context, action.title),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BabySummaryCard extends StatelessWidget {
  const _BabySummaryCard({
    required this.baby,
    required this.colorScheme,
    required this.textTheme,
    required this.genderLabel,
    required this.genderColor,
    required this.ageLabel,
  });

  final Baby baby;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String genderLabel;
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
                  colorScheme: colorScheme,
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
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            icon: Icons.cake_outlined,
                            label: DateFormat('dd/MM/yyyy').format(baby.birthDate),
                          ),
                          _InfoPill(
                            icon: Icons.calendar_month_rounded,
                            label: ageLabel,
                          ),
                          _InfoPill(
                            icon: Icons.waving_hand_rounded,
                            label: genderLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Divider(color: colorScheme.primary.withOpacity(0.2)),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Perfil creado el ${DateFormat('dd/MM/yyyy').format(baby.createdAt)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
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

class _BabyAvatar extends StatelessWidget {
  const _BabyAvatar({
    required this.baby,
    required this.colorScheme,
    required this.genderColor,
  });

  final Baby baby;
  final ColorScheme colorScheme;
  final Color genderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
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
                  size: 40,
                ),
              )
            : Icon(
                baby.gender == 'M'
                    ? Icons.boy_rounded
                    : baby.gender == 'F'
                        ? Icons.girl_rounded
                        : Icons.child_care,
                color: genderColor,
                size: 40,
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

class _BabyActionCard extends StatelessWidget {
  const _BabyActionCard({required this.data, required this.onTap});

  final _BabyActionCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                data.backgroundColors.first,
                data.backgroundColors.last,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: data.accentColor.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.accentColor, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                data.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                data.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Abrir',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: data.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: data.accentColor, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BabyActionCardData {
  const _BabyActionCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.backgroundColors,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<Color> backgroundColors;
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
