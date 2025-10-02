import 'package:baby_track_app/shared/theme/theme_service.dart';
import 'package:baby_track_app/shared/widgets/app_bars/baby_gradient_app_bar.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeService _themeService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    await _themeService.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveColorSelection(int index) async {
    await _themeService.setColorTheme(index);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Color ${_themeService.currentTheme.name} guardado'),
          backgroundColor: _themeService.currentTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const BabyGradientAppBar(
        title: 'Configuración',
        subtitle: 'Personaliza tu aplicación',
        icon: Icons.settings_rounded,
      ),
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
              : _buildSettingsContent(),
        ),
      ),
    );
  }

}
