import 'package:flutter/material.dart';

/// Palette and ThemeData for Chaturang.
///
class ChaturangTheme {
  ChaturangTheme._();

  static const Color primaryText = Color(0xFFFFF5E4);
  static const Color secondaryText = Color(0xFFD1DBD6);
  static const Color parchment = Color(0xFFF0DFC0);
  static const Color charcoal = Color(0xFF2A1F14);
  static const Color saffron = Color(0xFFC97B2A);
  static const Color saffronLight = Color(0xFFD7B575);
  static const Color saffronDark = Color(0xFF8B5316);
  static const Color terracotta = Color(0xFF8B3A1F);
  static const Color deepMaroon = Color(0xFF101E20);
  // Board-surface colors (grid hairline, selection and legal-move tints)
  // moved to `appearance.dart` when the board became themeable — each
  // BoardSurface carries its own so they stay legible on dark fields.
  // The values Parchment inherited from here are unchanged.

  static ThemeData data() {
    final text = ThemeData.dark().textTheme.apply(
      fontFamily: 'RoyalSans',
      bodyColor: primaryText,
      displayColor: primaryText,
    );
    return ThemeData(
      textTheme: text.copyWith(
        bodyLarge: text.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
        bodyMedium: text.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
        bodySmall: text.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      fontFamily: 'RoyalSans',
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: deepMaroon,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: saffronLight,
          foregroundColor: deepMaroon,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: parchment,
          side: const BorderSide(color: Color(0xFF58706B)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: parchment),
      ),
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: saffron,
            brightness: Brightness.dark,
          ).copyWith(
            surface: deepMaroon,
            onSurface: primaryText,
            onSurfaceVariant: secondaryText,
          ),
    );
  }
}
