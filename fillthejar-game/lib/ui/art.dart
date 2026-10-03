import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/geometry.dart';
import 'solid_scene.dart';

const ink = Color(0xff393061);
const purple = Color(0xff7554d8);
const candy = [
  Color(0xffff718d),
  Color(0xffffc64f),
  Color(0xff58cdb5),
  Color(0xff8f7af3),
  Color(0xff58b6ed),
  Color(0xffffa75c),
  Color(0xffe783d1),
  Color(0xff96d65b),
];
const sceneNames = [
  'Sunshine meadow',
  'Coral daydream',
  'Sunset dunes',
  'Starlight garden',
];

void star(Canvas canvas, Offset center, double radius, Color color) {
  final path = Path();
  for (int i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5,
        r = i.isEven ? radius : radius * .45;
    final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  canvas.drawPath(path, Paint()..color = color);
}

Path polygonPath(Piece p, double scale, Offset origin) =>
    Path()..addPolygon(p.points.map((q) => origin + q * scale).toList(), true);
void drawPiece(
  Canvas canvas,
  Piece p,
  double scale,
  Offset origin, {
  bool dimension = false,
  bool ghost = false,
  bool label = true,
  Offset depth = const Offset(9, -10),
}) {
  final color = candy[p.id % candy.length],
      path = polygonPath(p, scale, origin);
  if (dimension && !ghost && depth.distanceSquared > 0) {
    canvas.drawShadow(path, ink.withValues(alpha: .45), 5, false);
    canvas.drawPath(
      path.shift(depth),
      Paint()..color = Color.lerp(color, ink, .32)!,
    );
    for (int i = 0; i < p.points.length; i++) {
      final a = origin + p.points[i] * scale,
          b = origin + p.points[(i + 1) % p.points.length] * scale;
      final face = Path()..addPolygon([a, b, b + depth, a + depth], true);
      canvas.drawPath(
        face,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, .2)!,
              Color.lerp(color, ink, .4)!,
            ],
          ).createShader(face.getBounds().inflate(1)),
      );
      canvas.drawPath(
        face,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = Colors.white.withValues(alpha: .4),
      );
    }
  }
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, dimension ? .48 : .15)!,
          color,
          if (dimension) Color.lerp(color, ink, .12)!,
        ],
      ).createShader(path.getBounds())
      ..color = color.withValues(alpha: ghost ? .35 : 1),
  );
  if (ghost) {
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: .60));
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ghost ? 2 : 1.5
      ..strokeJoin = StrokeJoin.round
      ..color = ghost
          ? purple.withValues(alpha: .65)
          : Colors.white.withValues(alpha: .85),
  );
  if (dimension && !ghost) {
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: .28),
    );
    canvas.restore();
  }
  if (label && !ghost) {
    final center =
        p.points.fold(Offset.zero, (a, b) => a + b) /
        p.points.length.toDouble();
    final text = TextPainter(
      text: TextSpan(
        text: '${p.id + 1}',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: (scale * .25).clamp(8, 12),
          fontWeight: FontWeight.w800,
          color: ink.withValues(alpha: .7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(
      canvas,
      origin + center * scale - Offset(text.width / 2, text.height / 2),
    );
  }
}

class PiecePainter extends CustomPainter {
  final Piece piece;
  final bool dimension;
  PiecePainter(this.piece, {this.dimension = false});
  @override
  void paint(Canvas canvas, Size size) {
    if (dimension) {
      SolidScenePainter(
        Puzzle(number: 1, title: '', w: piece.w, h: piece.h, pieces: [piece]),
        const [],
        piece,
        -.22,
        .18,
        thumbnail: true,
      ).paint(canvas, size);
      return;
    }
    final scale = math.min(
      (size.width - 8) / piece.w,
      (size.height - 8) / piece.h,
    );
    drawPiece(
      canvas,
      piece,
      scale,
      Offset(
        (size.width - piece.w * scale) / 2,
        (size.height - piece.h * scale) / 2,
      ),
      dimension: dimension,
    );
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.piece != piece || old.dimension != dimension;
}

class JarPainter extends CustomPainter {
  final Puzzle puzzle;
  final List<Piece> board;
  final Piece? ghost;
  final bool dimension;
  final Offset depth;
  JarPainter(
    this.puzzle,
    this.board,
    this.ghost,
    this.dimension, {
    this.depth = const Offset(16, -14),
  });
  static Rect bounds(Size s, Puzzle c) {
    final scale = math.min((s.width - 30) / c.w, (s.height - 32) / c.h);
    return Rect.fromLTWH(
      (s.width - c.w * scale) / 2,
      (s.height - c.h * scale) / 2,
      c.w * scale,
      c.h * scale,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = bounds(size, puzzle),
        scale = r.width / puzzle.w,
        outer = r.inflate(9);
    if (dimension) {
      SolidScenePainter(
        puzzle,
        board,
        null,
        0,
        0,
        scaleOverride: scale,
        centerOverride: r.center,
      ).paint(canvas, size);
      if (ghost != null) {
        final p = ghost!;
        drawPiece(
          canvas,
          p,
          scale,
          r.topLeft + Offset(p.x, p.y) * scale,
          ghost: true,
        );
      }
      return;
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(r.center.dx, r.bottom + 18),
        width: r.width * .9,
        height: 12,
      ),
      Paint()
        ..color = ink.withValues(alpha: .10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // An open U-shaped body: no horizontal stroke sealing the mouth.
    final body = Path()
      ..moveTo(outer.left, outer.top + 1)
      ..lineTo(outer.left, outer.bottom - 22)
      ..quadraticBezierTo(
        outer.left,
        outer.bottom,
        outer.left + 22,
        outer.bottom,
      )
      ..lineTo(outer.right - 22, outer.bottom)
      ..quadraticBezierTo(
        outer.right,
        outer.bottom,
        outer.right,
        outer.bottom - 22,
      )
      ..lineTo(outer.right, outer.top + 1);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .8),
            Colors.white.withValues(alpha: .38),
            Colors.white.withValues(alpha: .72),
          ],
        ).createShader(outer),
    );
    canvas.save();
    canvas.clipRect(r);
    for (int i = 0; i <= puzzle.w; i++) {
      canvas.drawLine(
        Offset(r.left + i * scale, r.top),
        Offset(r.left + i * scale, r.bottom),
        Paint()..color = purple.withValues(alpha: .06),
      );
    }
    for (int i = 0; i <= puzzle.h; i++) {
      canvas.drawLine(
        Offset(r.left, r.top + i * scale),
        Offset(r.right, r.top + i * scale),
        Paint()..color = purple.withValues(alpha: .06),
      );
    }
    for (final p in board) {
      drawPiece(
        canvas,
        p,
        scale,
        r.topLeft + Offset(p.x, p.y) * scale,
        dimension: dimension,
        depth: Offset.zero,
      );
    }
    if (ghost != null) {
      final p = ghost!;
      drawPiece(
        canvas,
        p,
        scale,
        r.topLeft + Offset(p.x, p.y) * scale,
        ghost: true,
      );
    }
    canvas.restore();
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: .9),
    );
    canvas.drawLine(
      Offset(outer.left + 5, outer.top + 30),
      Offset(outer.left + 5, outer.bottom - 28),
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final mouth = Rect.fromCenter(
      center: Offset(outer.center.dx, outer.top + 1),
      width: outer.width + 2,
      height: 14,
    );
    final opening = Rect.fromCenter(
      center: mouth.center,
      width: mouth.width - 10,
      height: 9,
    );
    // Cool interior shading distinguishes the opening from a solid lid.
    canvas.drawOval(
      opening,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xff5f9cae).withValues(alpha: .42),
            const Color(0xffb5e7ee).withValues(alpha: .28),
          ],
        ).createShader(opening),
    );
    final lip = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(mouth)
      ..addOval(opening);
    canvas.drawPath(lip, Paint()..color = Colors.white.withValues(alpha: .88));
    canvas.drawOval(
      opening,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..color = const Color(0xff80b9c8).withValues(alpha: .7),
    );
    canvas.drawArc(
      mouth,
      0,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(JarPainter old) => true;
}

/// Inspect a rigid solid with a fixed camera scale.
class OrbitView extends StatefulWidget {
  final Puzzle puzzle;
  final List<Piece> board;
  final Piece? piece;
  const OrbitView({
    super.key,
    required this.puzzle,
    required this.board,
    this.piece,
  });
  @override
  State<OrbitView> createState() => _OrbitViewState();
}

class _OrbitViewState extends State<OrbitView> {
  double yaw = -.35, pitch = -.18;
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onPanUpdate: (d) => setState(() {
      yaw = (yaw + d.delta.dx * .01) % (math.pi * 2);
      pitch = (pitch - d.delta.dy * .01).clamp(-1.1, 1.1);
    }),
    onDoubleTap: () => setState(() {
      yaw = -.35;
      pitch = -.18;
    }),
    child: CustomPaint(
      painter: OrbitPainter(
        widget.puzzle,
        widget.board,
        widget.piece,
        yaw,
        pitch,
      ),
      size: Size.infinite,
    ),
  );
}

class OrbitPainter extends CustomPainter {
  final Puzzle puzzle;
  final List<Piece> board;
  final Piece? piece;
  final double yaw, pitch;
  OrbitPainter(this.puzzle, this.board, this.piece, this.yaw, this.pitch);
  @override
  void paint(Canvas canvas, Size size) {
    SolidScenePainter(puzzle, board, piece, yaw, pitch).paint(canvas, size);
  }

  @override
  bool shouldRepaint(OrbitPainter old) =>
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.piece != piece ||
      old.board != board;
}
