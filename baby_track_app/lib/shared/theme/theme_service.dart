import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _colorIndexKey = 'selected_color_index';
  int _selectedColorIndex = 0;

  // Singleton instance
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  // Paleta de colores disponibles
  static const List<AppColorTheme> availableThemes = [
    AppColorTheme(
      name: 'Naranja Cálido',
      primary: Color(0xFFFF7043),
      secondary: Color(0xFFFFAB91),
      description: 'Color predeterminado cálido y acogedor',
    ),
    AppColorTheme(
      name: 'Azul Serenidad',
      primary: Color(0xFF42A5F5),
      secondary: Color(0xFF90CAF9),
      description: 'Tranquilidad y confianza',
    ),
    AppColorTheme(
      name: 'Verde Naturaleza',
      primary: Color(0xFF66BB6A),
      secondary: Color(0xFFA5D6A7),
      description: 'Armonía y crecimiento',
    ),
    AppColorTheme(
      name: 'Rosa Ternura',
      primary: Color(0xFFEC407A),
      secondary: Color(0xFFF8BBD9),
      description: 'Dulzura y cuidado maternal',
    ),
    AppColorTheme(
      name: 'Púrpura Elegante',
      primary: Color(0xFF7E57C2),
      secondary: Color(0xFFB39DDB),
      description: 'Sofisticación y creatividad',
    ),
  ];

  int get selectedColorIndex => _selectedColorIndex;
  AppColorTheme get currentTheme => availableThemes[_selectedColorIndex];

  ThemeData get themeData {
    final theme = currentTheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: theme.primary,
        brightness: Brightness.light,
      ).copyWith(primary: theme.primary, secondary: theme.secondary),
      appBarTheme: AppBarTheme(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedColorIndex = prefs.getInt(_colorIndexKey) ?? 0;
    notifyListeners();
  }

  Future<void> setColorTheme(int index) async {
    if (index >= 0 && index < availableThemes.length) {
      _selectedColorIndex = index;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_colorIndexKey, index);
      notifyListeners();
    }
  }
}

class AppColorTheme {
  final String name;
  final Color primary;
  final Color secondary;
  final String description;

  const AppColorTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.description,
  });
}
