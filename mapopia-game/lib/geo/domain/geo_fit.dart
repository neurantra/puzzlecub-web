import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'geo_piece.dart';

/// Maps a region pack's normalized viewBox coordinates to on-screen pixels
/// and back. A "contain" fit — the whole region is scaled to fit the board
/// box and centered, preserving aspect ratio. The same fit drives both the
/// board painter and the drag-drop hit-testing, so they stay in lockstep.
class GeoFit {
  const GeoFit({
    required this.scale,
    required this.origin,
    required this.viewBox,
  });

  /// viewBox-units → pixels multiplier.
  final double scale;

  /// Screen position of viewBox coordinate (0, 0).
  final Offset origin;

  final Size viewBox;

  factory GeoFit.contain(Size viewBox, Size box) {
    if (viewBox.width <= 0 || viewBox.height <= 0) {
      return GeoFit(scale: 1, origin: Offset.zero, viewBox: viewBox);
    }
    final scale = math.min(
      box.width / viewBox.width,
      box.height / viewBox.height,
    );
    final drawn = Size(viewBox.width * scale, viewBox.height * scale);
    final origin = Offset(
      (box.width - drawn.width) / 2,
      (box.height - drawn.height) / 2,
    );
    return GeoFit(scale: scale, origin: origin, viewBox: viewBox);
  }

  Offset toScreen(Offset vb) =>
      Offset(origin.dx + vb.dx * scale, origin.dy + vb.dy * scale);

  Offset toViewBox(Offset screen) =>
      Offset((screen.dx - origin.dx) / scale, (screen.dy - origin.dy) / scale);

  /// Diagonal of the viewBox, in viewBox units — scales a tolerance
  /// fraction into an absolute snap distance.
  double get viewBoxDiagonal => math.sqrt(
    viewBox.width * viewBox.width + viewBox.height * viewBox.height,
  );

  /// Closed [Path] for [piece] at its true place in the region, in screen
  /// coordinates.
  Path screenPath(GeoPiece piece) => _pathFrom(piece, toScreen);

  /// Transforms a path already expressed in viewBox coordinates into
  /// screen coordinates with this fit's scale + origin. Used for the
  /// region silhouette, which `GeoPack` precomputes once in viewBox
  /// space. The matrix is the column-major scale-then-translate
  /// equivalent of [toScreen].
  Path toScreenPath(Path viewBoxPath) {
    final m = Float64List.fromList(<double>[
      scale, 0, 0, 0, //
      0, scale, 0, 0, //
      0, 0, 1, 0, //
      origin.dx, origin.dy, 0, 1, //
    ]);
    return viewBoxPath.transform(m);
  }

  /// Closed [Path] for [piece] scaled to fill [box] (with [padding] on each
  /// side), independent of where the piece sits in the region. Used for
  /// tray thumbnails and drag feedback.
  static Path pieceInBox(GeoPiece piece, Size box, {double padding = 6}) {
    final b = piece.bounds;
    final availW = box.width - padding * 2;
    final availH = box.height - padding * 2;
    if (b.width <= 0 || b.height <= 0 || availW <= 0 || availH <= 0) {
      return Path();
    }
    final scale = math.min(availW / b.width, availH / b.height);
    final dx = (box.width - b.width * scale) / 2;
    final dy = (box.height - b.height * scale) / 2;
    return _pathFrom(
      piece,
      (vb) =>
          Offset(dx + (vb.dx - b.left) * scale, dy + (vb.dy - b.top) * scale),
    );
  }

  static Path _pathFrom(GeoPiece piece, Offset Function(Offset) map) {
    final path = Path();
    for (final ring in piece.rings) {
      if (ring.isEmpty) continue;
      final first = map(ring.first);
      path.moveTo(first.dx, first.dy);
      for (var i = 1; i < ring.length; i++) {
        final p = map(ring[i]);
        path.lineTo(p.dx, p.dy);
      }
      path.close();
    }
    return path;
  }
}
