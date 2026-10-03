import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/geometry.dart';

/// Model-space point. Rotation is rigid; no angle-dependent scaling is used.
class Point3 {
  final double x, y, z;
  const Point3(this.x, this.y, this.z);
  Point3 operator -(Point3 b) => Point3(x - b.x, y - b.y, z - b.z);
  Point3 cross(Point3 b) =>
      Point3(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x);
  double get length => math.sqrt(x * x + y * y + z * z);
  Point3 rotated(double yaw, double pitch) {
    final xx = x * math.cos(yaw) + z * math.sin(yaw);
    final zz = -x * math.sin(yaw) + z * math.cos(yaw);
    return Point3(
      xx,
      y * math.cos(pitch) - zz * math.sin(pitch),
      y * math.sin(pitch) + zz * math.cos(pitch),
    );
  }
}

class SolidFace {
  final List<Point3> points;
  final Color color;
  final bool glass;
  SolidFace(this.points, this.color, {this.glass = false});
}

const solidColors = [
  Color(0xffff718d),
  Color(0xffffc64f),
  Color(0xff58cdb5),
  Color(0xff8f7af3),
  Color(0xff58b6ed),
  Color(0xffffa75c),
  Color(0xffe783d1),
  Color(0xff96d65b),
];

/// All pieces occupy the same fixed depth inside the glass cavity.
List<SolidFace> pieceMesh(
  Piece piece, {
  double centerX = 0,
  double centerY = 0,
  double thickness = .64,
}) {
  final out = <SolidFace>[];
  final color = solidColors[piece.id % solidColors.length];
  final pts = piece.points
      .map((p) => p + Offset(piece.x - centerX, piece.y - centerY))
      .toList();
  var area = 0.0;
  for (var i = 0; i < pts.length; i++) {
    final a = pts[i], b = pts[(i + 1) % pts.length];
    area += a.dx * b.dy - b.dx * a.dy;
  }
  if (area < 0) {
    final reversed = pts.reversed.toList();
    pts.setAll(0, reversed);
  }
  // An actual inset creates bevels without drawing over neighboring pieces.
  final inset = <Offset>[];
  final bevel = math.min(.055, math.min(piece.w, piece.h) * .065);
  for (var i = 0; i < pts.length; i++) {
    final a = pts[(i + pts.length - 1) % pts.length],
        b = pts[i],
        c = pts[(i + 1) % pts.length];
    final e = b - a, f = c - b;
    final n = Offset(-e.dy, e.dx) / e.distance,
        m = Offset(-f.dy, f.dx) / f.distance;
    final bis = n + m;
    inset.add(b + bis * (bevel / (1 + n.dx * m.dx + n.dy * m.dy)));
  }
  final z = thickness / 2;
  List<Point3> ring(List<Offset> p, double z) =>
      p.map((v) => Point3(v.dx, v.dy, z)).toList();
  final front = ring(inset, z),
      back = ring(inset, -z),
      edgeFront = ring(pts, z - bevel),
      edgeBack = ring(pts, -z + bevel);
  out.add(SolidFace(front, color));
  out.add(SolidFace(back.reversed.toList(), color));
  for (var i = 0; i < pts.length; i++) {
    final j = (i + 1) % pts.length;
    out.add(SolidFace([front[j], front[i], edgeFront[i], edgeFront[j]], color));
    out.add(
      SolidFace([edgeFront[j], edgeFront[i], edgeBack[i], edgeBack[j]], color),
    );
    out.add(SolidFace([edgeBack[j], edgeBack[i], back[i], back[j]], color));
  }
  return out;
}

List<SolidFace> jarMesh(Puzzle p) {
  final out = <SolidFace>[];
  // A rectangular glass vessel with chamfered corners, an open mouth and a thick base.
  List<Offset> outline(double w, double d, double cut) => [
    Offset(-w / 2 + cut, -d / 2),
    Offset(w / 2 - cut, -d / 2),
    Offset(w / 2, -d / 2 + cut),
    Offset(w / 2, d / 2 - cut),
    Offset(w / 2 - cut, d / 2),
    Offset(-w / 2 + cut, d / 2),
    Offset(-w / 2, d / 2 - cut),
    Offset(-w / 2, -d / 2 + cut),
  ];
  final outside = outline(p.w + .24, 1.14, .12),
      inside = outline(p.w + .04, .86, .06);
  Point3 v(Offset q, double y) => Point3(q.dx, y, q.dy);
  final top = -p.h / 2 - .13, bottom = p.h / 2 + .14;
  for (var i = 0; i < outside.length; i++) {
    final j = (i + 1) % outside.length;
    out.add(
      SolidFace(
        [
          v(outside[i], top),
          v(outside[j], top),
          v(outside[j], bottom),
          v(outside[i], bottom),
        ],
        const Color(0xffa7d8e8),
        glass: true,
      ),
    );
    out.add(
      SolidFace(
        [
          v(outside[i], top),
          v(inside[i], top),
          v(inside[j], top),
          v(outside[j], top),
        ],
        const Color(0xffe5faff),
        glass: true,
      ),
    );
    out.add(
      SolidFace(
        [
          v(outside[i], bottom),
          v(outside[j], bottom),
          v(inside[j], bottom - .14),
          v(inside[i], bottom - .14),
        ],
        const Color(0xffd3edf5),
        glass: true,
      ),
    );
  }
  out.add(
    SolidFace(
      outside.map((q) => v(q, bottom)).toList(),
      const Color(0xffc0dfea),
      glass: true,
    ),
  );
  return out;
}

class SolidScenePainter extends CustomPainter {
  final Puzzle puzzle;
  final List<Piece> board;
  final Piece? piece;
  final double yaw, pitch;
  final bool thumbnail;
  final double? scaleOverride;
  final Offset? centerOverride;
  SolidScenePainter(
    this.puzzle,
    this.board,
    this.piece,
    this.yaw,
    this.pitch, {
    this.thumbnail = false,
    this.scaleOverride,
    this.centerOverride,
  });

  /// This camera scale is invariant under rotation, preventing zoom/pumping.
  double cameraScale(Size size) {
    if (scaleOverride != null) return scaleOverride!;
    final w = piece?.w ?? puzzle.w + .3, h = piece?.h ?? puzzle.h + .3;
    if (thumbnail) {
      final corners = [
        for (final x in [-w / 2, w / 2])
          for (final y in [-h / 2, h / 2])
            for (final z in [-.32, .32]) Point3(x, y, z).rotated(yaw, pitch),
      ];
      final spanX =
          corners.map((v) => v.x).reduce(math.max) -
          corners.map((v) => v.x).reduce(math.min);
      final spanY =
          corners.map((v) => v.y).reduce(math.max) -
          corners.map((v) => v.y).reduce(math.min);
      return math.min((size.width - 4) / spanX, (size.height - 4) / spanY);
    }
    final diameter = math.sqrt(w * w + h * h + 1.3 * 1.3);
    return math.max(0, math.min(size.width - 16, size.height - 16) / diameter);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final faces = <SolidFace>[];
    if (piece != null) {
      final p = piece!;
      faces.addAll(
        pieceMesh(p, centerX: p.x + p.w / 2, centerY: p.y + p.h / 2),
      );
    } else {
      faces.addAll(jarMesh(puzzle));
      for (final p in board) {
        faces.addAll(
          pieceMesh(p, centerX: puzzle.w / 2, centerY: puzzle.h / 2),
        );
      }
    }
    final scale = cameraScale(size),
        center = centerOverride ?? Offset(size.width / 2, size.height / 2);
    final projected =
        <
          ({SolidFace face, List<Point3> vertices, double depth, Point3 normal})
        >[];
    for (final face in faces) {
      final v = face.points.map((p) => p.rotated(yaw, pitch)).toList();
      final n = (v[1] - v[0]).cross(v[2] - v[0]);
      if (!face.glass && n.z <= .000001) continue;
      projected.add((
        face: face,
        vertices: v,
        depth: v.fold<double>(0, (s, p) => s + p.z) / v.length,
        normal: n,
      ));
    }
    projected.sort((a, b) => a.depth.compareTo(b.depth));
    for (final f in projected) {
      final path = Path()
        ..addPolygon(
          f.vertices.map((v) => center + Offset(v.x, v.y) * scale).toList(),
          true,
        );
      if (f.face.glass) {
        canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.white.withValues(alpha: .24),
                f.face.color.withValues(alpha: .035),
                f.face.color.withValues(alpha: .055),
                Colors.white.withValues(alpha: .18),
              ],
              stops: const [0, .12, .85, 1],
            ).createShader(path.getBounds().inflate(.01)),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (thumbnail ? .6 : 1.1)
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white.withValues(alpha: .62),
        );
      } else {
        final n = f.normal, len = n.length;
        final light = ((-n.x * .35 - n.y * .5 + n.z * .79) / len).clamp(
          0.0,
          1.0,
        );
        final shade = Color.lerp(
          const Color(0xff26283d),
          f.face.color,
          .65 + light * .35,
        )!;
        canvas.drawPath(path, Paint()..color = shade);
        // Tiny same-color seam avoids anti-alias cracks between bevel facets.
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .35
            ..color = shade,
        );
      }
    }
  }

  @override
  bool shouldRepaint(SolidScenePainter old) => true;
}
