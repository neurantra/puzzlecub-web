import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'appearance.dart';

/// All finishes use the same beveled inlay. Only color and grain vary.
class BoardTile extends StatelessWidget {
  const BoardTile({
    super.key,
    required this.surface,
    required this.file,
    required this.rank,
    this.tint,
    this.child,
  });
  final BoardSurface surface;
  final int file, rank;
  final Color? tint;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final field = surface.fieldAt(file, rank);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(field, Colors.white, .025)!,
            Color.lerp(field, Colors.black, .025)!,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _GrainPainter(surface.pattern, file, rank)),
          if (tint != null) ColoredBox(color: tint!),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: .12),
                  width: .7,
                ),
                left: BorderSide(
                  color: Colors.white.withValues(alpha: .08),
                  width: .7,
                ),
                right: BorderSide(
                  color: Colors.black.withValues(alpha: .10),
                  width: .8,
                ),
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: .12),
                  width: .8,
                ),
              ),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter(this.pattern, this.file, this.rank);
  final BoardPattern pattern;
  final int file, rank;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6;
    switch (pattern) {
      case BoardPattern.grain:
      case BoardPattern.checker:
        paint.color = const Color(0x0B734827);
        for (var i = 0; i < 12; i++) {
          final y = (i / 12) * size.height;
          final path = Path()..moveTo(0, y);
          for (var x = 0.0; x <= size.width; x += 2) {
            final phase = (x + file * size.width) / size.width * 2;
            path.lineTo(
              x,
              y + math.sin(phase + i * .8 + rank) * size.height * .035,
            );
          }
          canvas.drawPath(path, paint);
        }
      case BoardPattern.marble:
        paint.color = const Color(0x22666C70);
        for (var i = -1; i < 4; i++) {
          final y = size.height * (i * .42 + .12 * file);
          canvas.drawPath(
            Path()
              ..moveTo(0, y)
              ..cubicTo(
                size.width * .35,
                y + size.height * .4,
                size.width * .65,
                y - size.height * .2,
                size.width,
                y + size.height * .55,
              ),
            paint,
          );
        }
      case BoardPattern.lattice:
        paint.color = const Color(0x18D7B575);
        final c = size.center(Offset.zero);
        final r = size.width * .29;
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r)
            ..lineTo(c.dx + r, c.dy)
            ..lineTo(c.dx, c.dy + r)
            ..lineTo(c.dx - r, c.dy)
            ..close(),
          paint,
        );
        canvas.drawCircle(c, r * .4, paint);
      case BoardPattern.slate:
        paint.color = const Color(0x18FFFFFF);
        final random = math.Random(file * 71 + rank * 131);
        for (var i = 0; i < 32; i++) {
          canvas.drawLine(
            Offset(
              random.nextDouble() * size.width,
              random.nextDouble() * size.height,
            ),
            Offset(
              random.nextDouble() * size.width,
              random.nextDouble() * size.height,
            ),
            paint..strokeWidth = .25,
          );
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) =>
      pattern != old.pattern || file != old.file || rank != old.rank;
}
