import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'art.dart' show star;

int sceneForLevel(int level) => ((level - 1) ~/ 25).clamp(0, 3);

class SceneBackdrop extends StatefulWidget {
  final int scene;
  final bool animated;
  const SceneBackdrop({super.key, required this.scene, required this.animated});
  @override
  State<SceneBackdrop> createState() => _SceneBackdropState();
}

class _SceneBackdropState extends State<SceneBackdrop>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    sync();
  }

  final random = math.Random(41);
  late List<Offset> cloudStarts = _cloudStarts();
  List<Offset> _cloudStarts() => List.generate(
    4,
    (_) => Offset(
      -60 - random.nextDouble() * 120,
      .14 + random.nextDouble() * .42,
    ),
  );
  late final AnimationController drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  );
  void sync() {
    if (widget.animated &&
        foreground &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!drift.isAnimating) drift.repeat();
    } else {
      drift.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(SceneBackdrop old) {
    super.didUpdateWidget(old);
    if (old.scene != widget.scene) {
      cloudStarts = _cloudStarts();
      drift.value = 0;
    }
    sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: drift,
      builder: (_, _) => CustomPaint(
        painter: WorldPainter(
          widget.scene,
          drift.value,
          cloudStarts: cloudStarts,
        ),
      ),
    ),
  );
}

class WorldPainter extends CustomPainter {
  final int scene;
  final double phase;
  final List<Offset> cloudStarts;
  WorldPainter(
    this.scene,
    this.phase, {
    this.cloudStarts = const [
      Offset(-60, .17),
      Offset(-110, .31),
      Offset(-150, .44),
      Offset(-85, .55),
    ],
  });
  @override
  void paint(Canvas c, Size s) {
    final palettes = [
      [const Color(0xff87dbf5), const Color(0xffdaf4bf)],
      [const Color(0xff66cfdd), const Color(0xff6599d5)],
      [const Color(0xffffc5aa), const Color(0xffffe8b7)],
      [const Color(0xff9990dd), const Color(0xffd6b9e6)],
    ];
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palettes[scene],
        ).createShader(Offset.zero & s),
    );
    final cycle = phase * math.pi * 2;
    if (scene == 1) {
      // Submerged shafts of light, bubbles, coral and a drifting shoal.
      for (var i = 0; i < 4; i++) {
        final x = s.width * (i * .3 - .15);
        c.drawPath(
          Path()..addPolygon([
            Offset(x, 0),
            Offset(x + 30, 0),
            Offset(x + 150, s.height),
            Offset(x + 50, s.height),
          ], true),
          Paint()..color = Colors.white.withValues(alpha: .06),
        );
      }
      for (var i = 0; i < 14; i++) {
        final x = (i * 67.0 % s.width) + math.sin(cycle + i) * 5;
        final y = (s.height * (1 - (phase + i / 14) % 1));
        c.drawCircle(
          Offset(x, y),
          3 + (i % 4) * 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white.withValues(alpha: .3),
        );
      }
      for (var i = 0; i < 7; i++) {
        final x = ((i * 63 + phase * (s.width + 60)) % (s.width + 60)) - 30,
            y = s.height * (.2 + (i % 3) * .14);
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 15, height: 7),
          Paint()..color = const Color(0xffffe8b0).withValues(alpha: .45),
        );
        c.drawPath(
          Path()..addPolygon([
            Offset(x - 6, y),
            Offset(x - 12, y - 5),
            Offset(x - 12, y + 5),
          ], true),
          Paint()..color = const Color(0xffffe8b0).withValues(alpha: .45),
        );
      }
      for (var i = 0; i < 8; i++) {
        final x = i * s.width / 7, base = s.height;
        final paint = Paint()
          ..color =
              (i.isEven ? const Color(0xffea99b9) : const Color(0xff50b9b4))
                  .withValues(alpha: .65)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        for (var j = 0; j < 3; j++) {
          c.drawPath(
            Path()
              ..moveTo(x, base)
              ..quadraticBezierTo(
                x + (j - 1) * 18,
                base - 55,
                x + (j - 1) * 25 + math.sin(cycle + i) * 3,
                base - 90 - j * 12,
              ),
            paint,
          );
        }
      }
      return;
    }
    if (scene == 3) {
      final moon = Offset(s.width * .82, s.height * .18);
      c.drawCircle(moon, 31, Paint()..color = const Color(0xfffff3d3));
      c.drawCircle(
        moon + const Offset(13, -9),
        28,
        Paint()..color = const Color(0xffaaa0df),
      );
      for (var i = 0; i < 35; i++) {
        final x = (i * 79.0 + 17) % s.width,
            y = (i * 101.0 + 35) % (s.height * .85);
        star(
          c,
          Offset(x, y),
          i % 3 + 1.5,
          Colors.white.withValues(
            alpha: .25 + .3 * (1 + math.sin(cycle + i)) / 2,
          ),
        );
      }
    } else {
      final sun = Offset(s.width * .82, s.height * .18);
      c.drawCircle(
        sun,
        46,
        Paint()..color = const Color(0xffffe5a2).withValues(alpha: .23),
      );
      c.drawCircle(
        sun,
        32,
        Paint()
          ..color = scene == 2
              ? const Color(0xffffb375)
              : const Color(0xffffe895),
      );
      for (final start in cloudStarts) {
        // Fixed seeds survive repaints. Wrap only beyond the right edge,
        // re-entering offscreen left with no visible jump at the loop boundary.
        final span = s.width + 360;
        var x = start.dx + phase * span;
        if (x > s.width + 60) x -= span;
        final y = s.height * start.dy;
        final p = Paint()
          ..color = Colors.white.withValues(alpha: scene == 2 ? .24 : .44);
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 92, height: 19),
          p,
        );
        c.drawCircle(Offset(x + 10, y - 9), 19, p);
        c.drawCircle(Offset(x - 14, y - 4), 13, p);
      }
    }
    final hills = scene == 0
        ? [const Color(0xff83d49d), const Color(0xff5ab994)]
        : scene == 2
        ? [const Color(0xffeba47d), const Color(0xffd58b83)]
        : [const Color(0xff9b8aca), const Color(0xff8073b6)];
    for (var i = 0; i < 2; i++) {
      final y = s.height * (.68 + i * .13);
      c.drawPath(
        Path()
          ..moveTo(0, y)
          ..cubicTo(
            s.width * .25,
            y - 65,
            s.width * .55,
            y + 50,
            s.width,
            y - 30,
          )
          ..lineTo(s.width, s.height)
          ..lineTo(0, s.height)
          ..close(),
        Paint()..color = hills[i],
      );
    }
    if (scene == 2) {
      // Dune ripples and a little desert vegetation distinguish this world.
      for (var i = 0; i < 5; i++) {
        final y = s.height * (.77 + i * .037);
        c.drawPath(
          Path()
            ..moveTo(0, y)
            ..quadraticBezierTo(s.width * .4, y - 30, s.width, y + 10),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xffffdab0).withValues(alpha: .4),
        );
      }
      for (final x in [s.width * .07, s.width * .94]) {
        final p = Paint()
          ..color = const Color(0xffb47677)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round;
        c.drawLine(Offset(x, s.height * .88), Offset(x, s.height * .74), p);
        c.drawLine(Offset(x, s.height * .8), Offset(x - 12, s.height * .78), p);
      }
    } else {
      for (var i = 0; i < 12; i++) {
        final x = (i * 57.0 + 12) % s.width,
            y = s.height * (.75 + (i % 4) * .06);
        c.drawLine(
          Offset(x, y),
          Offset(x, y + 17),
          Paint()
            ..color = const Color(0xff589883)
            ..strokeWidth = 2,
        );
        for (var j = 0; j < 5; j++) {
          final a = j * math.pi * 2 / 5;
          c.drawCircle(
            Offset(x + math.cos(a) * 4, y + math.sin(a) * 4),
            3.4,
            Paint()
              ..color = i.isEven
                  ? const Color(0xffffdc91)
                  : const Color(0xffffc4da),
          );
        }
        if (scene == 3) {
          c.drawCircle(
            Offset(
              x + math.sin(cycle + i) * 8,
              y - 25 + math.cos(cycle + i) * 4,
            ),
            2,
            Paint()..color = const Color(0xfffff8ad).withValues(alpha: .7),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(WorldPainter old) =>
      scene != old.scene ||
      phase != old.phase ||
      cloudStarts != old.cloudStarts;
}
