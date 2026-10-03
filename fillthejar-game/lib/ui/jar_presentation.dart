import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Visual-only choreography: never changes the puzzle, rewards or hit testing.
class JarPresentation extends StatefulWidget {
  final String puzzleKey;
  final bool complete, motion;
  final Widget Function(BuildContext, double reveal) builder;
  const JarPresentation({
    super.key,
    required this.puzzleKey,
    required this.complete,
    required this.motion,
    required this.builder,
  });

  @override
  State<JarPresentation> createState() => _JarPresentationState();
}

class _JarPresentationState extends State<JarPresentation>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );
  late final celebration = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
    value: widget.complete ? 1 : 0,
  );
  bool _started = false, _foreground = true;
  bool get _motion => widget.motion && !MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (_motion) entrance.forward();
    }
    _sync();
  }

  void _sync() {
    if (!_motion) {
      entrance.value = 1;
      celebration.value = widget.complete ? 1 : 0;
    } else if (_foreground) {
      if (entrance.value < 1) entrance.forward();
      if (widget.complete && celebration.value < 1) celebration.forward();
    } else {
      entrance.stop();
      celebration.stop();
    }
  }

  @override
  void didUpdateWidget(JarPresentation old) {
    super.didUpdateWidget(old);
    if (old.puzzleKey != widget.puzzleKey) {
      entrance.value = _motion ? 0 : 1;
      celebration.value = widget.complete ? 1 : 0;
    } else if (old.complete != widget.complete) {
      celebration.value = widget.complete && !_motion ? 1 : 0;
    }
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    entrance.dispose();
    celebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: Listenable.merge([entrance, celebration]),
      builder: (context, _) {
        final arrive = Curves.easeOutBack.transform(entrance.value);
        // Let the final piece land (320 ms) before dissolving the seams.
        final reveal = widget.complete
            ? const Interval(
                .15,
                .48,
                curve: Curves.easeInOutCubic,
              ).transform(celebration.value)
            : 0.0;
        return ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: CustomPaint(
                    painter: JarGlowPainter(
                      entrance: entrance.value,
                      celebration: widget.complete ? celebration.value : 0,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, (1 - arrive) * constraints.maxHeight),
                  child: Transform.scale(
                    scale: .92 + .08 * arrive,
                    child: widget.builder(context, reveal),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: JarSparkPainter(
                      entrance: entrance.value,
                      celebration: widget.complete ? celebration.value : 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class JarGlowPainter extends CustomPainter {
  final double entrance, celebration;
  JarGlowPainter({required this.entrance, required this.celebration});
  @override
  void paint(Canvas canvas, Size size) {
    final arrival = math.sin(entrance * math.pi);
    final victory = math.sin(celebration * math.pi);
    final strength = math.max(arrival, victory);
    if (strength <= .001) return;
    final center = Offset(size.width / 2, size.height * .52);
    final radius = size.shortestSide * .65;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xfffff5ba).withValues(alpha: strength * .7),
            const Color(0xffffd16a).withValues(alpha: strength * .20),
            const Color(0x00ffd16a),
          ],
          stops: const [0, .5, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    if (celebration > .14 && celebration < .8) {
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6 + celebration * .15;
        final inner = Offset(math.cos(angle), math.sin(angle)) * radius * .2;
        final a =
            Offset(math.cos(angle - .055), math.sin(angle - .055)) * radius;
        final b =
            Offset(math.cos(angle + .055), math.sin(angle + .055)) * radius;
        canvas.drawPath(
          Path()..addPolygon([center + inner, center + a, center + b], true),
          Paint()
            ..color = const Color(0xffffe59c).withValues(alpha: victory * .19),
        );
      }
    }
  }

  @override
  bool shouldRepaint(JarGlowPainter old) =>
      entrance != old.entrance || celebration != old.celebration;
}

class JarSparkPainter extends CustomPainter {
  final double entrance, celebration;
  JarSparkPainter({required this.entrance, required this.celebration});
  static const colors = [
    Color(0xffffbf45),
    Color(0xffe8897c),
    Color(0xff69bdb0),
    Color(0xffab89ce),
  ];

  void sparkle(Canvas c, Offset point, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final r = i.isEven ? radius : radius * .25;
      final p = point + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    c.drawPath(path..close(), Paint()..color = color);
  }

  @override
  void paint(Canvas c, Size s) {
    if (entrance > .4 && entrance < 1) {
      final t = (entrance - .4) / .6;
      for (var i = 0; i < 10; i++) {
        final angle = i * math.pi * 2 / 10;
        final point =
            Offset(s.width / 2, s.height * .55) +
            Offset(
              math.cos(angle) * s.width * (.22 + .2 * t),
              math.sin(angle) * s.height * (.25 + .15 * t),
            );
        sparkle(
          c,
          point,
          (1 - t) * 7,
          const Color(0xfffff3be).withValues(alpha: 1 - t),
        );
      }
    }
    for (var burst = 0; burst < 3; burst++) {
      final t = (celebration - .28 - burst * .1) / .5;
      if (t <= 0 || t >= 1) continue;
      final center = Offset(
        s.width * [.18, .82, .5][burst],
        s.height * [.24, .32, .16][burst],
      );
      final radius = s.shortestSide * .23 * Curves.easeOutCubic.transform(t);
      for (var i = 0; i < 16; i++) {
        final angle = i * math.pi * 2 / 16 + burst;
        final direction = Offset(math.cos(angle), math.sin(angle));
        final point = center + direction * radius + Offset(0, t * t * 45);
        final color = colors[(i + burst) % colors.length].withValues(
          alpha: (1 - t) * .9,
        );
        c.drawLine(
          point - direction * (1 - t) * 9,
          point,
          Paint()
            ..color = color
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
        if (i % 4 == 0) sparkle(c, point, 4 * (1 - t), color);
      }
    }
  }

  @override
  bool shouldRepaint(JarSparkPainter old) =>
      entrance != old.entrance || celebration != old.celebration;
}

/// Slow edge lights leave the middle of the board visually quiet.
class WorkshopBackdrop extends StatefulWidget {
  final bool motion;
  const WorkshopBackdrop({super.key, required this.motion});
  @override
  State<WorkshopBackdrop> createState() => _WorkshopBackdropState();
}

class _WorkshopBackdropState extends State<WorkshopBackdrop>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  bool foreground = true;
  void sync() {
    if (widget.motion &&
        foreground &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!drift.isAnimating) drift.repeat();
    } else {
      drift.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(WorkshopBackdrop old) {
    super.didUpdateWidget(old);
    sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(child: CustomPaint(painter: WorkshopPainter(drift))),
  );
}

class WorkshopPainter extends CustomPainter {
  final Animation<double> drift;
  WorkshopPainter(this.drift) : super(repaint: drift);
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xfff8edda), Color(0xffe4c8a2)],
        ).createShader(Offset.zero & s),
    );
    for (var i = 0; i < 14; i++) {
      final phase = (drift.value + i / 14) % 1;
      final x =
          s.width * (i.isEven ? .035 : .965) +
          math.sin(phase * math.pi * 2 + i) * 16;
      final y = s.height * (1.08 - phase * 1.16);
      final opacity = math.sin(phase * math.pi) * .22;
      c.drawCircle(
        Offset(x, y),
        3 + (i % 3) * 2,
        Paint()..color = const Color(0xfffffcdf).withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(WorkshopPainter old) => drift != old.drift;
}
