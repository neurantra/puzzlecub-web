import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'toy_box.dart';

/// A one-shot fireworks and hopping-Pip parade, then quiet corner stars.
/// Pointer-transparent; reduced motion shows only the static star accents.
class CelebrationFlourish extends StatefulWidget {
  const CelebrationFlourish({super.key});
  @override
  State<CelebrationFlourish> createState() => _CelebrationFlourishState();
}

class _CelebrationFlourishState extends State<CelebrationFlourish>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  bool _started = false;
  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
      _animation.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _animation.forward();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final t = _animation.value;
            final still = MediaQuery.disableAnimationsOf(context);
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _FireworksPainter(t)),
                ),
                if (!still && t < 1)
                  Positioned(
                    key: const ValueKey('hooray-parade'),
                    left: -136 + (constraints.maxWidth + 272) * t,
                    top:
                        constraints.maxHeight * .28 -
                        math.sin(t * math.pi * 6).abs() * 34,
                    width: 136,
                    child: Transform.rotate(
                      angle: math.sin(t * math.pi * 12) * .12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD878),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33664C30),
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const FittedBox(
                              child: Text(
                                'HOORAY!',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(disableAnimations: true),
                            child: const Pip(size: 86),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _FireworksPainter extends CustomPainter {
  const _FireworksPainter(this.progress);
  final double progress;

  void star(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * .45;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFE1A62C);
    // These quiet accents remain while the player enjoys their solved board.
    for (final corner in [
      Offset(8, 8),
      Offset(size.width - 8, 8),
      Offset(8, size.height - 8),
      Offset(size.width - 8, size.height - 8),
    ]) {
      star(canvas, corner, 7, gold);
    }
    if (progress >= 1) return;
    final centers = [
      Offset(size.width * .18, size.height * .13),
      Offset(size.width * .83, size.height * .16),
      Offset(size.width * .5, size.height * .8),
      Offset(size.width * .18, size.height * .6),
      Offset(size.width * .82, size.height * .5),
    ];
    for (var burst = 0; burst < centers.length; burst++) {
      final t = (progress - burst * .14) / .44;
      if (t <= 0 || t >= 1) continue;
      final radius = (10 + 62 * Curves.easeOut.transform(t)) * size.width / 350;
      final opacity = math.sin(math.pi * t) * .95;
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6 + burst * .4;
        final direction = Offset(math.cos(angle), math.sin(angle));
        final position =
            centers[burst] + direction * radius + Offset(0, t * t * 15);
        final color = [
          gold,
          coral,
          teal,
          const Color(0xFFA782D1),
        ][i % 4].withValues(alpha: opacity);
        canvas.drawLine(
          position - direction * (8 * (1 - t)),
          position,
          Paint()
            ..color = color
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
        star(canvas, position, 2.5 + (1 - t) * 2, color);
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
