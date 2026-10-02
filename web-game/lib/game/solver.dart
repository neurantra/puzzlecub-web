import 'axis.dart';
import 'grid.dart';

/// Solving techniques, ordered by difficulty. The hardest one a puzzle demands
/// is what sets its tier.
enum Technique {
  nakedSingle('Naked single', 1),
  hiddenSingle('Hidden single', 2),
  axisElimination('AxisTrack elimination', 3),
  axisLock('AxisTrack lock', 3),
  pointingPair('Pointing pair', 4),
  boxLineReduction('Box-line reduction', 4),
  nakedPair('Naked pair', 5),
  hiddenPair('Hidden pair', 6),
  xWing('X-Wing', 7),
  guess('Trial and error', 9);

  const Technique(this.label, this.rank);
  final String label;
  final int rank;

  /// Deductions about which track is the mystery axis, as opposed to
  /// deductions about an individual cell.
  bool get isAxisWork =>
      this == Technique.axisElimination || this == Technique.axisLock;
}

/// Outcome of a logical solve attempt.
class SolveReport {
  SolveReport({
    required this.solved,
    required this.used,
    required this.grid,
    required this.axis,
  });

  final bool solved;

  /// Every technique the solve needed at least once.
  final Set<Technique> used;

  final Grid grid;

  /// The axis the solve settled on, once it became determined.
  final AxisTrack? axis;

  /// Hardest technique of any kind.
  Technique get hardest => used.isEmpty
      ? Technique.nakedSingle
      : used.reduce((a, b) => a.rank >= b.rank ? a : b);

  /// Hardest *cell* technique, ignoring the axis deductions.
  ///
  /// AxisTrack work is Alphadoku's signature move, not an escalation of Sudoku
  /// difficulty, and it is already measured separately by how many axis
  /// candidates survive move zero. Rating the two on one scale made every
  /// puzzle at least as hard as the axis lock, which left the Easy tier
  /// ungeneratable.
  Technique get hardestCell {
    final cells = used.where((t) => !t.isAxisWork);
    return cells.isEmpty
        ? Technique.nakedSingle
        : cells.reduce((a, b) => a.rank >= b.rank ? a : b);
  }

  bool get usedAxisLogic => used.any((t) => t.isAxisWork);
}

/// Alphadoku's constraint solver.
///
/// Two jobs: rate a puzzle by solving it the way a person would, and count
/// solutions to prove a dig left the puzzle unique.
class Solver {
  Solver(this.givens);

  final Grid givens;

  // ---------------------------------------------------------------- counting

  /// Number of grids satisfying the givens, the Sudoku rules, *and* the axis
  /// rule (exactly one track spells the phrase). Stops counting at [limit].
  ///
  /// The axis rule is part of the puzzle, so uniqueness has to be measured with
  /// it. A grid may have many raw Sudoku completions yet exactly one legal
  /// Alphadoku solution - which is precisely what the harder tiers rely on.
  ///
  /// Each candidate axis is seeded in turn and the result completed. Refuting a
  /// false axis is the expensive half of the work, so every node propagates
  /// forced cells before branching; without that, disproving a sparse false
  /// axis degenerates into an exhaustive search.
  int countSolutions({int limit = 2}) {
    var found = 0;
    _nodes = 0;
    for (final axis in AxisTrack.all) {
      final seeded = Grid.copy(givens);
      if (!axis.isViable(seeded)) continue;
      axis.apply(seeded);
      if (!seeded.isConsistent) continue;
      found += _complete(seeded, axis, limit - found);
      if (found >= limit) return found;
      if (_nodes > _nodeBudget) return limit; // bail out as "not unique"
    }
    return found;
  }

  /// Search budget. Hitting it reports the puzzle as non-unique, which is the
  /// safe direction: the dig keeps the cell rather than shipping a board whose
  /// uniqueness was never proven.
  static const int _nodeBudget = 150000;
  int _nodes = 0;

  /// Completions of [grid] whose unique spelling axis is [axis].
  int _complete(Grid grid, AxisTrack axis, int remaining) {
    if (remaining <= 0) return 0;
    if (++_nodes > _nodeBudget) return 0;

    final work = Grid.copy(grid);
    if (!_propagate(work)) return 0;

    final cell = _mostConstrained(work);
    if (cell == null) {
      // Full grid. Count it only if [axis] is the one and only spelling track,
      // so each legal solution is counted exactly once across the outer loop.
      final spelling = spellingAxes(work);
      return (spelling.length == 1 && spelling.first == axis) ? 1 : 0;
    }

    final (r, c, options) = cell;
    var found = 0;
    for (final v in options) {
      work.set(r, c, v);
      found += _complete(work, axis, remaining - found);
      work.set(r, c, Grid.empty);
      if (found >= remaining) return found;
      if (_nodes > _nodeBudget) return found;
    }
    return found;
  }

  /// Fill every cell that has exactly one candidate, repeatedly.
  ///
  /// Returns false the moment a cell runs out of candidates, which is what
  /// makes refuting a false axis cheap instead of exponential.
  bool _propagate(Grid grid) {
    var changed = true;
    while (changed) {
      changed = false;
      for (var r = 0; r < Grid.size; r++) {
        for (var c = 0; c < Grid.size; c++) {
          if (!grid.isEmpty(r, c)) continue;
          final options = grid.candidates(r, c);
          if (options.isEmpty) return false;
          if (options.length == 1) {
            grid.set(r, c, options.first);
            changed = true;
          }
        }
      }
    }
    return true;
  }

  /// The empty cell with fewest candidates, for a cheap branching order.
  (int, int, List<int>)? _mostConstrained(Grid grid) {
    (int, int, List<int>)? best;
    for (var r = 0; r < Grid.size; r++) {
      for (var c = 0; c < Grid.size; c++) {
        if (!grid.isEmpty(r, c)) continue;
        final options = grid.candidates(r, c).toList();
        if (options.isEmpty) return (r, c, const []);
        if (best == null || options.length < best.$3.length) {
          best = (r, c, options);
          if (options.length == 2) return best;
        }
      }
    }
    return best;
  }

  // ----------------------------------------------------------------- solving

  /// Solve the way a person would, recording which techniques were required.
  ///
  /// The candidate map is kept across passes. Rebuilding it each pass threw
  /// away every elimination, so an elimination-only technique reported progress
  /// forever and the solve never terminated; the map is now rebuilt only when a
  /// value is actually placed.
  SolveReport solveLogically() {
    final grid = Grid.copy(givens);
    final used = <Technique>{};
    var axes = viableAxes(grid);
    AxisTrack? locked;
    var candidates = _candidateMap(grid, axes);

    while (!grid.isComplete) {
      final narrowed = viableAxes(grid);
      if (narrowed.length < axes.length) {
        used.add(Technique.axisElimination);
        axes = narrowed;
        candidates = _candidateMap(grid, axes);
      }
      if (axes.isEmpty) break; // contradiction: nothing spells the phrase
      if (locked == null && axes.length == 1) {
        locked = axes.first;
        locked.apply(grid);
        used.add(Technique.axisLock);
        candidates = _candidateMap(grid, axes);
        continue;
      }

      // Placements invalidate the map; eliminations refine it in place.
      if (_nakedSingle(grid, candidates, used) ||
          _hiddenSingle(grid, candidates, used)) {
        candidates = _candidateMap(grid, axes);
        continue;
      }
      if (_pointing(candidates, used) ||
          _nakedPair(candidates, used) ||
          _xWing(candidates, used)) {
        continue;
      }
      break; // no technique made progress
    }

    return SolveReport(
      solved: grid.isComplete && grid.isConsistent,
      used: used,
      grid: grid,
      axis: locked ?? (axes.length == 1 ? axes.first : null),
    );
  }

  /// Candidates per cell, already trimmed by the surviving axes: if every
  /// remaining axis agrees a cell must hold a given letter, it must.
  List<Set<int>> _candidateMap(Grid grid, List<AxisTrack> axes) {
    final map = List.generate(81, (i) {
      final r = i ~/ 9, c = i % 9;
      return grid.isEmpty(r, c) ? grid.candidates(r, c) : <int>{};
    });
    // A cell covered by every surviving axis at the same position is forced.
    for (var i = 0; i < 81; i++) {
      final r = i ~/ 9, c = i % 9;
      if (!grid.isEmpty(r, c)) continue;
      final forced = <int>{};
      var coveredByAll = true;
      for (final a in axes) {
        final step = a.kind == AxisKind.row
            ? (a.index == r ? c : null)
            : (a.index == c ? r : null);
        if (step == null) {
          coveredByAll = false;
          break;
        }
        forced.add(step);
      }
      if (coveredByAll && forced.length == 1) {
        map[i] = map[i].intersection(forced);
      }
    }
    return map;
  }

  bool _nakedSingle(Grid grid, List<Set<int>> cand, Set<Technique> used) {
    for (var i = 0; i < 81; i++) {
      if (cand[i].length == 1) {
        grid.set(i ~/ 9, i % 9, cand[i].first);
        used.add(Technique.nakedSingle);
        return true;
      }
    }
    return false;
  }

  bool _hiddenSingle(Grid grid, List<Set<int>> cand, Set<Technique> used) {
    for (final unit in _units) {
      for (var v = 0; v < 9; v++) {
        final spots = unit.where((i) => cand[i].contains(v)).toList();
        if (spots.length == 1) {
          grid.set(spots.first ~/ 9, spots.first % 9, v);
          used.add(Technique.hiddenSingle);
          return true;
        }
      }
    }
    return false;
  }

  /// Pointing pairs and box-line reductions: a value confined to one line
  /// inside a box clears that value from the rest of the line, and vice versa.
  bool _pointing(List<Set<int>> cand, Set<Technique> used) {
    var changed = false;
    for (var b = 0; b < 9; b++) {
      final cells = _boxCells(b);
      for (var v = 0; v < 9; v++) {
        final spots = cells.where((i) => cand[i].contains(v)).toList();
        if (spots.isEmpty) continue;
        final rows = spots.map((i) => i ~/ 9).toSet();
        final cols = spots.map((i) => i % 9).toSet();
        if (rows.length == 1) {
          for (final i in _rowCells(rows.first)) {
            if (Grid.boxOf(i ~/ 9, i % 9) != b && cand[i].remove(v)) {
              changed = true;
            }
          }
        }
        if (cols.length == 1) {
          for (final i in _colCells(cols.first)) {
            if (Grid.boxOf(i ~/ 9, i % 9) != b && cand[i].remove(v)) {
              changed = true;
            }
          }
        }
      }
    }
    if (changed) used.add(Technique.pointingPair);
    return changed;
  }

  bool _nakedPair(List<Set<int>> cand, Set<Technique> used) {
    var changed = false;
    for (final unit in _units) {
      final pairs = unit.where((i) => cand[i].length == 2).toList();
      for (var a = 0; a < pairs.length; a++) {
        for (var b = a + 1; b < pairs.length; b++) {
          if (!_setEquals(cand[pairs[a]], cand[pairs[b]])) continue;
          for (final i in unit) {
            if (i == pairs[a] || i == pairs[b]) continue;
            for (final v in cand[pairs[a]]) {
              if (cand[i].remove(v)) changed = true;
            }
          }
        }
      }
    }
    if (changed) used.add(Technique.nakedPair);
    return changed;
  }

  bool _xWing(List<Set<int>> cand, Set<Technique> used) {
    var changed = false;
    for (var v = 0; v < 9; v++) {
      // Row-based X-Wing.
      for (var r1 = 0; r1 < 9; r1++) {
        final a = _rowCells(r1).where((i) => cand[i].contains(v)).toList();
        if (a.length != 2) continue;
        for (var r2 = r1 + 1; r2 < 9; r2++) {
          final b = _rowCells(r2).where((i) => cand[i].contains(v)).toList();
          if (b.length != 2) continue;
          if (a[0] % 9 != b[0] % 9 || a[1] % 9 != b[1] % 9) continue;
          for (final col in [a[0] % 9, a[1] % 9]) {
            for (final i in _colCells(col)) {
              if (i ~/ 9 == r1 || i ~/ 9 == r2) continue;
              if (cand[i].remove(v)) changed = true;
            }
          }
        }
      }
    }
    if (changed) used.add(Technique.xWing);
    return changed;
  }

  // ------------------------------------------------------------------- units

  static final List<List<int>> _units = [
    for (var r = 0; r < 9; r++) _rowCells(r),
    for (var c = 0; c < 9; c++) _colCells(c),
    for (var b = 0; b < 9; b++) _boxCells(b),
  ];

  static List<int> _rowCells(int r) => [for (var c = 0; c < 9; c++) r * 9 + c];
  static List<int> _colCells(int c) => [for (var r = 0; r < 9; r++) r * 9 + c];
  static List<int> _boxCells(int b) {
    final r0 = (b ~/ 3) * 3, c0 = (b % 3) * 3;
    return [
      for (var r = r0; r < r0 + 3; r++)
        for (var c = c0; c < c0 + 3; c++) r * 9 + c,
    ];
  }

  static bool _setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}
