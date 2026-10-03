import 'dart:math' as math;
import 'dart:ui';

const epsilon = 1e-7;

class Piece {
  final int id;
  final double x, y, w, h;
  final List<Offset> points;
  const Piece({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.points,
  });
  factory Piece.fromJson(Map<String, dynamic> j) => Piece(
    id: j['id'] as int,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    w: (j['w'] as num).toDouble(),
    h: (j['h'] as num).toDouble(),
    points: (j['points'] as List)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    'points': points.map((p) => [p.dx, p.dy]).toList(),
  };
  Piece at(double x, double y) =>
      Piece(id: id, x: x, y: y, w: w, h: h, points: points);
  Piece rotated() => Piece(
    id: id,
    x: x,
    y: y,
    w: h,
    h: w,
    points: points.map((p) => Offset(h - p.dy, p.dx)).toList(),
  );
  List<Offset> get world => points.map((p) => p + Offset(x, y)).toList();
  double get area {
    double sum = 0;
    for (int i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum.abs() / 2;
  }

  String get pileKey {
    final p = [...points]
      ..sort(
        (a, b) => a.dx == b.dx ? a.dy.compareTo(b.dy) : a.dx.compareTo(b.dx),
      );
    return p
        .map(
          (p) =>
              '${(p.dx.abs() < epsilon ? 0.0 : p.dx).toStringAsFixed(7)},${(p.dy.abs() < epsilon ? 0.0 : p.dy).toStringAsFixed(7)}',
        )
        .join(';');
  }

  String get name {
    if (points.length == 3) return 'Triangle';
    if (points.length == 5) return 'Pentagon';
    if (points.length == 6) return 'Hexagon';
    final edges = List.generate(
      points.length,
      (i) => points[(i + 1) % points.length] - points[i],
    );
    final right = List.generate(
      edges.length,
      (i) => dot(edges[i], edges[(i + 1) % edges.length]).abs() < epsilon,
    ).every((v) => v);
    final equal = edges.every(
      (e) => (e.distance - edges.first.distance).abs() < epsilon,
    );
    return right
        ? (equal ? 'Square' : 'Rectangle')
        : (equal ? 'Rhombus' : 'Parallelogram');
  }
}

class Puzzle {
  final int number;
  final String title;
  final int revision;
  final String? preview;
  final double w, h;
  final List<Piece> pieces;
  const Puzzle({
    required this.number,
    required this.title,
    this.revision = 1,
    this.preview,
    required this.w,
    required this.h,
    required this.pieces,
  });
  factory Puzzle.fromJson(Map<String, dynamic> j) => Puzzle(
    number: (j['number'] as int?) ?? 1,
    revision: (j['revision'] as int?) ?? 1,
    title: (j['title'] ?? j['theme']) as String,
    preview: j['preview'] as String?,
    w: (j['w'] as num).toDouble(),
    h: (j['h'] as num).toDouble(),
    pieces: (j['pieces'] as List)
        .map((p) => Piece.fromJson(Map<String, dynamic>.from(p)))
        .toList(),
  );
  String get key => preview ?? 'level-$number';
}

class Pile {
  final String key;
  final List<Piece> members;
  final List<Piece> available;
  Pile(this.key, this.members, this.available);
}

List<Pile> piles(Puzzle puzzle, List<Piece> board) {
  final groups = <String, List<Piece>>{};
  for (final p in puzzle.pieces) {
    groups.putIfAbsent(p.pileKey, () => []).add(p);
  }
  final used = board.map((p) => p.id).toSet();
  return groups.entries
      .map(
        (e) => Pile(
          e.key,
          e.value,
          e.value.where((p) => !used.contains(p.id)).toList(),
        ),
      )
      .toList();
}

double dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;
Iterable<Offset> axes(List<Offset> a, List<Offset> b) sync* {
  for (final v in [a, b]) {
    for (int i = 0; i < v.length; i++) {
      final d = v[(i + 1) % v.length] - v[i];
      yield Offset(-d.dy, d.dx);
    }
  }
}

(double, double) projection(List<Offset> points, Offset axis) {
  final values = points.map((p) => dot(p, axis));
  return (values.reduce(math.min), values.reduce(math.max));
}

bool overlaps(Piece p, Piece q) {
  final a = p.world, b = q.world;
  return axes(a, b).every((axis) {
    final (amin, amax) = projection(a, axis);
    final (bmin, bmax) = projection(b, axis);
    return amax > bmin + epsilon && bmax > amin + epsilon;
  });
}

double contact(Piece moving, Piece fixed, {double direction = 1}) =>
    movementContact(moving, fixed, Offset(0, direction));

/// Continuous swept polygon collision: the first contact along a translation.
/// Checking only the destination would let fast drags tunnel through blocks.
double movementContact(Piece moving, Piece fixed, Offset velocity) {
  final a = moving.world, b = fixed.world;
  double enter = double.negativeInfinity, exit = double.infinity;
  for (final axis in axes(a, b)) {
    final (amin, amax) = projection(a, axis);
    final (bmin, bmax) = projection(b, axis);
    final speed = dot(axis, velocity);
    if (speed.abs() < epsilon) {
      if (amax <= bmin + epsilon || bmax <= amin + epsilon) {
        return double.infinity;
      }
      continue;
    }
    final t1 = (bmin - amax) / speed, t2 = (bmax - amin) / speed;
    enter = math.max(enter, math.min(t1, t2));
    exit = math.min(exit, math.max(t1, t2));
  }
  return enter < exit - epsilon && exit > epsilon
      ? math.max(0, enter)
      : double.infinity;
}

Piece? landing(List<Piece> board, Piece p, double x, double w, double h) {
  if (!x.isFinite ||
      x < -epsilon ||
      x + p.w > w + epsilon ||
      p.h > h + epsilon) {
    return null;
  }
  final start = p.at(x, -p.h);
  double distance = h;
  for (final q in board) {
    distance = math.min(distance, contact(start, q));
  }
  final y = distance - p.h;
  if (y < -epsilon) return null;
  return p.at(x, y.abs() < epsilon ? 0 : y);
}

bool canLift(List<Piece> board, Piece p) =>
    board.any((q) => q.id == p.id) &&
    board
        .where((q) => q.id != p.id)
        .every((q) => contact(p, q, direction: -1) >= p.y + p.h - epsilon);

/// Slide horizontally along supports, then settle from the current
/// height (never re-drop from the mouth or lift over an obstacle).
Piece slidePiece(
  List<Piece> board,
  Piece p,
  Offset target,
  double w,
  double h,
) {
  if (!target.dx.isFinite || !target.dy.isFinite) return p;
  // Resolve sideways first so a small downward finger drift does not jam
  // a supported block. Gravity supplies only physically reachable descent.
  final delta = Offset(target.dx.clamp(0, w - p.w) - p.x, 0);
  final others = board.where((q) => q.id != p.id).toList();
  double fraction = 1;
  if (delta.distance > epsilon) {
    for (final q in others) {
      fraction = math.min(fraction, movementContact(p, q, delta));
    }
  }
  final position = Offset(p.x, p.y) + delta * fraction;
  final moved = p.at(position.dx, position.dy);
  double fall = math.max(0, h - moved.y - moved.h);
  for (final q in others) {
    fall = math.min(fall, contact(moved, q));
  }
  return moved.at(moved.x, moved.y + fall);
}

Piece? pieceAt(List<Piece> board, Offset point) {
  for (final p in board.reversed) {
    final path = Path()..addPolygon(p.world, true);
    if (path.contains(point)) return p;
  }
  return null;
}

bool solved(List<Piece> board, Puzzle c) {
  if ((board.fold<double>(0, (n, p) => n + p.area) - c.w * c.h).abs() >
      epsilon) {
    return false;
  }
  for (int i = 0; i < board.length; i++) {
    final p = board[i];
    if (p.x < -epsilon ||
        p.y < -epsilon ||
        p.x + p.w > c.w + epsilon ||
        p.y + p.h > c.h + epsilon) {
      return false;
    }
    for (final q in board.skip(i + 1)) {
      if (overlaps(p, q)) return false;
    }
  }
  return true;
}

bool sameShape(Piece a, Piece b) =>
    a.points.length == b.points.length &&
    a.world.every((p) => b.world.any((q) => (p - q).distance < epsilon));
Piece? nextHint(Puzzle c, List<Piece> board) {
  // Match occupied geometry rather than piece IDs: identical blocks may be
  // taken from their shared pile in any order.
  final slots = List<Piece>.of(c.pieces);
  final used = <int>{};
  for (final p in board) {
    if (!used.add(p.id) || !c.pieces.any((q) => q.id == p.id)) return null;
    final index = slots.indexWhere((slot) => sameShape(p, slot));
    if (index < 0) return null;
    slots.removeAt(index);
  }
  final available = c.pieces.where((p) => !used.contains(p.id)).toList();
  double center(Piece p) =>
      p.y + p.points.fold<double>(0, (s, v) => s + v.dy) / p.points.length;
  slots.sort((a, b) => center(b).compareTo(center(a)));
  for (final slot in slots) {
    final candidates = available
        .where((p) => p.id == slot.id)
        .followedBy(available.where((p) => p.id != slot.id));
    for (final candidate in candidates) {
      var oriented = candidate;
      for (var turn = 0; turn < 4; turn++) {
        if (oriented.pileKey == slot.pileKey) {
          final drop = landing(board, oriented, slot.x, c.w, c.h);
          if (drop != null && sameShape(drop, slot)) return drop;
          break;
        }
        oriented = oriented.rotated();
      }
    }
  }
  return null;
}

List<Piece> solution(Puzzle c) {
  final board = <Piece>[];
  while (board.length < c.pieces.length) {
    final p = nextHint(c, board);
    if (p == null) throw StateError('Unsolvable ${c.key}');
    board.add(landing(board, p, p.x, c.w, c.h)!);
  }
  return board;
}

/// A tap names a visible destination, rather than the bounding-box center.
/// Only reachable landings under that point qualify; this does not consult
/// the level solution or rotate a piece on the player's behalf.
double tapColumn(
  List<Piece> board,
  Piece piece,
  Offset point,
  double w,
  double h,
) {
  final aimed = aimColumn(point.dx, piece.w, w);
  final candidates = <double>{aimed};
  for (double x = 0; x <= w - piece.w + epsilon; x += .5) {
    candidates.add(x);
  }
  final ordered = candidates.toList()
    ..sort((a, b) => (a - aimed).abs().compareTo((b - aimed).abs()));
  for (final x in ordered) {
    final p = landing(board, piece, x, w, h);
    if (p != null && pieceAt([p], point) != null) return x;
  }
  return aimed;
}

double aimColumn(
  double pointer,
  double width,
  double jarWidth, {
  double grab = .5,
}) => ((pointer - width * grab) * 2).roundToDouble().dividedByTwo.clamp(
  0,
  math.max(0, jarWidth - width),
);

extension on double {
  double get dividedByTwo => this / 2;
}
