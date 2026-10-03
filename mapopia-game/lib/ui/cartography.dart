import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../geo/domain/geo_region.dart';
import '../geo/data/geo_pack.dart';
import '../geo/domain/geo_fit.dart';
import '../geo/domain/geo_piece.dart';
import 'theme.dart';

/// Real geographic outlines with a layered ceramic edge, bevel, soft cast
/// shadow, and fine surface texture. Identical geometry is used for hit testing.
void paintCeramic(
  Canvas canvas,
  Path path,
  Color color, {
  double depth = 3,
  bool selected = false,
}) {
  final bounds = path.getBounds();
  canvas.drawShadow(
    path.shift(Offset(0, depth)),
    Colors.black.withValues(alpha: .6),
    depth + 2,
    true,
  );
  final edge = Color.lerp(color, const Color(0xFF153C43), .45)!;
  for (double i = depth; i > 0; i -= 1) {
    canvas.drawPath(path.shift(Offset(0, i)), Paint()..color = edge);
  }
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, .24)!,
          color,
          Color.lerp(color, ink, .13)!,
        ],
      ).createShader(bounds),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.8 : .7
      ..color = selected
          ? const Color(0xFFFFE0A0)
          : Colors.white.withValues(alpha: .45),
  );
  canvas.save();
  canvas.clipPath(path);
  canvas.drawPath(
    path.shift(const Offset(0, 1.1)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = Colors.white.withValues(alpha: .4),
  );
  final random = math.Random(17);
  for (
    var i = 0;
    i < (bounds.width * bounds.height / 75).clamp(0, 450).toInt();
    i++
  ) {
    final point = Offset(
      bounds.left + random.nextDouble() * bounds.width,
      bounds.top + random.nextDouble() * bounds.height,
    );
    canvas.drawCircle(
      point,
      .35,
      Paint()..color = Colors.white.withValues(alpha: .20),
    );
  }
  canvas.restore();
}

class MapPainter extends CustomPainter {
  MapPainter({
    required this.pack,
    this.placed = const {},
    this.preview = false,
    this.hintId,
    this.lastId,
    this.pulse = 1,
    this.dark = true,
    this.zoom = 1,
    this.showSmallMarkers = false,
    this.onTarget,
    this.onPlaced,
  });
  final GeoPack pack;
  final Set<String> placed;
  final bool preview, dark;
  final String? hintId, lastId;
  final double pulse;
  final double zoom;
  final bool showSmallMarkers;

  Iterable<GeoPiece> smallPieces(Size size) => pack.paintOrder.where(
    (p) =>
        math.max(p.bounds.width, p.bounds.height) *
            actualFit(size).scale *
            zoom <
        12,
  );
  final void Function(GeoPiece)? onTarget;
  final void Function(GeoPiece)? onPlaced;
  GeoFit fit(Size size) => GeoFit.contain(
    pack.viewBox,
    Size(math.max(1, size.width - 36), math.max(1, size.height - 44)),
  );
  GeoFit actualFit(Size size) {
    final f = fit(size);
    return GeoFit(
      scale: f.scale,
      origin: f.origin + const Offset(18, 20),
      viewBox: pack.viewBox,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final f = actualFit(size);
    final palette = MapPalette(night: dark);
    if (!preview) {
      final bg = Paint()
        ..color = palette.grid
        ..strokeWidth = .6;
      for (double x = 15; x < size.width; x += 28) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), bg);
      }
      for (double y = 10; y < size.height; y += 28) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), bg);
      }
      canvas.drawCircle(
        Offset(size.width * .48, size.height * .52),
        math.min(size.width, size.height) * .43,
        Paint()
          ..color = palette.orbit
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    for (final piece in pack.paintOrder) {
      final path = f.screenPath(piece);
      final active = preview || placed.contains(piece.id);
      if (!active) {
        canvas.drawPath(
          path.shift(const Offset(0, 2)),
          Paint()..color = palette.recess,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = hintId == piece.id
                ? gold.withValues(alpha: .65)
                : palette.empty,
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8
            ..color = hintId == piece.id ? palette.accent : palette.outline,
        );
      } else {
        paintCeramic(
          canvas,
          path,
          pieceColor(piece.id),
          depth: preview ? 2 : 3,
        );
      }
    }
    if (showSmallMarkers) {
      for (final piece in smallPieces(size)) {
        final center = f.toScreen(piece.target);
        canvas.drawCircle(center, 10 / zoom, Paint()..color = palette.empty);
        canvas.drawCircle(
          center,
          10 / zoom,
          Paint()
            ..color = palette.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 / zoom,
        );
        final pen = Paint()
          ..color = palette.accent
          ..strokeWidth = 1.5 / zoom;
        canvas.drawLine(
          center - Offset(4 / zoom, 0),
          center + Offset(4 / zoom, 0),
          pen,
        );
        canvas.drawLine(
          center - Offset(0, 4 / zoom),
          center + Offset(0, 4 / zoom),
          pen,
        );
      }
    }
    if (hintId != null) {
      final p = pack.pieces.firstWhere((p) => p.id == hintId);
      final center = f.toScreen(p.target);
      canvas.drawCircle(
        center,
        16,
        Paint()..color = gold.withValues(alpha: .15),
      );
      canvas.drawCircle(
        center,
        10,
        Paint()
          ..color = palette.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(center, 3, Paint()..color = Colors.white);
    }
    if (lastId != null && pulse < 1) {
      final piece = pack.pieces.firstWhere((p) => p.id == lastId);
      final center = f.toScreen(piece.target);
      canvas.drawCircle(
        center,
        12 + pulse * 38,
        Paint()
          ..color = gold.withValues(alpha: (1 - pulse) * .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - pulse),
      );
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6;
        final radius = 10 + pulse * (i.isEven ? 47 : 31);
        final pt = center + Offset(math.cos(angle), math.sin(angle)) * radius;
        canvas.drawCircle(
          pt,
          2.2 * (1 - pulse),
          Paint()
            ..color = ceramicColors[i % ceramicColors.length].withValues(
              alpha: 1 - pulse,
            ),
        );
      }
    }
    if (!preview) {
      _compass(canvas, Offset(size.width - 27, size.height - 34));
    }
  }

  void _compass(Canvas canvas, Offset c) {
    final accent = MapPalette(night: dark).accent;
    canvas.drawCircle(
      c,
      13,
      Paint()
        ..color = accent.withValues(alpha: .4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - 11)
        ..lineTo(c.dx - 4, c.dy + 6)
        ..lineTo(c.dx, c.dy + 3)
        ..lineTo(c.dx + 4, c.dy + 6)
        ..close(),
      Paint()..color = accent.withValues(alpha: .8),
    );
    final t = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(fontSize: 7, color: accent),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(canvas, c + const Offset(-2.5, -24));
  }

  @override
  bool shouldRepaint(MapPainter old) =>
      old.zoom != zoom ||
      old.showSmallMarkers != showSmallMarkers ||
      old.pack != pack ||
      old.placed != placed ||
      old.preview != preview ||
      old.dark != dark ||
      old.hintId != hintId ||
      old.lastId != lastId ||
      old.pulse != pulse;
  @override
  SemanticsBuilderCallback? get semanticsBuilder =>
      onTarget == null && onPlaced == null
      ? null
      : (size) {
          final f = actualFit(size);
          return pack.pieces
              .where(
                (p) =>
                    placed.contains(p.id) ? onPlaced != null : onTarget != null,
              )
              .map(
                (p) => CustomPainterSemantics(
                  rect: Rect.fromCenter(
                    center: f.toScreen(p.target),
                    width: 24,
                    height: 24,
                  ),
                  properties: SemanticsProperties(
                    label: placed.contains(p.id)
                        ? '${p.name}. View place information'
                        : 'Map position ${pack.pieces.indexOf(p) + 1}',
                    button: true,
                    onTap: () =>
                        placed.contains(p.id) ? onPlaced!(p) : onTarget!(p),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              )
              .toList();
        };
  @override
  bool shouldRebuildSemantics(MapPainter oldDelegate) =>
      oldDelegate.placed != placed ||
      oldDelegate.pack != pack ||
      oldDelegate.onPlaced != onPlaced ||
      oldDelegate.onTarget != onTarget;
}

class PiecePainter extends CustomPainter {
  PiecePainter(this.piece, {this.selected = false});
  final GeoPiece piece;
  final bool selected;
  @override
  void paint(Canvas canvas, Size size) => paintCeramic(
    canvas,
    GeoFit.pieceInBox(piece, size, padding: 9),
    pieceColor(piece.id),
    depth: 4,
    selected: selected,
  );
  @override
  bool shouldRepaint(PiecePainter old) =>
      old.piece != piece || old.selected != selected;
}

class MapThumbnail extends StatelessWidget {
  const MapThumbnail(this.region, {super.key, this.height = 110});
  final GeoRegion region;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: FutureBuilder<GeoPack>(
      future: GeoPack.load(region),
      builder: (context, snapshot) => snapshot.hasData
          ? CustomPaint(
              size: Size.infinite,
              painter: MapPainter(
                pack: snapshot.data!,
                preview: true,
                dark: false,
              ),
            )
          : const Center(child: Icon(Icons.public, color: muted, size: 32)),
    ),
  );
}
