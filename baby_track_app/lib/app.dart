import 'package:baby_track_app/features/baby/presentation/pages/baby_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class BabyTrackApp extends StatelessWidget {
  const BabyTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF886B),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'BabyTrack',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      theme: ThemeData(
        colorScheme: baseColorScheme.copyWith(
          primary: const Color(0xFFFF886B),
          secondary: const Color(0xFF7DD1B3),
          surface: Colors.white,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF4A4A4A),
              displayColor: const Color(0xFF4A4A4A),
            ),
        useMaterial3: true,
      ),
      home: const BabySelectionPage(),
    );
  }
}
