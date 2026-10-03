import 'package:flutter/material.dart';

const ink = Color(0xFF163E3B);
const teal = Color(0xFF146C60);
const mint = Color(0xFFDCF0DE);
const paper = Color(0xFFF8F5EC);
const muted = Color(0xFF465F57);
const gold = Color(0xFFE9B958);

ThemeData mazeTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'PlusJakartaSans',
  fontFamilyFallback: [
    'NotoSansTamil',
    'NotoSansDevanagari',
    'NotoSansBengali',
    'NotoSansJP',
  ],
  scaffoldBackgroundColor: paper,
  colorScheme: ColorScheme.fromSeed(
    seedColor: teal,
    surface: paper,
    onSurface: ink,
    onSurfaceVariant: muted,
    brightness: Brightness.light,
  ),
  textTheme: _readableTextTheme(),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: teal,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontFamilyFallback: [
          'NotoSansTamil',
          'NotoSansDevanagari',
          'NotoSansBengali',
          'NotoSansJP',
        ],
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      minimumSize: const Size(48, 52),
      side: const BorderSide(color: Color(0xFFD2DDD0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: paper,
    foregroundColor: ink,
    centerTitle: false,
  ),
  dividerColor: const Color(0xFFDDE3D8),
);

// Keep the existing sizes and spacing; strengthen the actual font faces.
TextTheme _readableTextTheme() {
  final base = ThemeData.light().textTheme.apply(
    fontFamily: 'PlusJakartaSans',
    fontFamilyFallback: const [
      'NotoSansTamil',
      'NotoSansDevanagari',
      'NotoSansBengali',
      'NotoSansJP',
    ],
    bodyColor: ink,
    displayColor: ink,
  );
  TextStyle? semibold(TextStyle? style) =>
      style?.copyWith(fontWeight: FontWeight.w600);
  TextStyle? bold(TextStyle? style) =>
      style?.copyWith(fontWeight: FontWeight.w700);
  return base.copyWith(
    displayLarge: bold(base.displayLarge),
    displayMedium: bold(base.displayMedium),
    displaySmall: bold(base.displaySmall),
    headlineLarge: bold(base.headlineLarge),
    headlineMedium: bold(base.headlineMedium),
    headlineSmall: bold(base.headlineSmall),
    titleLarge: bold(base.titleLarge),
    titleMedium: bold(base.titleMedium),
    titleSmall: bold(base.titleSmall),
    bodyLarge: semibold(base.bodyLarge),
    bodyMedium: semibold(base.bodyMedium),
    bodySmall: semibold(base.bodySmall),
    labelLarge: bold(base.labelLarge),
    labelMedium: bold(base.labelMedium),
    labelSmall: bold(base.labelSmall),
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: ink.withValues(alpha: .06)),
    ),
    child: child,
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 10,
      letterSpacing: 2.2,
      fontWeight: FontWeight.w800,
      color: color,
    ),
  );
}
