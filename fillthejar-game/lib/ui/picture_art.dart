import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/geometry.dart';

/// Artwork is a destination-based reveal. It never participates in collision or scoring.
class PictureArt {
  static const asset = 'assets/pictures/fox.png';
  static final image = ValueNotifier<ui.Image?>(null);
  static String _currentAsset = asset;
  static final Map<String, Future<ui.Image>> _cache = {};
  static Future<void> load({String asset = PictureArt.asset}) async {
    if (_currentAsset == asset && image.value != null) return;
    if (_currentAsset != asset) {
      _currentAsset = asset;
      image.value = null;
    }
    try {
      final decoded = await (_cache[asset] ??= _decode(asset));
      if (_currentAsset == asset) image.value = decoded;
    } catch (_) {
      _cache.remove(asset);
      rethrow;
    }
  }

  static Future<ui.Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final result = (await codec.getNextFrame()).image;
    codec.dispose();
    return result;
  }

  static void draw(Canvas canvas, Rect destination, {double opacity = 1}) {
    final art = image.value;
    if (art == null) return;
    final sourceSize = Size(art.width.toDouble(), art.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, sourceSize, destination.size);
    canvas.drawImageRect(
      art,
      Alignment.center.inscribe(fitted.source, Offset.zero & sourceSize),
      destination,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withValues(alpha: opacity),
    );
  }

  static void fragment(
    Canvas canvas,
    Path clip,
    Piece piece,
    Puzzle puzzle,
    Offset origin,
    double scale, {
    double opacity = 1,
  }) {
    if (image.value == null) return;
    canvas.save();
    canvas.clipPath(clip);
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    // Crop from the destination, not the identity or original rotation.
    draw(
      canvas,
      Rect.fromLTWH(-piece.x, -piece.y, puzzle.w, puzzle.h),
      opacity: opacity,
    );
    canvas.restore();
  }
}
