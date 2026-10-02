import 'package:flutter/material.dart';

/// Alphadoku's palette, drawn from the family house style: warm paper, deep
/// teal, ink text, gold reserved for the axis payoff.
const ink = Color(0xFF10383F);
const teal = Color(0xFF08756E);
const paper = Color(0xFFF8F5EC);
const muted = Color(0xFF405E62);
const gold = Color(0xFFE2A93F);
const mint = Color(0xFFDCEFE6);
const line = Color(0xFFE1E6DC);
const coral = Color(0xFFB64032);

/// Cell fills. Givens sit on a tinted ground so they read as fixed; the
/// player's own letters sit on plain white.
const givenFill = Color(0xFFEDF1E8);
const axisGlow = Color(0xFFFBF0D4);

ThemeData alphadokuTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'PlusJakartaSans',
  scaffoldBackgroundColor: paper,
  colorScheme: ColorScheme.fromSeed(
    seedColor: teal,
    surface: paper,
    onSurface: ink,
    onSurfaceVariant: muted,
    brightness: Brightness.light,
  ),
  textTheme: _textTheme(),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: teal,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      minimumSize: const Size(48, 52),
      side: const BorderSide(color: Color(0xFFD4DED3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: paper,
    foregroundColor: ink,
    centerTitle: false,
    elevation: 0,
  ),
  dividerColor: line,
);

TextTheme _textTheme() {
  final base = ThemeData.light().textTheme.apply(
    fontFamily: 'PlusJakartaSans',
    bodyColor: ink,
    displayColor: ink,
  );
  TextStyle? bold(TextStyle? s) => s?.copyWith(fontWeight: FontWeight.w800);
  return base.copyWith(
    headlineLarge: bold(base.headlineLarge),
    headlineMedium: bold(base.headlineMedium),
    headlineSmall: bold(base.headlineSmall),
    titleLarge: bold(base.titleLarge),
    titleMedium: bold(base.titleMedium),
    titleSmall: bold(base.titleSmall),
    bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: bold(base.labelLarge),
    labelMedium: bold(base.labelMedium),
    labelSmall: bold(base.labelSmall),
  );
}

/// A rounded card, the family's standard content container.
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

/// Small all-caps label above a section.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: 11,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w800,
      color: color,
    ),
  );
}

/// Rounded status chip.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.icon, this.tone = teal});

  final String text;
  final IconData? icon;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: tone),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: tone == gold ? const Color(0xFF8A6412) : ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The app mark: a grid cell holding a letter, the game in one glyph.
class AlphadokuMark extends StatelessWidget {
  const AlphadokuMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .22),
    child: Image.asset(
      'branding/icon.png',
      width: size,
      height: size,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
      excludeFromSemantics: true,
    ),
  );
}
