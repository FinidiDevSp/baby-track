import 'package:baby_track_app/features/baby/presentation/pages/baby_selection_page.dart';
import 'package:baby_track_app/shared/theme/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class BabyTrackApp extends StatefulWidget {
  const BabyTrackApp({super.key});

  @override
  State<BabyTrackApp> createState() => _BabyTrackAppState();
}

class _BabyTrackAppState extends State<BabyTrackApp> {
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.initialize();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabyTrack',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      theme: _themeService.themeData,
      home: const BabySelectionPage(),
    );
  }
}
