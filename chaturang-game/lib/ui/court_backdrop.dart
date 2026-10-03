import 'package:flutter/material.dart';

/// The same court artwork follows the player into the match, subdued enough
/// that piece silhouettes and legal-square indicators remain the focus.
class CourtBackdrop extends StatelessWidget {
  const CourtBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/decorations/royal_court.png'),
        fit: BoxFit.cover,
        opacity: .16,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B3233), Color(0xFF0C171A)],
      ),
    ),
    child: child,
  );
}
