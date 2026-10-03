import 'dart:typed_data';

import 'pieces.dart';

/// Tunable parameters for [Evaluator].
///
/// Bundled in one struct so Phase 2's Texel-style self-play tuner can read
/// and write them as a single optimization target. Production code uses
/// [EvalParams.handTuned] — the values that shipped through slice 4c.
/// The tuner produces a new instance via [copyWith] for each candidate
/// parameter perturbation.
///
/// Phase 3 (NNUE) will eventually replace these hand-crafted weights with
/// a small neural network. Until then, this struct is the single source
/// of truth for what the engine values.
class EvalParams {
  EvalParams({
    required this.materialValues,
    required this.psts,
    required this.kingLeapBaseBonus,
    required this.doubledPawnPenalty,
    required this.isolatedPawnPenalty,
    required this.kingAttackQuadCoeff,
    required this.kingShieldBonus,
    required this.kingLeapContextDivisor,
    this.passedPawnBonus = _defaultPassedPawnBonus,
    this.rookSemiOpenFileBonus = 15,
    this.rookOpenFileBonus = 30,
    this.minorsOnlyScalePct = 50,
    this.insufficientMaterialScalePct = 0,
  });

  /// Material value (centipawns) per piece type, indexed by
  /// [PieceType.index]. The king's value is 0 — its capture is implicit.
  final List<int> materialValues;

  /// Piece-square table per piece type: `psts[pieceType.index][rank][file]`.
  /// All tables are from White's perspective: row 0 is the enemy back
  /// rank, row 7 is White's home back rank. The lookup mirrors vertically
  /// for Black pieces (see [pieceSquareValues]).
  final List<List<List<int>>> psts;

  /// Base bonus for retaining the king's once-per-game knight leap. Scaled
  /// up by own-king-danger at lookup time so it grows when the king is
  /// being harassed.
  final int kingLeapBaseBonus;

  /// Penalty (centipawns) per extra pawn on a file beyond the first.
  final int doubledPawnPenalty;

  /// Penalty (centipawns) per pawn with no friendly pawn on adjacent files.
  final int isolatedPawnPenalty;

  /// King-safety attack coefficient. Penalty = coeff × attackers².
  final int kingAttackQuadCoeff;

  /// Per-friendly-pawn bonus inside the king's 8-square neighborhood.
  final int kingShieldBonus;

  /// Divisor applied to own-king-danger when scaling the leap bonus
  /// upward in [Evaluator]'s context-aware king-leap valuation.
  final int kingLeapContextDivisor;

  /// Bonus for a passed padati, indexed by the number of steps it still has
  /// to take to promote (1..6; index 0 unused). A padati starts six steps
  /// away, so the table runs from "one push from promotion" down to
  /// "has not moved yet".
  ///
  /// Scaled in [Evaluator] by what the padati will become on its file: a
  /// ratha-file passer is worth the whole table, a mantri-file one a
  /// fraction, and the one file that cannot promote at all less still. That
  /// gating is the lesson of the earlier unconditional promotion term, which
  /// valued every padati by its future and lost 42 Elo for it.
  ///
  /// Gated, it measured at 300ms/move over 400 games: +47 Elo [+22, +73],
  /// depth unchanged. Same idea, opposite sign — the difference is entirely
  /// in asking whether the padati is actually going to get there.
  final List<int> passedPawnBonus;

  /// Bonus for a ratha on a file with no friendly padati, and the larger
  /// one for a file with no padati at all. The ratha is the only piece that
  /// slides, so an open file is the one long-range asset on the board.
  ///
  /// Measured at 300ms/move over 400 games: +22 Elo [-4, +48]. Untuned
  /// hand values; a Texel pass over the new knobs is the next step.
  final int rookSemiOpenFileBonus;
  final int rookOpenFileBonus;

  /// Percentage the score is scaled to when the side ahead has neither a
  /// ratha nor a padati: minors alone can mate only with the defender's
  /// cooperation, so most of the material edge is not convertible.
  ///
  /// Measured at 300ms/move over 400 games: +6 Elo [-19, +31]. Rarely
  /// reached in a 200-ply game; the value is a guess for the tuner to fix.
  final int minorsOnlyScalePct;

  /// Percentage the score is scaled to when the game's insufficient-material
  /// rule would already have drawn the position. Zero mirrors the rule; the
  /// search otherwise happily chases a lone mantri's 142 centipawns into a
  /// draw it could have avoided, or avoids one it should have taken.
  ///
  /// Measured at 300ms/move over 400 games: +3 Elo [-21, +28] — the
  /// positions it covers are rare inside a 200-ply game. Kept because it is
  /// the rule, not a guess, and costs nothing.
  final int insufficientMaterialScalePct;

  static const List<int> _defaultPassedPawnBonus = [0, 140, 90, 55, 30, 15, 5];

  /// Material plus piece-square bonus for every (type, side, square), laid
  /// out flat as `[(type * 2 + side) * 64 + file * 8 + rank]`, with the
  /// vertical mirror for Black already applied.
  ///
  /// [materialValues] and [psts] are the tuner's view — nested, unmodifiable
  /// lists it can step one entry at a time. This is the evaluator's: one
  /// typed array, one index computation per piece, no interface dispatch.
  /// Built on first use, so a tuner producing thousands of candidate
  /// parameter sets pays for it only on those it actually evaluates with.
  late final Int32List pieceSquareValues = _flattenPieceSquareValues();

  Int32List _flattenPieceSquareValues() {
    final flat = Int32List(PieceType.values.length * 2 * 64);
    for (final type in PieceType.values) {
      final material = materialValues[type.index];
      final table = psts[type.index];
      for (final side in Side.values) {
        final base = (type.index * 2 + side.index) * 64;
        for (var file = 0; file < 8; file++) {
          for (var rank = 0; rank < 8; rank++) {
            final r = side == Side.white ? rank : 7 - rank;
            flat[base + file * 8 + rank] = material + table[r][file];
          }
        }
      }
    }
    return flat;
  }

  /// Tuned defaults from the Phase 2 self-play run.
  ///
  /// Source: 500 games at depth 4 → 95,779 positions, Texel-tuned over 8
  /// sweeps (loss 0.0421 → 0.0360). Validated by a 100-game match at
  /// depth 4 against the previous hand-tuned values: tuned won 12, lost
  /// 2, drew 86 — about +35 Elo.
  ///
  /// Notable shifts from the pre-tune hand values:
  ///   - Material values uniformly nudged down by ~8 (pawn 100→92, …).
  ///   - kingAttackQuadCoeff halved (15 → 7), shield bonus doubled
  ///     (8 → 16) — the engine learned the shield matters more than
  ///     just counting attackers.
  ///   - kingLeapContextDivisor dropped 4 → 1, meaning the leap bonus
  ///     now scales much more aggressively with king danger.
  ///   - King PST: home-rank d/e files turned negative, kings prefer
  ///     stepping off-center to the rooks' guard squares.
  static EvalParams handTuned() => EvalParams(
    materialValues: List.unmodifiable(const [
      0, // king (PieceType.king.index == 0)
      142, // counsellor
      192, // elephant
      292, // knight
      492, // rook
      92, // pawn
    ]),
    psts: _handTunedPsts,
    kingLeapBaseBonus: 192,
    doubledPawnPenalty: 20,
    isolatedPawnPenalty: 23,
    kingAttackQuadCoeff: 7,
    kingShieldBonus: 16,
    kingLeapContextDivisor: 1,
  );

  /// Returns a new [EvalParams] with the named fields replaced. Used by
  /// the Texel tuner to step one parameter at a time without rebuilding
  /// the whole struct.
  EvalParams copyWith({
    List<int>? materialValues,
    List<List<List<int>>>? psts,
    int? kingLeapBaseBonus,
    int? doubledPawnPenalty,
    int? isolatedPawnPenalty,
    int? kingAttackQuadCoeff,
    int? kingShieldBonus,
    int? kingLeapContextDivisor,
    List<int>? passedPawnBonus,
    int? rookSemiOpenFileBonus,
    int? rookOpenFileBonus,
    int? minorsOnlyScalePct,
    int? insufficientMaterialScalePct,
  }) {
    return EvalParams(
      materialValues: materialValues ?? this.materialValues,
      psts: psts ?? this.psts,
      kingLeapBaseBonus: kingLeapBaseBonus ?? this.kingLeapBaseBonus,
      doubledPawnPenalty: doubledPawnPenalty ?? this.doubledPawnPenalty,
      isolatedPawnPenalty: isolatedPawnPenalty ?? this.isolatedPawnPenalty,
      kingAttackQuadCoeff: kingAttackQuadCoeff ?? this.kingAttackQuadCoeff,
      kingShieldBonus: kingShieldBonus ?? this.kingShieldBonus,
      kingLeapContextDivisor:
          kingLeapContextDivisor ?? this.kingLeapContextDivisor,
      passedPawnBonus: passedPawnBonus ?? this.passedPawnBonus,
      rookSemiOpenFileBonus:
          rookSemiOpenFileBonus ?? this.rookSemiOpenFileBonus,
      rookOpenFileBonus: rookOpenFileBonus ?? this.rookOpenFileBonus,
      minorsOnlyScalePct: minorsOnlyScalePct ?? this.minorsOnlyScalePct,
      insufficientMaterialScalePct:
          insufficientMaterialScalePct ?? this.insufficientMaterialScalePct,
    );
  }

  /// A copy with one evaluation term switched off, for the match harness to
  /// play a build with the term against the same build without it. Throws
  /// [ArgumentError] on an unknown name.
  EvalParams withoutTerm(String name) {
    return switch (name) {
      'passedPawn' => copyWith(passedPawnBonus: List.filled(7, 0)),
      'rookFiles' => copyWith(rookSemiOpenFileBonus: 0, rookOpenFileBonus: 0),
      'minorsOnly' => copyWith(minorsOnlyScalePct: 100),
      'insufficientMaterial' => copyWith(insufficientMaterialScalePct: 100),
      _ => throw ArgumentError.value(name, 'name', 'unknown eval term'),
    };
  }
}

// Order must match PieceType.values: king, counsellor, elephant, knight,
// rook, pawn.
final List<List<List<int>>> _handTunedPsts = List.unmodifiable([
  _kingPst,
  _counsellorPst,
  _elephantPst,
  _knightPst,
  _rookPst,
  _pawnPst,
]);

// PSTs below are the Phase 2 Texel-tuned values from
// `tool/data/tuned.txt`. Original hand-set values are preserved in the
// pre-tune commit history.

const List<List<int>> _kingPst = [
  [-22, -32, -32, -58, -58, -48, -32, -22],
  [-22, -32, -48, -58, -42, -32, -48, -22],
  [-22, -32, -48, -46, -42, -32, -32, -22],
  [-22, -48, -32, -42, -58, -32, -32, -38],
  [-12, -22, -22, -32, -32, -22, -22, -12],
  [-2, -12, -12, -12, -12, -12, -12, -2],
  [28, 28, 8, 8, 8, 8, 28, 28],
  [28, 22, 16, -8, -8, 2, 22, 28],
];

const List<List<int>> _counsellorPst = [
  [-20, -10, -18, -18, -6, -2, -10, -28],
  [-10, -8, -8, -8, 5, -6, -8, -18],
  [-2, -8, -3, 5, 18, 13, -8, -2],
  [-2, -3, -3, 7, 7, 13, -3, -18],
  [-2, -8, 2, 7, 7, 8, -8, -15],
  [-2, 10, 2, 2, 2, 18, 2, -2],
  [-2, -3, 8, -8, -8, -8, 13, -2],
  [-28, -2, -18, -4, -18, -2, -18, -20],
];

const List<List<int>> _elephantPst = [
  [-20, -10, -18, -10, -10, -18, -10, -20],
  [-18, 0, 5, 2, 2, 5, 0, -18],
  [-18, 5, 10, 2, 2, 10, 5, -18],
  [-10, 2, 2, 15, 15, 2, 2, -10],
  [-10, 10, 2, 15, 15, 2, 2, -10],
  [-18, 5, 10, 2, 2, 10, 5, -5],
  [-10, 0, 5, 2, 18, 5, 0, -17],
  [-20, -18, -8, -10, -10, -2, -18, -20],
];

const List<List<int>> _knightPst = [
  [-38, -28, -18, -18, -16, -18, -28, -38],
  [-28, -18, -8, -3, -3, -8, -2, -12],
  [-18, -3, 2, 7, 7, 2, -3, -18],
  [-18, -3, 7, 12, 12, 7, -3, -18],
  [-18, -3, 7, 12, 12, 7, -3, -3],
  [-2, -3, 2, 20, 9, 2, -3, -16],
  [-28, -18, 8, -3, 13, -5, -18, -12],
  [-28, -12, -2, -2, -8, -14, -12, -38],
];

const List<List<int>> _rookPst = [
  [-8, -8, -3, 2, 2, -3, -8, -1],
  [-3, 2, 2, 2, 2, 2, 2, 13],
  [-13, 8, -8, -8, -8, -8, -8, -13],
  [-13, -8, -8, -8, -8, -8, 8, -13],
  [-13, -6, -8, 7, 8, -8, -8, 2],
  [-3, -8, 8, 8, 8, 8, -8, 3],
  [3, 8, 8, 8, -8, 8, 8, 3],
  [7, 7, 8, 13, 13, 8, 8, -8],
];

const List<List<int>> _pawnPst = [
  [0, 0, 0, 0, 0, 0, 0, 0], // rank 0 (promoted — unused)
  [52, 52, 42, 32, 32, 42, 52, 68],
  [17, 22, 12, 7, 7, 12, 25, 27],
  [15, 7, 2, 2, 2, 2, 12, 18],
  [13, -3, 2, 12, 12, 2, -3, -3],
  [-5, 0, -3, 7, 7, -3, -1, 3],
  [-8, -8, -8, -8, -8, -8, -8, -8],
  [0, 0, 0, 0, 0, 0, 0, 0], // rank 7 (home)
];
