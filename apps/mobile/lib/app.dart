import 'package:flutter/material.dart';

import 'features/bowl_builder/presentation/bowl_builder_screen.dart';

class DonburiXApp extends StatelessWidget {
  const DonburiXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFC44D29),
      surface: const Color(0xFFFFF9F1),
    );
    return MaterialApp(
      title: 'DonburiX • Racik Bowl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFFFF9F1),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const BowlBuilderScreen(),
    );
  }
}
