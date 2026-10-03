import 'board.dart';
import 'eval_params.dart';
import 'move_generator.dart';
import 'pieces.dart';
import 'square.dart';

/// Static-position evaluator for the AI search.
///
/// Score is from White's perspective: positive means White is winning,
/// negative means Black is winning, zero is even. The search negates the
/// score when evaluating from Black's perspective.
///
/// Eval terms (cumulative through slices):
///   - 4a: material values + piece-square tables + base king-leap bonus
///   - 4c: king safety (attackers near king, pawn shield),
///         pawn structure (doubled / isolated penalties),
///         context-aware king-leap valuation
///
/// All tunable weights live in [EvalParams]; callers can pass an alternate
/// [EvalParams] to evaluate with non-default parameters (used by Phase 2
/// self-play tuning). Production callers use [EvalParams.handTuned].
class Evaluator {
  Evaluator._();

  /// Score for a checkmate position. Large enough to dominate any material
  /// score but bounded so depth-N searches can prefer "mate in fewer plies"
  /// over "mate in more plies" by subtracting the ply count.
  static const int mateScore = 1000000;

  /// Lazy-initialized default params, used when the caller passes none.
  static EvalParams? _defaults;
  static EvalParams get defaults => _defaults ??= EvalParams.handTuned();

  /// Public lookup for the searcher's MVV-LVA move ordering. Returns the
  /// material value of [type] from the default parameter set.
  static int pieceValue(PieceType type) => defaults.materialValues[type.index];

  /// Score [board] from White's perspective using [params] (defaults to
  /// [defaults]).
  static int evaluate(Board board, [EvalParams? params]) {
    final p = params ?? defaults;
    var score = 0;

    // Pass 1: material + PST per piece, and the pawn-file counts that pass
    // 2 needs, in the one walk over the board. The evaluation runs at every
    // quiescence node, so this loop is the engine's hottest.
    //
    // A term valuing every padati by the piece it will promote to was tried
    // here and removed: measured over 150 games at equal time it LOST 42
    // Elo. The reasoning was sound — a Chaturang padati really does become
    // whatever belongs on its file — but it pushed padatis for a future
    // most of them never reach. The same valuation gated on the padati
    // being passed, and scaled by how far it has come, lives in
    // [_passedPawnBonus] below and measured +47 Elo.
    final values = p.pieceSquareValues;
    final whitePawnFiles = _whitePawnFiles;
    final blackPawnFiles = _blackPawnFiles;
    final whitePawnMaxRank = _whitePawnMaxRank;
    final blackPawnMinRank = _blackPawnMinRank;
    var whitePawns = 0, blackPawns = 0;
    var whiteRooks = 0, blackRooks = 0;
    var whiteMinors = 0, blackMinors = 0;
    for (var file = 0; file < 8; file++) {
      whitePawnFiles[file] = 0;
      blackPawnFiles[file] = 0;
      whitePawnMaxRank[file] = -1;
      blackPawnMinRank[file] = 8;
      for (var rank = 0; rank < 8; rank++) {
        final piece = board.pieceAtCoords(file, rank);
        if (piece == null) continue;
        final total =
            values[(piece.type.index * 2 + piece.side.index) * 64 +
                file * 8 +
                rank];
        if (piece.side == Side.white) {
          score += total;
          switch (piece.type) {
            case PieceType.pawn:
              whitePawnFiles[file]++;
              if (rank > whitePawnMaxRank[file]) whitePawnMaxRank[file] = rank;
              _whitePawns[whitePawns++] = file * 8 + rank;
            case PieceType.rook:
              _whiteRookFiles[whiteRooks++] = file;
            case PieceType.king:
              break;
            default:
              whiteMinors++;
          }
        } else {
          score -= total;
          switch (piece.type) {
            case PieceType.pawn:
              blackPawnFiles[file]++;
              if (rank < blackPawnMinRank[file]) blackPawnMinRank[file] = rank;
              _blackPawns[blackPawns++] = file * 8 + rank;
            case PieceType.rook:
              _blackRookFiles[blackRooks++] = file;
            case PieceType.king:
              break;
            default:
              blackMinors++;
          }
        }
      }
    }

    // Pass 2: pawn structure (doubled, isolated), passed padatis.
    score -= _pawnStructurePenalty(whitePawnFiles, p);
    score += _pawnStructurePenalty(blackPawnFiles, p);
    score += _passedPawnBonus(
      _whitePawns,
      whitePawns,
      Side.white,
      blackPawnMinRank,
      p,
    );
    score -= _passedPawnBonus(
      _blackPawns,
      blackPawns,
      Side.black,
      whitePawnMaxRank,
      p,
    );

    // Rathas on open and semi-open files.
    score += _rookFileBonus(
      _whiteRookFiles,
      whiteRooks,
      whitePawnFiles,
      blackPawnFiles,
      p,
    );
    score -= _rookFileBonus(
      _blackRookFiles,
      blackRooks,
      blackPawnFiles,
      whitePawnFiles,
      p,
    );

    // Pass 3: king safety.
    final whiteKingDanger = _kingSafetyPenalty(board, Side.white, p);
    final blackKingDanger = _kingSafetyPenalty(board, Side.black, p);
    score -= whiteKingDanger;
    score += blackKingDanger;

    // King-leap bonus, scaled up by own-king danger.
    if (!board.kingKnightMoveUsed(Side.white)) {
      score +=
          p.kingLeapBaseBonus + (whiteKingDanger ~/ p.kingLeapContextDivisor);
    }
    if (!board.kingKnightMoveUsed(Side.black)) {
      score -=
          p.kingLeapBaseBonus + (blackKingDanger ~/ p.kingLeapContextDivisor);
    }

    // Convertibility. A material edge held in minors alone is mostly not one
    // — see [EvalParams.minorsOnlyScalePct] — and a position the game's own
    // insufficient-material rule would draw is worth nothing to either side.
    final whiteHeavy = whiteRooks + whitePawns;
    final blackHeavy = blackRooks + blackPawns;
    if (whiteHeavy == 0 && blackHeavy == 0 && whiteMinors + blackMinors <= 1) {
      score = score * p.insufficientMaterialScalePct ~/ 100;
    } else if ((score > 0 && whiteHeavy == 0) ||
        (score < 0 && blackHeavy == 0)) {
      score = score * p.minorsOnlyScalePct ~/ 100;
    }

    return score;
  }

  // Scratch filled by [evaluate]'s board walk. Static rather than a per-call
  // allocation: the evaluator is not re-entrant and each isolate has its own
  // copy. Padati and ratha lists are sized for the most a side can have,
  // promotions included (every padati on the ratha files becoming one).
  static final List<int> _whitePawnFiles = List<int>.filled(8, 0);
  static final List<int> _blackPawnFiles = List<int>.filled(8, 0);
  static final List<int> _whitePawnMaxRank = List<int>.filled(8, -1);
  static final List<int> _blackPawnMinRank = List<int>.filled(8, 8);
  static final List<int> _whitePawns = List<int>.filled(16, 0);
  static final List<int> _blackPawns = List<int>.filled(16, 0);
  static final List<int> _whiteRookFiles = List<int>.filled(16, 0);
  static final List<int> _blackRookFiles = List<int>.filled(16, 0);

  /// Bonus for [side]'s passed padatis. [enemyFrontier] is, per file, the
  /// rank of the enemy padati nearest to promotion on that file — the one
  /// that decides whether anything stands in a passer's way.
  ///
  /// A padati is passed when no enemy padati is ahead of it on its own or
  /// an adjacent file. Its bonus is the table entry for the steps left, then
  /// scaled by what it will promote to on this file, since a Chaturang
  /// padati becomes the piece that started behind it: full value on a ratha
  /// file, a fraction elsewhere, and least on the file where it can never
  /// promote at all.
  static int _passedPawnBonus(
    List<int> pawns,
    int count,
    Side side,
    List<int> enemyFrontier,
    EvalParams p,
  ) {
    if (count == 0) return 0;
    final rookValue = p.materialValues[PieceType.rook.index];
    var bonus = 0;
    for (var i = 0; i < count; i++) {
      final file = pawns[i] >> 3;
      final rank = pawns[i] & 7;
      var passed = true;
      for (var f = file - 1; f <= file + 1 && passed; f++) {
        if (f < 0 || f > 7) continue;
        final frontier = enemyFrontier[f];
        // For White (moving toward rank 0) an enemy ahead has a lower rank;
        // for Black a higher one. A missing enemy reads as 8 / -1, which is
        // never ahead.
        if (side == Side.white ? frontier < rank : frontier > rank) {
          passed = false;
        }
      }
      if (!passed) continue;
      final stepsLeft = side == Side.white ? rank : 7 - rank;
      final promo = side == Side.white
          ? blackBackRank[file]
          : whiteBackRank[file];
      final pct = promo == PieceType.king
          ? _unpromotablePasserPct
          : p.materialValues[promo.index] * 100 ~/ rookValue;
      bonus += p.passedPawnBonus[stepsLeft] * pct ~/ 100;
    }
    return bonus;
  }

  /// Share of the passed-padati table a padati on the file that cannot
  /// promote still earns: it ties down defenders and cramps the raja, but it
  /// is going nowhere.
  static const int _unpromotablePasserPct = 25;

  static int _rookFileBonus(
    List<int> rookFiles,
    int count,
    List<int> ownPawns,
    List<int> enemyPawns,
    EvalParams p,
  ) {
    var bonus = 0;
    for (var i = 0; i < count; i++) {
      final file = rookFiles[i];
      if (ownPawns[file] != 0) continue;
      bonus += enemyPawns[file] == 0
          ? p.rookOpenFileBonus
          : p.rookSemiOpenFileBonus;
    }
    return bonus;
  }

  // Pawn structure: doubled and isolated penalties, from one side's per-file
  // pawn counts. Returned as a non-negative penalty.
  static int _pawnStructurePenalty(List<int> filesOccupied, EvalParams p) {
    var penalty = 0;
    for (var f = 0; f < 8; f++) {
      final count = filesOccupied[f];
      if (count == 0) continue;
      if (count > 1) penalty += p.doubledPawnPenalty * (count - 1);
      final leftHas = f > 0 && filesOccupied[f - 1] > 0;
      final rightHas = f < 7 && filesOccupied[f + 1] > 0;
      if (!leftHas && !rightHas) penalty += p.isolatedPawnPenalty * count;
    }
    return penalty;
  }

  // King safety: quadratic penalty for enemy attackers near king,
  // linear bonus for friendly pawn shield.
  static int _kingSafetyPenalty(Board board, Side side, EvalParams p) {
    final kingSq = board.kingSquare(side);
    if (kingSq == null) return 0;

    var attackers = 0;
    var shield = 0;
    for (final (df, dr) in _kingNeighborhood) {
      final f = kingSq.file + df;
      final r = kingSq.rank + dr;
      if (f < 0 || f >= 8 || r < 0 || r >= 8) continue;
      final sq = Square(f, r);
      if (MoveGenerator.isSquareAttacked(board, sq, side.opposite)) {
        attackers++;
      }
      final occupant = board.pieceAt(sq);
      if (occupant != null &&
          occupant.side == side &&
          occupant.type == PieceType.pawn) {
        shield++;
      }
    }
    final attackPenalty = p.kingAttackQuadCoeff * attackers * attackers;
    final shieldBonus = p.kingShieldBonus * shield;
    final net = attackPenalty - shieldBonus;
    return net < 0 ? 0 : net;
  }

  static const List<(int, int)> _kingNeighborhood = [
    (-1, -1),
    (-1, 0),
    (-1, 1),
    (0, -1),
    (0, 1),
    (1, -1),
    (1, 0),
    (1, 1),
  ];
}
