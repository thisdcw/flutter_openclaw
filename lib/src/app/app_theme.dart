import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const background = Color(0xFFF4F1EA);
  const panel = Color(0xFFFFFBF4);
  const ink = Color(0xFF1F1A17);
  const accent = Color(0xFFB6542A);

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      surface: panel,
    ),
    scaffoldBackgroundColor: background,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: ink),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, color: ink),
      bodyMedium: TextStyle(color: ink),
    ),
    useMaterial3: true,
  );
}
