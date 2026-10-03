import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../game/geometry.dart';
import 'picture_art.dart';

/// One decoded material shared by all painters; never decode per frame.
class WoodMaterial {
  static final texture = ValueNotifier<ui.Image?>(null);
  static Future<void>? _loading;
  static Future<void> load() => _loading ??= _load();
  static Future<void> _load() async {
    final data = await rootBundle.load('assets/materials/maple.png');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 768,
    );
    texture.value = (await codec.getNextFrame()).image;
    codec.dispose();
  }
}

/// Offset each edge, preserving concave corners and shared-edge clearance.
List<Offset> insetWoodPolygon(List<Offset> points, double distance) {
  var area = 0.0;
  for (int i = 0; i < points.length; i++) {
    final a = points[i], b = points[(i + 1) % points.length];
    area += a.dx * b.dy - b.dx * a.dy;
  }
  final direction = area >= 0 ? 1.0 : -1.0;
  return List.generate(points.length, (i) {
    final a = points[(i + points.length - 1) % points.length];
    final b = points[i], c = points[(i + 1) % points.length];
    final e = b - a, f = c - b;
    if (e.distance < .001 || f.distance < .001) return b;
    final n = Offset(-e.dy, e.dx) / e.distance * direction;
    final m = Offset(-f.dy, f.dx) / f.distance * direction;
    final denominator = 1 + n.dx * m.dx + n.dy * m.dy;
    if (denominator.abs() < .001) return b + n * distance;
    final offset = (n + m) * (distance / denominator);
    final limit = math.min(e.distance, f.distance) * .24;
    return b +
        (offset.distance > limit ? offset / offset.distance * limit : offset);
  });
}

/// One upright orthographic view for the glass and the puzzle plane.
/// The painter supplies depth; a second perspective tilt would skew both.
Matrix4 woodenCamera() => Matrix4.identity();

class WoodenJar extends StatefulWidget {
  final Puzzle puzzle;
  final List<Piece> board;
  final Piece? ghost;
  final bool motion;
  final bool pictureClues, showReference;
  final double reveal;
  final VoidCallback? onLanded;
  const WoodenJar({
    super.key,
    required this.puzzle,
    required this.board,
    required this.ghost,
    required this.motion,
    this.reveal = 0,
    this.pictureClues = false,
    this.showReference = true,
    this.onLanded,
  });

  @override
  State<WoodenJar> createState() => _WoodenJarState();
}

class _WoodenJarState extends State<WoodenJar> {
  int _dropRevision = 0;
  bool _landing = false;

  @override
  void didUpdateWidget(WoodenJar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.board.map((p) => p.id).toSet();
    final added =
        oldWidget.puzzle.key == widget.puzzle.key &&
        widget.board.any((p) => !previous.contains(p.id));
    if (added) {
      _landing = true;
      _dropRevision++;
    } else if (oldWidget.puzzle.key != widget.puzzle.key ||
        widget.board.length < oldWidget.board.length) {
      _landing = false;
    }
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(_dropRevision),
    tween: Tween(begin: 1, end: 0),
    duration: Duration(milliseconds: widget.motion ? 320 : 0),
    curve: Curves.easeOutCubic,
    onEnd: () {
      if (_landing) {
        _landing = false;
        widget.onLanded?.call();
      }
    },
    builder: (context, lift, child) => CustomPaint(
      painter: WoodenJarPainter(
        widget.puzzle,
        widget.board,
        widget.ghost,
        _landing ? lift : 0,
        reveal: widget.reveal,
        pictureClues: widget.pictureClues,
        showReference: widget.showReference,
      ),
      size: Size.infinite,
    ),
  );
}

class WoodenJarPainter extends CustomPainter {
  final Puzzle puzzle;
  final List<Piece> board;
  final Piece? ghost;
  final double lift;
  final bool pictureClues, showReference;
  final double reveal;
  WoodenJarPainter(
    this.puzzle,
    this.board,
    this.ghost,
    this.lift, {
    this.reveal = 0,
    this.pictureClues = false,
    this.showReference = true,
  }) : super(
         repaint: Listenable.merge([WoodMaterial.texture, PictureArt.image]),
       );

  static Rect bounds(Size size, Puzzle puzzle) {
    // Reserve only the glass rim, sidewalls, and base shadow. Fit the actual
    // puzzle directly so painting, taps, and placement arrows share one scale.
    const top = 64.0, bottom = 52.0, sides = 52.0;
    final availableHeight = math.max(1.0, size.height - top - bottom);
    final scale = math.min(
      math.max(1.0, size.width - sides) / puzzle.w,
      availableHeight / puzzle.h,
    );
    final width = puzzle.w * scale, height = puzzle.h * scale;
    return Rect.fromLTWH(
      (size.width - width) / 2,
      top + (availableHeight - height) / 2,
      width,
      height,
    );
  }

  void wood(Canvas canvas, Path path, Color tint, {int seed = 0}) {
    final r = path.getBounds();
    final image = WoodMaterial.texture.value;
    if (image != null) {
      final span = math.max(r.width, r.height) / (image.width * .75);
      final transform = Matrix4.identity()
        ..translateByDouble(
          r.left - (seed * 71 % 190) * span,
          r.top - (seed * 113 % 190) * span,
          0,
          1,
        )
        ..rotateZ((seed % 4) * math.pi / 2)
        ..scaleByDouble(span, span, 1, 1);
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.ImageShader(
            image,
            TileMode.mirror,
            TileMode.mirror,
            transform.storage,
          )
          ..colorFilter = ColorFilter.mode(tint, BlendMode.modulate)
          ..filterQuality = FilterQuality.medium,
      );
    } else {
      canvas.drawPath(
        path,
        Paint()..color = Color.lerp(const Color(0xffefd2a0), tint, .5)!,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .08),
            Colors.transparent,
            const Color(0xff5b3317).withValues(alpha: .09),
          ],
        ).createShader(r),
    );
  }

  Path polygon(List<Offset> points) => Path()..addPolygon(points, true);

  // Front faces stand upright in the vessel. Depth recedes upward toward
  // the far half of the glass rim, exposing top edges rather than undersides.
  Offset thickness(double scale) => Offset(0, -(scale * .16).clamp(5.0, 10.0));

  void piece(
    Canvas canvas,
    Piece p,
    double scale,
    Offset origin, {
    double elevation = 0,
    bool sidesOnly = false,
    bool topOnly = false,
    double pictureOpacity = 1,
  }) {
    final raw = p.points
        .map((q) => origin + q * scale - Offset(0, elevation))
        .toList();
    final gap = (scale * .028).clamp(.65, 1.8);
    final bevel = (scale * .035).clamp(.7, 2.1);
    final edge = insetWoodPolygon(raw, gap);
    final top = insetWoodPolygon(raw, gap + bevel);
    final depth = thickness(scale);
    final path = polygon(edge);
    const tones = [
      Color(0xfffff4e1),
      Color(0xffefd9b5),
      Color(0xfffff9ea),
      Color(0xfff4dfbd),
      Color(0xfff9e6c7),
      Color(0xffead3b1),
    ];
    final tone = tones[p.id % tones.length];
    if (!topOnly) {
      // Broad directional cast shadow, then tight contact occlusion.
      canvas.drawPath(
        path.shift(Offset(0, 2 + elevation * .35)),
        Paint()
          ..color = const Color(0xff281205).withValues(alpha: .20)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            1.5 + elevation * .20,
          ),
      );
      canvas.drawPath(
        path.shift(const Offset(0, 1)),
        Paint()
          ..color = const Color(0xff271307).withValues(alpha: .70)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
      // Draw only the outward-facing sidewalls, using their surface normal.
      for (int i = 0; i < edge.length; i++) {
        final j = (i + 1) % edge.length;
        final a = edge[i], b = edge[j], d = b - a;
        final normal = Offset(d.dy, -d.dx) / d.distance;
        if (normal.dx * depth.dx + normal.dy * depth.dy <= 0) continue;
        final face = polygon([a, b, b + depth, a + depth]);
        final shade =
            (.35 + .24 * (-normal.dx * .6 - normal.dy * .8).clamp(-1, 1)).clamp(
              .20,
              .60,
            );
        wood(
          canvas,
          face,
          Color.lerp(const Color(0xff8e4a19), tone, shade)!,
          seed: p.id + 9,
        );
        canvas.drawPath(
          face,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xff3a1a05).withValues(alpha: .35),
              ],
            ).createShader(face.getBounds()),
        );
      }
    }
    if (sidesOnly) return;
    // Bevels are separate inclined facets. Each catches light according to
    // its edge direction instead of receiving a rectangular outline stroke.
    for (int i = 0; i < edge.length; i++) {
      final j = (i + 1) % edge.length;
      final d = edge[j] - edge[i];
      final outward = Offset(d.dy, -d.dx) / d.distance;
      final light = (-outward.dx * .55 - outward.dy * .75).clamp(-1.0, 1.0);
      final shade = light > 0
          ? Color.lerp(const Color(0xffe8c394), const Color(0xfffff3d5), light)!
          : Color.lerp(
              const Color(0xffd7af7b),
              const Color(0xff976332),
              -light,
            )!;
      final face = polygon([edge[i], edge[j], top[j], top[i]]);
      canvas.drawPath(face, Paint()..color = shade);
      canvas.drawPath(
        face,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .35
          ..color = shade,
      );
    }
    wood(canvas, polygon(top), tone, seed: p.id);
    if (pictureClues) {
      PictureArt.fragment(
        canvas,
        polygon(top),
        p,
        puzzle,
        origin - Offset(0, elevation),
        scale,
        opacity: pictureOpacity,
      );
    }
    // A fine specular edge follows the lit bevel only, never a dark border.
    for (int i = 0; i < top.length; i++) {
      final j = (i + 1) % top.length, d = top[j] - top[i];
      if (d.dx - d.dy > 0) {
        canvas.drawLine(
          top[i],
          top[j],
          Paint()
            ..strokeWidth = .55
            ..color = const Color(0xfffff8e5).withValues(alpha: .75),
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = bounds(size, puzzle);
    final scale = r.width / puzzle.w;
    final depth = thickness(scale);
    final outer = Rect.fromLTRB(
      r.left - 18,
      r.top - 18,
      r.right + depth.dx + 17,
      r.bottom + 4,
    );
    // The far rim is behind the contents; the near rim and reflections are
    // painted last. Elliptical cross-sections give the vessel real depth cues.
    final ellipseHeight = (outer.width * .16).clamp(28.0, 48.0);
    final rim = Rect.fromCenter(
      center: Offset(outer.center.dx, r.top - 35),
      width: outer.width,
      height: ellipseHeight,
    );
    final base = Rect.fromCenter(
      center: Offset(outer.center.dx, outer.bottom + 1),
      width: outer.width - 4,
      height: ellipseHeight * (outer.width - 4) / outer.width,
    );
    final body = Path()
      ..moveTo(rim.left, rim.center.dy)
      ..cubicTo(
        rim.left - 2,
        outer.center.dy,
        base.left - 2,
        base.center.dy - 30,
        base.left,
        base.center.dy,
      )
      ..arcTo(base, math.pi, -math.pi, false)
      ..cubicTo(
        base.right + 2,
        base.center.dy - 30,
        rim.right + 2,
        outer.center.dy,
        rim.right,
        rim.center.dy,
      )
      ..arcTo(rim, 0, -math.pi, false)
      ..close();
    void stroke(Path path, Color color, double width) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width
          ..color = color,
      );
    }

    Path arc(Rect oval, double start, double sweep) =>
        Path()..addArc(oval, start, sweep);
    canvas.drawOval(
      base.shift(const Offset(5, 13)),
      Paint()
        ..color = const Color(0x28516a70)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x457eafbb),
            Color(0x14b6e0e8),
            Color(0x06ffffff),
            Color(0x0cffffff),
            Color(0x4a8ab5bf),
          ],
          stops: [0, .08, .35, .8, 1],
        ).createShader(outer),
    );
    // Thick transparent foot: back ellipse, then a refracted lower edge.
    canvas.drawOval(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x126c9ba5), Color(0x35ffffff), Color(0x7086b3bd)],
        ).createShader(base),
    );
    stroke(arc(base, math.pi, math.pi), const Color(0x55729ca7), 1.4);
    stroke(
      arc(base.shift(const Offset(0, 5)), 0, math.pi),
      const Color(0x99759da7),
      3,
    );
    stroke(arc(rim, math.pi, math.pi), const Color(0x99749aa6), 4);
    stroke(arc(rim.deflate(3), math.pi, math.pi), const Color(0xcfffffff), 1.5);
    final sides = Path()
      ..moveTo(rim.left, rim.center.dy)
      ..lineTo(base.left, base.center.dy)
      ..moveTo(rim.right, rim.center.dy)
      ..lineTo(base.right, base.center.dy);
    stroke(sides, const Color(0x807394a0), 2.5);
    stroke(sides.shift(const Offset(2, 0)), const Color(0xcfffffff), 1.2);
    canvas.save();
    canvas.clipPath(body);
    if (pictureClues && showReference) {
      PictureArt.draw(canvas, r, opacity: .16);
    }
    // All coplanar tops are drawn after every sidewall. A diagonal block's
    // wall can no longer paint across its neighbouring block's top surface.
    final ordered = [...board]..sort((a, b) => a.y.compareTo(b.y));
    for (final topPass in [false, true]) {
      for (final p in ordered) {
        piece(
          canvas,
          p,
          scale,
          r.topLeft +
              Offset(p.x, p.y) * scale -
              Offset(
                0,
                board.isNotEmpty && p.id == board.last.id
                    ? lift * ((p.y + p.h) * scale + 34)
                    : 0,
              ),
          pictureOpacity: board.isNotEmpty && p.id == board.last.id
              ? (1 - lift * 12).clamp(0.0, 1.0)
              : 1,
          sidesOnly: !topPass,
          topOnly: topPass,
        );
      }
    }
    if (reveal > 0) {
      // A single continuous material closes the seams; gameplay polygons stay intact.
      canvas.saveLayer(
        r.inflate(16),
        Paint()..color = Colors.white.withValues(alpha: reveal),
      );
      final slab = Piece(
        id: 0,
        x: 0,
        y: 0,
        w: puzzle.w,
        h: puzzle.h,
        points: [
          Offset.zero,
          Offset(puzzle.w, 0),
          Offset(puzzle.w, puzzle.h),
          Offset(0, puzzle.h),
        ],
      );
      piece(canvas, slab, scale, r.topLeft);
      canvas.restore();
      if (reveal < 1) {
        canvas.save();
        canvas.clipRect(r);
        final x = r.left - r.width * .3 + reveal * r.width * 1.6;
        final sheen = Rect.fromLTWH(
          x - r.width * .22,
          r.top,
          r.width * .44,
          r.height,
        );
        canvas.drawRect(
          sheen,
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(
                  alpha: math.sin(reveal * math.pi) * .45,
                ),
                Colors.transparent,
              ],
            ).createShader(sheen),
        );
        canvas.restore();
      }
    }
    canvas.restore();
    // Reflections cross in front of the blocks, placing them inside glass.
    canvas.save();
    canvas.clipPath(body);
    final leftReflection = Path()
      ..moveTo(rim.left + 11, rim.center.dy + 11)
      ..cubicTo(
        rim.left + 16,
        r.top + 90,
        base.left + 11,
        base.center.dy - 65,
        base.left + 17,
        base.center.dy - 8,
      )
      ..lineTo(base.left + 27, base.center.dy - 4)
      ..cubicTo(
        base.left + 19,
        base.center.dy - 90,
        rim.left + 29,
        r.top + 85,
        rim.left + 26,
        rim.center.dy + 15,
      )
      ..close();
    canvas.drawPath(
      leftReflection,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x80ffffff), Color(0x18ffffff), Color(0x60ffffff)],
        ).createShader(outer),
    );
    final rightReflection = Path()
      ..moveTo(rim.right - 12, rim.center.dy + 17)
      ..quadraticBezierTo(
        rim.right - 20,
        outer.center.dy,
        base.right - 13,
        base.center.dy - 12,
      );
    stroke(rightReflection, const Color(0x50ffffff), 5);
    // Etched graduations curve gently around the front of the cylinder.
    for (int y = 1; y < puzzle.h; y++) {
      final yy = r.top + y * scale;
      final x = r.left + 9;
      final mark = Path()
        ..moveTo(x, yy)
        ..quadraticBezierTo(x + 8, yy + 2, x + (y.isEven ? 23 : 14), yy + 2);
      stroke(mark, const Color(0x8861838e), 1);
      if (y.isEven) {
        final text = TextPainter(
          text: TextSpan(
            text: '${(puzzle.h - y).toInt() * 100}',
            style: const TextStyle(
              fontSize: 7,
              fontFamily: 'Roboto',
              color: Color(0x9961838e),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, Offset(x + 27, yy - 3));
      }
    }
    canvas.restore();
    // The near half of the rolled lip overlaps entering pieces.
    stroke(arc(rim, 0, math.pi), const Color(0x90779da9), 5);
    stroke(
      arc(rim.shift(const Offset(0, -2)), 0, math.pi),
      const Color(0xeeffffff),
      2,
    );
    stroke(arc(rim.deflate(3), 0, math.pi), const Color(0x65799fab), 1);
    stroke(arc(base, 0, math.pi), const Color(0xb8ffffff), 3);
    stroke(arc(base.deflate(4), 0, math.pi), const Color(0x6083aeb8), 1);
  }

  @override
  bool shouldRepaint(WoodenJarPainter old) => true;
}

class WoodenPiecePainter extends CustomPainter {
  final Piece piece;
  WoodenPiecePainter(this.piece)
    : super(
        repaint: Listenable.merge([WoodMaterial.texture, PictureArt.image]),
      );
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      (size.width - 12) / piece.w,
      (size.height - 16) / piece.h,
    );
    WoodenJarPainter(
      Puzzle(number: 1, title: '', w: piece.w, h: piece.h, pieces: [piece]),
      const [],
      null,
      0,
    ).piece(
      canvas,
      piece,
      scale,
      Offset(
        (size.width - piece.w * scale) / 2,
        (size.height - piece.h * scale) / 2 - 3,
      ),
    );
  }

  @override
  bool shouldRepaint(WoodenPiecePainter old) => old.piece != piece;
}
