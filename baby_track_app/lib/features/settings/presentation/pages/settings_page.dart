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

  Widget _buildSettingsContent() {
    final theme = Theme.of(context);
    final selectedIndex = _themeService.selectedColorIndex;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tema de color',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...List<Widget>.generate(ThemeService.availableThemes.length, (int index) {
          final option = ThemeService.availableThemes[index];
          final bool isSelected = index == selectedIndex;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? option.primary : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _saveColorSelection(index),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [option.primary, option.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isSelected
                          ? Icon(
                              Icons.check_circle,
                              key: ValueKey<int>(index),
                              color: option.primary,
                            )
                          : Icon(
                              Icons.circle_outlined,
                              key: ValueKey<String>('unselected-$index'),
                              color: theme.disabledColor,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

}
