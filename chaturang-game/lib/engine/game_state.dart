import 'board.dart';
import 'move_generator.dart';
import 'square.dart';
import 'pieces.dart';

/// Result of evaluating a Chaturang position.
///
/// Modern semantics: the game ends on checkmate (side-to-move has no legal
/// moves and is in check), stalemate (no legal moves, not in check),
/// threefold repetition, or insufficient material.
///
/// The last two are not part of the original Chaturang rules, but without
/// them some games simply cannot end: bare kings have legal moves forever,
/// and two rooks shuffling reach the same position indefinitely. Both were
/// reachable in play — measured at 60 plies and 8 repeats respectively with
/// the result still Ongoing. The Move limit setting mitigated it, but that
/// defaults to Off.
///
/// The 50-move rule is deliberately still absent: it has no basis in
/// Chaturang, and the two rules here already close the games that could not
/// otherwise finish.
sealed class GameResult {
  const GameResult();

  /// Compute the result for [board] based on its side-to-move.
  factory GameResult.of(Board board) {
    final hasMove = MoveGenerator.legalMoves(board).isNotEmpty;
    final inCheck = MoveGenerator.isInCheck(board, board.sideToMove);
    if (!hasMove) {
      return inCheck
          ? Checkmate(winner: board.sideToMove.opposite)
          : const Stalemate();
    }
    // Checked after mate/stalemate: a position that ends the game outright
    // does so regardless of how often it has been seen.
    if (board.repetitionCount() >= 3) return const RepetitionDraw();
    if (hasInsufficientMaterial(board)) return const InsufficientMaterial();
    return Ongoing(inCheck: inCheck);
  }

  /// True when neither side could deliver mate even with the other's help.
  ///
  /// Deliberately conservative — only the cases that are unarguable:
  ///   * bare kings
  ///   * king and one minor against a bare king
  ///
  /// A minor here is the ashva, gaja or mantri, none of which can force
  /// mate: the ashva no more than a chess knight, the gaja reaches only
  /// eight squares from anywhere, and the mantri is a colour-bound
  /// one-square mover. A ratha or a padati (which promotes) is always
  /// enough material to keep playing.
  static bool hasInsufficientMaterial(Board board) {
    var whiteMinors = 0;
    var blackMinors = 0;
    for (var f = 0; f < 8; f++) {
      for (var r = 0; r < 8; r++) {
        final p = board.pieceAt(Square(f, r));
        if (p == null || p.type == PieceType.king) continue;
        if (p.type == PieceType.rook || p.type == PieceType.pawn) return false;
        if (p.side == Side.white) {
          whiteMinors++;
        } else {
          blackMinors++;
        }
      }
    }
    // K vs K, or a lone minor on one side only. Two minors can construct
    // mates in some positions, so they are left playable.
    return whiteMinors + blackMinors <= 1;
  }

  /// True for terminal positions (no further moves can be made).
  bool get isTerminal;
}

class Ongoing extends GameResult {
  const Ongoing({required this.inCheck});

  final bool inCheck;

  @override
  bool get isTerminal => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ongoing && other.inCheck == inCheck);

  @override
  int get hashCode => inCheck.hashCode;

  @override
  String toString() => inCheck ? 'Ongoing(in check)' : 'Ongoing';
}

class Checkmate extends GameResult {
  const Checkmate({required this.winner});

  final Side winner;

  @override
  bool get isTerminal => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Checkmate && other.winner == winner);

  @override
  int get hashCode => winner.hashCode;

  @override
  String toString() => 'Checkmate(winner: $winner)';
}

/// The same position has appeared three times. A draw.
class RepetitionDraw extends GameResult {
  const RepetitionDraw();

  @override
  bool get isTerminal => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RepetitionDraw;

  @override
  int get hashCode => 0x3EDEA7;

  @override
  String toString() => 'RepetitionDraw';
}

/// Neither side has the material to mate. A draw.
class InsufficientMaterial extends GameResult {
  const InsufficientMaterial();

  @override
  bool get isTerminal => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InsufficientMaterial;

  @override
  int get hashCode => 0x105FFF;

  @override
  String toString() => 'InsufficientMaterial';
}

class Stalemate extends GameResult {
  const Stalemate();

  @override
  bool get isTerminal => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Stalemate;

  @override
  int get hashCode => 0x57A1E;

  @override
  String toString() => 'Stalemate';
}

/// One side resigned / forfeited / quit / used Reset mid-game.
/// [winner] is the side that did NOT forfeit. Cannot be derived from
/// board position — must be set externally by player action.
class Forfeit extends GameResult {
  const Forfeit({required this.winner});

  final Side winner;

  @override
  bool get isTerminal => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Forfeit && other.winner == winner);

  @override
  int get hashCode => winner.hashCode ^ 0xF03F;

  @override
  String toString() => 'Forfeit(winner: $winner)';
}

/// Both sides agreed to a draw. Set externally by the Offer Draw flow.
class DrawByAgreement extends GameResult {
  const DrawByAgreement();

  @override
  bool get isTerminal => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DrawByAgreement;

  @override
  int get hashCode => 0xD7A_BA;

  @override
  String toString() => 'DrawByAgreement';
}

/// One side ran out of clock time. [winner] is the side that still has
/// time on the clock. Only set when timed mode is on and a side's
/// remaining time hits zero. Tracked separately from [Forfeit] so stats
/// can distinguish "lost on time" from "lost by resignation".
class Timeout extends GameResult {
  const Timeout({required this.winner});

  final Side winner;

  @override
  bool get isTerminal => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Timeout && other.winner == winner);

  @override
  int get hashCode => winner.hashCode ^ 0x710E;

  @override
  String toString() => 'Timeout(winner: $winner)';
}

/// Game ended because the move-count limit set in Settings was reached
/// without a checkmate. Counted as a draw. Distinct from
/// [DrawByAgreement] so stats can separate "agreed draw" from "ran out
/// of moves" if the differentiation becomes useful.
class MoveLimitDraw extends GameResult {
  const MoveLimitDraw();

  @override
  bool get isTerminal => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MoveLimitDraw;

  @override
  int get hashCode => 0x40DA1;

  @override
  String toString() => 'MoveLimitDraw';
}
