import 'package:flutter/material.dart';

/// FireSight app theme configuration.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD32F2F),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
    );
  }
}
