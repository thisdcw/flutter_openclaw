import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const background = Color(0xFFF3F7FC);
  const backgroundAccent = Color(0xFFE7F0FF);
  const surface = Color(0xFFFDFEFF);
  const surfaceStrong = Color(0xFFF2F7FF);
  const ink = Color(0xFF142033);
  const mutedInk = Color(0xFF5C6B80);
  const primary = Color(0xFF2F6BFF);
  const secondary = Color(0xFF5BC7FF);
  const outline = Color(0xFFD6E3F5);
  const errorContainer = Color(0xFFFFE7EA);
  const onErrorContainer = Color(0xFF7B2233);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: primary,
    secondary: secondary,
    surface: surface,
    surfaceContainerHighest: surfaceStrong,
    outline: outline,
    onSurface: ink,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFDCE7FF),
    onPrimaryContainer: ink,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineMedium: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: ink,
        height: 1.08,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: const TextStyle(
        fontSize: 15,
        color: ink,
        height: 1.35,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: ink,
        height: 1.4,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        color: mutedInk,
        height: 1.35,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: mutedInk,
        letterSpacing: 0.2,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: ink,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: outline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceStrong,
      labelStyle: const TextStyle(color: mutedInk),
      hintStyle: const TextStyle(color: mutedInk),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: outline),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: backgroundAccent,
      side: const BorderSide(color: outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      labelStyle: const TextStyle(
        color: ink,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
  );
}
