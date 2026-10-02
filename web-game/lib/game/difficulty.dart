import 'solver.dart';

/// The four tiers, tuned on two independent levers: how many cells are given,
/// and how ambiguous the mystery axis is at move zero.
///
/// Two departures from the design spec, both measured rather than assumed:
///
/// 1. The spec's ambiguity bands (up to "7-9 candidates") assumed nine diagonal
///    candidates. The shipped rule has eighteen tracks, and placing the real
///    axis constrains the rest of the board, so the achievable spread is
///    narrower than the spec hoped. The bands below are what the generator can
///    actually hit - see `tool/ambiguity_study2.dart`.
/// 2. AxisTrack difficulty and cell difficulty are rated separately. [ceiling]
///    bounds only the classical Sudoku work; axis work is measured by the
///    candidate bands, because it is the signature mechanic rather than an
///    escalation.
enum Difficulty {
  easy(
    label: 'Easy',
    blurb: 'The axis is shown. Fill in the rest.',
    minGivens: 36,
    maxGivens: 40,
    minAxes: 1,
    maxAxes: 18,
    revealAxis: true,
    symmetric: true,
    decoys: 0,
    ceiling: Technique.hiddenSingle,
  ),
  medium(
    label: 'Medium',
    blurb: 'A quick scan pins the axis down.',
    minGivens: 30,
    maxGivens: 34,
    minAxes: 2,
    maxAxes: 4,
    revealAxis: false,
    symmetric: true,
    decoys: 3,
    ceiling: Technique.hiddenSingle,
  ),
  hard(
    label: 'Hard',
    blurb: 'Expert Deduction. Confirm the line; fill it yourself.',
    minGivens: 25,
    maxGivens: 28,
    minAxes: 3,
    maxAxes: 6,
    revealAxis: false,
    symmetric: false,
    decoys: 5,
    ceiling: Technique.boxLineReduction,
  ),
  pro(
    label: 'Pro',
    blurb: 'Unassisted. No automatic fills or revealing hints.',
    minGivens: 20,
    maxGivens: 24,
    minAxes: 4,
    maxAxes: 9,
    revealAxis: false,
    symmetric: false,
    decoys: 6,
    ceiling: Technique.xWing,
  );

  const Difficulty({
    required this.label,
    required this.blurb,
    required this.minGivens,
    required this.maxGivens,
    required this.minAxes,
    required this.maxAxes,
    required this.revealAxis,
    required this.symmetric,
    required this.decoys,
    required this.ceiling,
  });

  final String label, blurb;
  final int minGivens, maxGivens;

  /// Band of axis candidates a player cannot scan away at move zero.
  final int minAxes, maxAxes;

  /// Easy hands the axis over outright, as a tutorial.
  final bool revealAxis;

  /// 180-degree rotational symmetry in the givens. Dropped on the harder tiers
  /// because it constrains which cells can be cleared, and clearing specific
  /// cells is what creates axis ambiguity.
  final bool symmetric;

  /// How many false axes the dig actively protects.
  final int decoys;

  /// Hardest *classical* technique this tier may require.
  final Technique ceiling;

  /// Tiers where the axis deduction must carry real weight.
  bool get requiresAxisLogic => this == hard || this == pro;

  bool get autoFillAxis => this == easy || this == medium;
  bool get allowsHints => this != pro;
  String get challengeLabel => switch (this) {
    easy => 'Guided start',
    medium => 'Hidden-line hunt',
    hard => 'Expert Deduction',
    pro => 'Unassisted challenge',
  };
}
