import 'dart:ui';

/// One assemblable region piece — a US state or a European country.
///
/// Geometry is in the parent [GeoPack]'s normalized viewBox space. The
/// build tool (`tools/build-geo-packs.mjs`) has already projected the raw
/// lat/long geometry, simplified it, and normalized it into that box, so
/// the runtime never sees a map projection.
class GeoPiece {
  GeoPiece({
    required this.id,
    required this.name,
    required this.capital,
    required this.fact,
    required this.expertClue,
    required this.target,
    required this.rings,
    required this.neighbors,
  }) : bounds = _ringsBounds(rings);

  /// Stable identifier, e.g. `US-TX` or `EU-FRA`.
  final String id;

  /// Display name, e.g. `Texas` / `France`.
  final String name;

  /// Capital city — surfaced in the placement fact card. May be empty.
  final String capital;

  /// One-line teaching fact shown when the piece is placed correctly.
  final String fact;

  /// Curated identifying clue used as the Expert-tier tray card. MUST
  /// NOT name the country, since the player's job is to identify it.
  /// Empty when no clue has been authored for this piece — Expert tier
  /// is hidden for regions where no pieces have clues.
  final String expertClue;

  /// Centroid of the piece's correct slot, in viewBox coordinates.
  final Offset target;

  /// Polygon rings, in viewBox coordinates. Most pieces have a single
  /// ring; islands and multi-part pieces (e.g. Hawaii) have several.
  final List<List<Offset>> rings;

  /// Ids of pieces sharing a real border — drives Hard-mode adjacency.
  final List<String> neighbors;

  /// Axis-aligned bounds of all rings, in viewBox coordinates.
  final Rect bounds;

  factory GeoPiece.fromJson(Map<String, dynamic> json) {
    final rings = (json['rings'] as List)
        .map(
          (ring) => (ring as List)
              .map((pt) {
                final p = (pt as List).cast<num>();
                return Offset(p[0].toDouble(), p[1].toDouble());
              })
              .toList(growable: false),
        )
        .toList(growable: false);
    final target = (json['target'] as List).cast<num>();
    return GeoPiece(
      id: json['id'] as String,
      name: json['name'] as String,
      capital: json['capital'] as String? ?? '',
      fact: json['fact'] as String? ?? '',
      expertClue: json['expertClue'] as String? ?? '',
      target: Offset(target[0].toDouble(), target[1].toDouble()),
      rings: rings,
      neighbors: (json['neighbors'] as List? ?? const <String>[])
          .cast<String>(),
    );
  }

  static Rect _ringsBounds(List<List<Offset>> rings) {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final ring in rings) {
      for (final p in ring) {
        if (p.dx < minX) minX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }
    }
    if (minX > maxX) return Rect.zero;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
