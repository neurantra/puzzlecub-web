import 'dart:collection';

import 'puzzle_board.dart';

/// Layer-by-layer solver for the 5×5 alphabet sliding puzzle.
///
/// Strategy (well-known sliding-puzzle technique):
///
///   Layer 1 (5×5): solve top row + left column → 4×4 remaining
///   Layer 2 (4×4): solve top row + left column → 3×3 remaining
///   Layer 3 (3×3): solve top row + left column → 2×2 remaining
///   Final  (2×2): rotate to solve
///
/// Each row/column is solved by placing tiles one at a time. The last two
/// tiles of each row/column need the "corner macro" — placed via a
/// park-and-rotate sequence — because naive placement deadlocks when only
/// one cell remains.
///
/// The blank is routed between target positions via BFS over the unfrozen
/// cells, treating the tile currently being placed as a temporary blocker.
class AlphaSolver {
  AlphaSolver(this.initial);

  final PuzzleBoard initial;

  PuzzleBoard _board = PuzzleBoard.solved();
  final List<int> _moves = [];
  final Set<int> _frozen = {};

  /// Solve the puzzle. Returns the sequence of tap indices (each index is the
  /// position of the tile to tap — the engine's `move(idx)` then swaps it
  /// with the adjacent blank).
  List<int> solve() {
    _board = initial;
    _moves.clear();
    _frozen.clear();

    // Peel rectangular layers until the final 2×2 remains. This supports
    // both the 5×5 alphabet area and the full 6×5 number board.
    var top = 0, left = 0;
    final bottom = initial.playableRows - 1;
    final right = initial.columns - 1;
    while (bottom - top > 1 || right - left > 1) {
      if (bottom - top > 1) {
        _solveTopRow(rowIdx: top, colStart: left, colEnd: right);
        top++;
      }
      if (right - left > 1) {
        _solveLeftCol(colIdx: left, rowStart: top, rowEnd: bottom);
        left++;
      }
    }
    _solve2x2(rowStart: top, colStart: left);

    return List.unmodifiable(_moves);
  }

  // ─── Row & column solvers ─────────────────────────────────────────────

  void _solveTopRow({
    required int rowIdx,
    required int colStart,
    required int colEnd,
  }) {
    // Place all-but-last-two normally
    for (var c = colStart; c <= colEnd - 2; c++) {
      final sym = _symbolForGoal(rowIdx, c);
      _placeTile(sym, _idx(rowIdx, c));
      _frozen.add(_idx(rowIdx, c));
    }
    // Last two of the row: corner macro
    _placeRowCorner(rowIdx, colEnd);
    _frozen.add(_idx(rowIdx, colEnd - 1));
    _frozen.add(_idx(rowIdx, colEnd));
  }

  void _solveLeftCol({
    required int colIdx,
    required int rowStart,
    required int rowEnd,
  }) {
    for (var r = rowStart; r <= rowEnd - 2; r++) {
      final sym = _symbolForGoal(r, colIdx);
      _placeTile(sym, _idx(r, colIdx));
      _frozen.add(_idx(r, colIdx));
    }
    _placeColCorner(colIdx, rowEnd);
    _frozen.add(_idx(rowEnd - 1, colIdx));
    _frozen.add(_idx(rowEnd, colIdx));
  }

  // ─── Corner macros ────────────────────────────────────────────────────

  /// Place the last two tiles of a top row simultaneously via joint BFS over
  /// `(blank, pIdx, qIdx)` state pairs. The state space (~9000) is small
  /// enough to always find an optimal-ish path when one exists, which
  /// sidesteps the deadlock cases a sequential park-and-rotate hits.
  void _placeRowCorner(int r, int c) {
    final pSym = _symbolForGoal(r, c - 1);
    final qSym = _symbolForGoal(r, c);
    final pTarget = _idx(r, c - 1);
    final qTarget = _idx(r, c);
    _placeTwoTiles(pSym, pTarget, qSym, qTarget);
  }

  /// Mirror of the row-corner solver for the bottom two tiles of a left
  /// column.
  void _placeColCorner(int c, int rEnd) {
    final pSym = _symbolForGoal(rEnd - 1, c);
    final qSym = _symbolForGoal(rEnd, c);
    final pTarget = _idx(rEnd - 1, c);
    final qTarget = _idx(rEnd, c);
    _placeTwoTiles(pSym, pTarget, qSym, qTarget);
  }

  /// Move two named tiles to two target positions simultaneously via BFS
  /// over `(blankIdx, pIdx, qIdx)` states. Frozen cells are forbidden.
  /// Other movable letters are treated as fungible.
  void _placeTwoTiles(String pSym, int pTarget, String qSym, int qTarget) {
    final startP = _board.tiles.indexOf(pSym);
    final startQ = _board.tiles.indexOf(qSym);
    if (startP == pTarget && startQ == qTarget) return;
    final startB = _board.blankIndex;
    final start = (startB, startP, startQ);

    final visited = <(int, int, int)>{start};
    final parent = <(int, int, int), ((int, int, int), int)>{};
    final queue = Queue<(int, int, int)>()..add(start);

    (int, int, int)? goal;
    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      if (cur.$2 == pTarget && cur.$3 == qTarget) {
        goal = cur;
        break;
      }
      final (b, p, q) = cur;
      for (final n in _neighbors(b)) {
        if (_frozen.contains(n)) continue;
        var newP = p;
        var newQ = q;
        if (n == p) {
          newP = b;
        } else if (n == q) {
          newQ = b;
        }
        final next = (n, newP, newQ);
        if (visited.contains(next)) continue;
        visited.add(next);
        parent[next] = (cur, n);
        queue.add(next);
      }
    }

    if (goal == null) {
      throw StateError(
        'Solver: could not place ($pSym, $qSym) at ($pTarget, $qTarget) '
        '(frozen=$_frozen, blank=$startB, p=$startP, q=$startQ)',
      );
    }

    final taps = <int>[];
    var state = goal;
    while (state != start) {
      final p = parent[state]!;
      taps.add(p.$2);
      state = p.$1;
    }
    for (final tap in taps.reversed) {
      _applyMove(tap);
    }
  }

  // ─── Final 2×2 ────────────────────────────────────────────────────────

  /// Solve the last 2×2 block via joint BFS over `(blank, t1, t2, t3)`.
  /// State space here is tiny (≤24 reachable arrangements), so BFS is
  /// instant and provably finds a solution when parity allows one — which
  /// it always does after a `solved().shuffled(...)` start.
  void _solve2x2({required int rowStart, required int colStart}) {
    final tl = _idx(rowStart, colStart);
    final tr = _idx(rowStart, colStart + 1);
    final bl = _idx(rowStart + 1, colStart);

    final aSym = _symbolForGoal(rowStart, colStart);
    final bSym = _symbolForGoal(rowStart, colStart + 1);
    final cSym = _symbolForGoal(rowStart + 1, colStart);

    final startA = _board.tiles.indexOf(aSym);
    final startB = _board.tiles.indexOf(bSym);
    final startC = _board.tiles.indexOf(cSym);
    if (startA == tl && startB == tr && startC == bl) return;
    final startBlank = _board.blankIndex;
    final start = (startBlank, startA, startB, startC);

    final visited = <(int, int, int, int)>{start};
    final parent = <(int, int, int, int), ((int, int, int, int), int)>{};
    final queue = Queue<(int, int, int, int)>()..add(start);

    (int, int, int, int)? goal;
    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      if (cur.$2 == tl && cur.$3 == tr && cur.$4 == bl) {
        goal = cur;
        break;
      }
      final (blank, a, b, c) = cur;
      for (final n in _neighbors(blank)) {
        if (_frozen.contains(n)) continue;
        var na = a;
        var nb = b;
        var nc = c;
        if (n == a) {
          na = blank;
        } else if (n == b) {
          nb = blank;
        } else if (n == c) {
          nc = blank;
        }
        final next = (n, na, nb, nc);
        if (visited.contains(next)) continue;
        visited.add(next);
        parent[next] = (cur, n);
        queue.add(next);
      }
    }

    if (goal == null) {
      throw StateError('Solver: could not solve final 2×2');
    }

    final taps = <int>[];
    var state = goal;
    while (state != start) {
      final p = parent[state]!;
      taps.add(p.$2);
      state = p.$1;
    }
    for (final tap in taps.reversed) {
      _applyMove(tap);
    }
  }

  // ─── Tile placement ───────────────────────────────────────────────────

  /// Place `symbol` at `targetIdx` by BFS over `(blankIdx, tileIdx)` state
  /// pairs. The search treats every other movable letter as fungible — we
  /// only care about where the blank and the target tile end up. Frozen
  /// cells are forbidden transitions.
  ///
  /// This is robust against the "deadlock sliver" that a naive step-by-step
  /// shepherd hits: when the blank gets trapped between a frozen wall and
  /// the tile it's chasing, BFS finds a long-way-around path that a greedy
  /// approach would miss.
  ///
  /// Caller must `_frozen.add(targetIdx)` after this returns if the tile
  /// should not be disturbed by later placements.
  void _placeTile(String symbol, int targetIdx) {
    final startTile = _board.tiles.indexOf(symbol);
    if (startTile == targetIdx) return;
    final startBlank = _board.blankIndex;

    // State: (blankIdx, tileIdx). Transitions: blank moves to a neighbor
    // (which may or may not be the target tile). If it lands on the target
    // tile, the tile swaps to the previous blank position.
    final start = (startBlank, startTile);
    final visited = <(int, int)>{start};
    final parent = <(int, int), ((int, int), int)>{};

    final queue = Queue<(int, int)>()..add(start);
    (int, int)? goal;
    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      if (cur.$2 == targetIdx) {
        goal = cur;
        break;
      }
      final (b, t) = cur;
      for (final n in _neighbors(b)) {
        if (_frozen.contains(n)) continue;
        final newT = (n == t) ? b : t;
        final next = (n, newT);
        if (visited.contains(next)) continue;
        visited.add(next);
        parent[next] = (cur, n); // tap-index `n` is what produced `next`
        queue.add(next);
      }
    }

    if (goal == null) {
      throw StateError(
        'Solver: could not place $symbol at $targetIdx '
        '(frozen=$_frozen, blank=$startBlank, tile=$startTile)',
      );
    }

    // Reconstruct taps from goal back to start, then apply forward.
    final taps = <int>[];
    var state = goal;
    while (state != start) {
      final p = parent[state]!;
      taps.add(p.$2);
      state = p.$1;
    }
    for (final tap in taps.reversed) {
      _applyMove(tap);
    }
  }

  // ─── Geometry helpers ─────────────────────────────────────────────────

  static const int _cols = PuzzleBoard.activeColumns;

  int _idx(int r, int c) => r * _cols + c;

  List<int> _neighbors(int idx) {
    final r = idx ~/ _cols;
    final c = idx % _cols;
    final out = <int>[];
    if (r > 0) out.add(_idx(r - 1, c));
    if (r < initial.playableRows - 1) out.add(_idx(r + 1, c));
    if (c > 0) out.add(_idx(r, c - 1));
    if (c < _cols - 1) out.add(_idx(r, c + 1));
    return out;
  }

  /// What letter (A..X) belongs at goal cell (row, col)?
  String _symbolForGoal(int row, int col) {
    final idx = row * _cols + col;
    return String.fromCharCode('A'.codeUnitAt(0) + idx);
  }

  // ─── Move application ─────────────────────────────────────────────────

  void _applyMove(int tapIdx) {
    final next = _board.move(tapIdx);
    if (identical(next, _board)) {
      throw StateError('Illegal move attempted at $tapIdx');
    }
    _board = next;
    _moves.add(tapIdx);
  }
}
