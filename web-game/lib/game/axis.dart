import 'grid.dart';

/// Which way a candidate axis runs.
enum AxisKind {
  row('Row', 'R'),
  column('Column', 'C');

  const AxisKind(this.label, this.short);
  final String label, short;
}

/// One of the eighteen tracks that could be the mystery axis.
///
/// Alphadoku's rule: in the solved grid exactly one of these eighteen tracks
/// reads the target phrase in natural order - left-to-right for a row,
/// top-to-bottom for a column.
///
/// The original specification asked for one row *and* one column to both spell
/// the phrase. That is impossible: the intersection argument forces the two to
/// share an index, and a track plus its transpose then place the same letter
/// twice inside the diagonal 3x3 box. See `docs/AXIS_RULE.md` for the proof.
class AxisTrack {
  const AxisTrack(this.kind, this.index);

  final AxisKind kind;

  /// 0-8.
  final int index;

  /// Every candidate axis, rows first: R1-R9 then C1-C9.
  static List<AxisTrack> get all => [
    for (final k in AxisKind.values)
      for (var i = 0; i < Grid.size; i++) AxisTrack(k, i),
  ];

  /// Human label such as `R4` or `C7`.
  String get label => '${kind.short}${index + 1}';

  /// The (row, col) of position [step] along this axis.
  (int, int) cell(int step) =>
      kind == AxisKind.row ? (index, step) : (step, index);

  /// The track's current contents, blanks included.
  List<int> read(Grid grid) =>
      kind == AxisKind.row ? grid.row(index) : grid.column(index);

  /// Whether this track spells the phrase in full. Position `i` must hold
  /// letter index `i`.
  bool spellsPhrase(Grid grid) {
    final values = read(grid);
    for (var i = 0; i < Grid.size; i++) {
      if (values[i] != i) return false;
    }
    return true;
  }

  /// Whether a *scan* of the board rules this track out: does any letter
  /// already on the track disagree with what the phrase needs there?
  ///
  /// This is the player-facing test, and the one the difficulty tiers count.
  /// It deliberately stops at what the eye can check, which is why it is kept
  /// apart from [isViable] below.
  bool isCompatible(Grid grid) {
    for (var i = 0; i < Grid.size; i++) {
      final (r, c) = cell(i);
      final v = grid.at(r, c);
      if (v != Grid.empty && v != i) return false;
    }
    return true;
  }

  /// Whether this track could still be completed into the phrase once the
  /// classical constraints are propagated.
  ///
  /// Strictly stronger than [isCompatible]: placing the true axis blocks every
  /// other track by row/column/box conflict, so this returns true for exactly
  /// one axis on any grid that already shows the real one. That makes it the
  /// right test for the solver and the wrong one for measuring ambiguity.
  bool isViable(Grid grid) {
    for (var i = 0; i < Grid.size; i++) {
      final (r, c) = cell(i);
      final v = grid.at(r, c);
      if (v != Grid.empty && v != i) return false;
      if (v == Grid.empty && !grid.allows(r, c, i)) return false;
    }
    return true;
  }

  /// Write the phrase along this track.
  void apply(Grid grid) {
    for (var i = 0; i < Grid.size; i++) {
      final (r, c) = cell(i);
      grid.set(r, c, i);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AxisTrack && other.kind == kind && other.index == index;

  @override
  int get hashCode => Object.hash(kind, index);

  @override
  String toString() => label;
}

/// Axes a player cannot cross off by scanning. The count at move zero is the
/// "axis ambiguity" difficulty lever, and drives the header slash UI.
List<AxisTrack> compatibleAxes(Grid grid) =>
    AxisTrack.all.where((a) => a.isCompatible(grid)).toList();

/// Axes that survive full constraint propagation. Used by the solver.
List<AxisTrack> viableAxes(Grid grid) =>
    AxisTrack.all.where((a) => a.isViable(grid)).toList();

/// Axes that actually spell the phrase in a completed grid. A well-formed
/// puzzle has exactly one.
List<AxisTrack> spellingAxes(Grid grid) =>
    AxisTrack.all.where((a) => a.spellsPhrase(grid)).toList();
