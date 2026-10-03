import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A finite celebration; stays readable and never blocks the review controls.
class SuccessCelebration extends StatefulWidget {
  const SuccessCelebration({super.key});

  @override
  State<SuccessCelebration> createState() => _SuccessCelebrationState();
}

class _SuccessCelebrationState extends State<SuccessCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Hooray! Maze complete!',
    liveRegion: true,
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox(
          height: 132,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _Fireworks(_controller.value),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(7, (index) {
                        final t = _controller.value;
                        final dance =
                            math.sin(t * math.pi * 8 - index * .65) *
                            math.sin(t * math.pi);
                        final entrance = Curves.easeOutBack.transform(
                          ((t - index * .025) / .3).clamp(0.0, 1.0),
                        );
                        return Transform.translate(
                          offset: Offset(0, dance * 10 + (1 - entrance) * 28),
                          child: Transform.rotate(
                            angle: dance * .12,
                            child: Container(
                              width: 36,
                              height: 44,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: index.isEven
                                    ? const Color(0xFFDCEEDD)
                                    : const Color(0xFFF2E2B5),
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22304C43),
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'HOORAY!'[index],
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF164440),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Fireworks extends CustomPainter {
  _Fireworks(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [Color(0xFFC99227), Color(0xFF198577), Color(0xFFE58D77)];
    for (var burst = 0; burst < 6; burst++) {
      final t = (progress * 2.4 - burst * .22).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final center = Offset(
        size.width * [.14, .82, .48, .25, .9, .62][burst],
        size.height * [.32, .4, .2, .7, .72, .65][burst],
      );
      final paint = Paint()
        ..color = colors[burst % 3].withValues(alpha: (1 - t) * .8)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      for (var ray = 0; ray < 12; ray++) {
        final angle = ray * math.pi / 6 + burst;
        final direction = Offset(math.cos(angle), math.sin(angle));
        final drift = Offset(0, t * t * 12);
        canvas.drawLine(
          center + direction * (t * 38) + drift,
          center + direction * (t * 38 + (1 - t) * 9) + drift,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Fireworks oldDelegate) =>
      progress != oldDelegate.progress;
}
