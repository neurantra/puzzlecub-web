import 'dart:math';

import '../data/corpus.dart';
import 'axis.dart';
import 'difficulty.dart';
import 'grid.dart';
import 'phrase.dart';
import 'puzzle.dart';
import 'solver.dart';

/// Builds puzzles with the seed-and-prune pipeline from the design spec:
/// pick a phrase, seed the mystery axis, fill a legal grid, then dig givens
/// while proving the puzzle stays uniquely solvable and no false axis appears.
///
/// The dig is decoy-aware. Clearing cells at random leaves exactly one axis
/// standing almost every time, because any given that disagrees with the
/// phrase crosses its track off instantly. To make the axis genuinely worth
/// hunting, the dig first clears the cells that refute a chosen set of decoy
/// tracks, so several axes survive a scan of the finished board.
class Generator {
  Generator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Generate one puzzle, retrying until the pipeline yields a valid board.
  Puzzle generate(Difficulty difficulty, {Phrase? phrase, int attempts = 60}) {
    for (var attempt = 0; attempt < attempts; attempt++) {
      final target = phrase ?? _pickPhrase();
      final axis = AxisTrack.all[_random.nextInt(AxisTrack.all.length)];

      final solution = _fillGrid(axis);
      if (solution == null) continue;

      // The seeded axis must be the only track that spells the phrase, or the
      // puzzle would have two right answers to its meta-question.
      final spelling = spellingAxes(solution);
      if (spelling.length != 1 || spelling.first != axis) continue;

      final givens = _dig(solution, axis, difficulty);
      if (givens == null) continue;

      final ambiguity = compatibleAxes(givens).length;
      if (ambiguity < difficulty.minAxes || ambiguity > difficulty.maxAxes) {
        continue;
      }

      final report = Solver(givens).solveLogically();
      if (!report.solved) continue;
      if (report.hardestCell.rank > difficulty.ceiling.rank) continue;
      if (difficulty.requiresAxisLogic && !report.usedAxisLogic) continue;

      return Puzzle(
        id: _id(target, difficulty),
        phrase: target,
        difficulty: difficulty,
        axis: axis,
        givens: givens,
        solution: solution,
        viableAxesAtStart: ambiguity,
      );
    }
    throw StateError(
      'Could not generate a ${difficulty.label} puzzle in $attempts attempts',
    );
  }

  Phrase _pickPhrase() => corpus[_random.nextInt(corpus.length)];

  String _id(Phrase phrase, Difficulty difficulty) =>
      'alpha_${difficulty.name}_${phrase.key.toLowerCase()}_'
      '${_random.nextInt(0x10000).toRadixString(16).padLeft(4, '0')}';

  /// Fill a complete legal grid with [axis] already spelling the phrase.
  Grid? _fillGrid(AxisTrack axis) {
    final grid = Grid();
    axis.apply(grid);
    if (!grid.isConsistent) return null;
    return _backtrack(grid) ? grid : null;
  }

  bool _backtrack(Grid grid) {
    var best = -1, bestCount = 10;
    List<int> bestOptions = const [];
    for (var i = 0; i < 81; i++) {
      final r = i ~/ 9, c = i % 9;
      if (!grid.isEmpty(r, c)) continue;
      final options = grid.candidates(r, c).toList();
      if (options.isEmpty) return false;
      if (options.length < bestCount) {
        best = i;
        bestCount = options.length;
        bestOptions = options;
        if (bestCount == 1) break;
      }
    }
    if (best == -1) return true; // complete

    bestOptions.shuffle(_random);
    final r = best ~/ 9, c = best % 9;
    for (final v in bestOptions) {
      grid.set(r, c, v);
      if (_backtrack(grid)) return true;
      grid.set(r, c, Grid.empty);
    }
    return false;
  }

  /// Clear cells while the puzzle stays uniquely solvable under the axis rule,
  /// down into the tier's givens band.
  Grid? _dig(Grid solution, AxisTrack axis, Difficulty difficulty) {
    final puzzle = Grid.copy(solution);
    final target =
        difficulty.minGivens +
        _random.nextInt(difficulty.maxGivens - difficulty.minGivens + 1);

    // Decoys are false tracks we want to survive the player's first scan.
    final decoys =
        (AxisTrack.all.where((a) => a != axis).toList()..shuffle(_random))
            .take(difficulty.decoys)
            .toList();

    // Cells that refute a decoy come out first; everything else follows.
    final priority = <int>[];
    for (final d in decoys) {
      for (var step = 0; step < Grid.size; step++) {
        final (r, c) = d.cell(step);
        if (solution.at(r, c) != step) priority.add(r * 9 + c);
      }
    }
    final rest = List.generate(81, (i) => i)..shuffle(_random);

    for (final i in [...priority, ...rest]) {
      if (puzzle.filledCount <= target) break;
      _tryClear(puzzle, i, difficulty.symmetric);
    }

    final count = puzzle.filledCount;
    if (count < difficulty.minGivens || count > difficulty.maxGivens) {
      return null;
    }
    return puzzle;
  }

  /// Clear a cell (and its rotational partner when the tier is symmetric),
  /// putting it back if the puzzle stops being uniquely solvable.
  void _tryClear(Grid puzzle, int index, bool symmetric) {
    final r = index ~/ 9, c = index % 9;
    final mirror = 80 - index;
    final mr = mirror ~/ 9, mc = mirror % 9;

    final saved = puzzle.at(r, c);
    final savedMirror = symmetric ? puzzle.at(mr, mc) : Grid.empty;
    if (saved == Grid.empty && (!symmetric || savedMirror == Grid.empty)) {
      return;
    }

    puzzle.set(r, c, Grid.empty);
    if (symmetric) puzzle.set(mr, mc, Grid.empty);

    if (Solver(puzzle).countSolutions(limit: 2) != 1) {
      puzzle.set(r, c, saved);
      if (symmetric) puzzle.set(mr, mc, savedMirror);
    }
  }
}
