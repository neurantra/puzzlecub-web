import 'axis.dart';
import 'difficulty.dart';
import 'grid.dart';
import 'phrase.dart';

/// A generated, playable puzzle.
class Puzzle {
  Puzzle({
    required this.id,
    required this.phrase,
    required this.difficulty,
    required this.axis,
    required this.givens,
    required this.solution,
    required this.viableAxesAtStart,
  });

  final String id;
  final Phrase phrase;
  final Difficulty difficulty;

  /// The one track that spells the phrase.
  final AxisTrack axis;

  /// Starting board. Cells are letter indices or [Grid.empty].
  final Grid givens;

  /// The unique completed grid.
  final Grid solution;

  /// AxisTrack candidates still standing at move zero - the tier's ambiguity lever.
  final int viableAxesAtStart;

  int get givensCount => givens.filledCount;

  /// Complete local save format, separate from the public sample exporter.
  Map<String, Object?> toSave() => {
    'id': id,
    'phrase': phrase.text,
    'phraseTier': phrase.tier.name,
    'difficulty': difficulty.name,
    'axis': AxisTrack.all.indexOf(axis),
    'givens': givens.cells,
    'solution': solution.cells,
    'viableAxes': viableAxesAtStart,
  };

  factory Puzzle.fromSave(Map<String, dynamic> data) {
    final phrase = Phrase(
      text: data['phrase'] as String,
      tier: PhraseTier.values.byName(data['phraseTier'] as String),
    );
    final givens = readSavedGrid(data['givens']);
    final solution = readSavedGrid(data['solution']);
    final axisIndex = data['axis'] as int;
    final viable = data['viableAxes'] as int;
    if (!phrase.isValid ||
        !RegExp(r'^[A-Z ]+$').hasMatch(phrase.text) ||
        axisIndex < 0 ||
        axisIndex >= 18 ||
        viable < 1 ||
        viable > 18 ||
        !solution.isComplete ||
        !solution.isConsistent ||
        !givens.isConsistent) {
      throw const FormatException('Invalid saved puzzle');
    }
    final axis = AxisTrack.all[axisIndex];
    if (spellingAxes(solution).length != 1 || !axis.spellsPhrase(solution)) {
      throw const FormatException('Invalid saved hidden line');
    }
    for (var i = 0; i < 81; i++) {
      if (givens.cells[i] != Grid.empty &&
          givens.cells[i] != solution.cells[i]) {
        throw const FormatException('Invalid saved starting letters');
      }
    }
    return Puzzle(
      id: data['id'] as String,
      phrase: phrase,
      difficulty: Difficulty.values.byName(data['difficulty'] as String),
      axis: axis,
      givens: givens,
      solution: solution,
      viableAxesAtStart: viable,
    );
  }

  /// Letter at a solved position, for display.
  String letterAt(int row, int col) {
    final v = solution.at(row, col);
    return v == Grid.empty ? '' : phrase.letters[v];
  }

  /// How many placements of [letter] the player still owes, given [board].
  int remainingOf(Grid board, int letterIndex) {
    var placed = 0;
    for (var r = 0; r < Grid.size; r++) {
      for (var c = 0; c < Grid.size; c++) {
        if (board.at(r, c) == letterIndex) placed++;
      }
    }
    return Grid.size - placed;
  }

  Map<String, Object?> toJson() => {
    'puzzle_id': id,
    'difficulty': difficulty.name,
    'target_phrase': phrase.key,
    'display_title': phrase.text,
    'alphabet': phrase.letters,
    'mystery_axis': {
      'kind': axis.kind.name,
      'index': axis.index + 1,
      'label': axis.label,
    },
    'givens_count': givensCount,
    'viable_axes_at_start': viableAxesAtStart,
    'initial_grid': [
      for (var r = 0; r < Grid.size; r++)
        [
          for (var c = 0; c < Grid.size; c++)
            givens.at(r, c) == Grid.empty
                ? null
                : phrase.letters[givens.at(r, c)],
        ],
    ],
  };
}

Grid readSavedGrid(dynamic value) {
  final cells = (value as List).cast<int>();
  if (cells.length != 81 || cells.any((v) => v < -1 || v > 8)) {
    throw const FormatException('Invalid saved grid');
  }
  return Grid.from(cells);
}
