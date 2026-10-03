import 'package:flutter/material.dart';

/// The same artwork used by the launcher, website and store listings.
class JarAppIcon extends StatelessWidget {
  final double size;
  const JarAppIcon({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .22),
    child: Image.asset(
      'assets/branding/icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}
