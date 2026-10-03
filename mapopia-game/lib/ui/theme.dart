import 'package:flutter/material.dart';

const ink = Color(0xFF183A43);
const ocean = Color(0xFF102F3C);
const paper = Color(0xFFF7F3E9);
const muted = Color(0xFF465D63);
const gold = Color(0xFFE8B767);
const teal = Color(0xFF227D76);
const line = Color(0xFFE4E6DD);
const ceramicColors = [
  Color(0xFF83C9B6),
  Color(0xFFEAA483),
  Color(0xFFE1BD6B),
  Color(0xFFA7ABD0),
  Color(0xFF77B3C9),
  Color(0xFFC0CB8D),
  Color(0xFFD59AA6),
];
Color pieceColor(String id) =>
    ceramicColors[id.codeUnits.fold(0, (a, b) => a * 31 + b).abs() %
        ceramicColors.length];
ThemeData atlasTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'PlusJakartaSans',
  scaffoldBackgroundColor: paper,
  colorScheme: ColorScheme.fromSeed(
    seedColor: teal,
    surface: paper,
    brightness: Brightness.light,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(
      color: ink,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.45,
    ),
    bodyLarge: TextStyle(
      color: ink,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.45,
    ),
    bodySmall: TextStyle(
      color: ink,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: teal,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 54),
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
  dividerColor: line,
);

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.3,
      color: color,
    ),
  );
}

class AtlasMark extends StatelessWidget {
  const AtlasMark({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: teal,
      borderRadius: BorderRadius.circular(size * .3),
    ),
    child: Icon(Icons.explore_rounded, color: paper, size: size * .67),
  );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.icon, this.dark = false});
  final String text;
  final IconData? icon;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: dark
          ? Colors.white.withValues(alpha: .12)
          : const Color(0xFFEAEDE3),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: dark ? gold : teal),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: TextStyle(
            color: dark ? paper : ink,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// Map lighting changes the atlas surface, not the identity of its pieces.
class MapPalette {
  const MapPalette({required this.night});
  final bool night;
  List<Color> get water => night
      ? [const Color(0xFF244D59), ocean, const Color(0xFF092430)]
      : [
          const Color(0xFFECF6EF),
          const Color(0xFFD2E9EA),
          const Color(0xFFB9DBE4),
        ];
  Color get border => night ? const Color(0xFF41606A) : const Color(0xFF93B8BD);
  Color get controls =>
      night ? const Color(0xE6102F3C) : const Color(0xF0F7FBF4);
  Color get icon => night ? const Color(0xFFCADEDE) : const Color(0xFF285F66);
  Color get caption =>
      night ? const Color(0xFFCDDFE3) : const Color(0xFF416C73);
  Color get grid => night
      ? Colors.white.withValues(alpha: .045)
      : const Color(0xFF437985).withValues(alpha: .09);
  Color get orbit => night
      ? Colors.white.withValues(alpha: .035)
      : const Color(0xFF437985).withValues(alpha: .09);
  Color get recess => night ? const Color(0xFF0A202B) : const Color(0xFF89ADB1);
  Color get empty => night ? const Color(0xFF284E5A) : const Color(0xFFAECBD0);
  Color get outline => night
      ? const Color(0xFF64858A).withValues(alpha: .6)
      : const Color(0xFF6D999E);
  Color get accent => night ? gold : const Color(0xFF956120);
  Gradient get gradient => RadialGradient(
    center: const Alignment(-.2, -.4),
    radius: 1.1,
    colors: water,
  );
}
