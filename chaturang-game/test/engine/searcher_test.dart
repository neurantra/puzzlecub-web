import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/eval_params.dart';
import 'package:chaturang/engine/evaluator.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/searcher.dart';
import 'package:chaturang/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

Square sq(String s) => Square.algebraic(s);

/// Default parameters minus the term that scores a position the game would
/// draw for insufficient material as zero — for tests whose bare-king
/// positions are about some other term entirely.
final bareKingsStillCount = EvalParams.handTuned().withoutTerm(
  'insufficientMaterial',
);

void main() {
  group('Evaluator', () {
    test('initial position evaluates near zero', () {
      // Pre-tune the eval was exactly 0 because the hand-set PSTs were
      // symmetric across the board midline. The Phase 2 tuner found
      // small per-cell asymmetries that better fit the self-play data,
      // so the opening evaluates to a small non-zero value now. What
      // matters is that there's no large built-in bias toward either
      // side — the value should still be small magnitude.
      final board = Board();
      final score = Evaluator.evaluate(board);
      expect(
        score,
        inInclusiveRange(-60, 60),
        reason: 'initial position should not have a >half-pawn intrinsic bias',
      );
    });

    test('rook advantage shows clear positive score for white', () {
      final board = Board()
        ..setupCustom({
          // White: king + rook
          sq('d8'): const Piece(PieceType.king, Side.white),
          sq('a8'): const Piece(PieceType.rook, Side.white),
          // Black: king only.
          sq('e1'): const Piece(PieceType.king, Side.black),
        });
      // Tuned material value for rook is 492 ± a few cp of PST + safety.
      expect(
        Evaluator.evaluate(board),
        inInclusiveRange(450, 540),
        reason: 'white up a rook should score near the rook material value',
      );
    });

    test('king-leap-used flag costs the bonus', () {
      final board = Board()
        ..setupCustom({
          sq('d8'): const Piece(PieceType.king, Side.white),
          sq('e1'): const Piece(PieceType.king, Side.black),
        }, whiteKingKnightUsed: true);
      // White used its leap → loses its retention bonus; black still
      // retains → contributes -kingLeapBaseBonus to white perspective.
      // Tuned base bonus is 192; in this empty position there's no king
      // danger so context scaling is zero.
      //
      // Bare kings are a draw by rule, which the evaluation now mirrors by
      // scaling everything to zero; that term is switched off here so the
      // leap bonus itself is what gets measured.
      expect(Evaluator.evaluate(board, bareKingsStillCount), -192);
    });

    test('king safety: position with attackers near king is worse', () {
      // Two boards with identical material; the only difference is whether
      // black has attackers swarming white's king.
      final safe = Board()
        ..setupCustom(
          {
            sq('d8'): const Piece(PieceType.king, Side.white),
            sq('a1'): const Piece(PieceType.king, Side.black),
          },
          whiteKingKnightUsed: true,
          blackKingKnightUsed: true,
        );
      final attacked = Board()
        ..setupCustom(
          {
            sq('d8'): const Piece(PieceType.king, Side.white),
            // Black rook on e-file threatens d-file via Re8+ tactics; the
            // rook attacks e7 and e8 squares adjacent to white king.
            sq('e7'): const Piece(PieceType.rook, Side.black),
            sq('a1'): const Piece(PieceType.king, Side.black),
          },
          whiteKingKnightUsed: true,
          blackKingKnightUsed: true,
        );
      // The "attacked" board should evaluate strictly worse for white
      // (more negative) than the "safe" board, even after accounting for
      // black's extra rook material.
      final safeScore = Evaluator.evaluate(safe);
      final attackedScore = Evaluator.evaluate(attacked);
      // Material delta alone is -500 (black has a rook). King-safety
      // penalty should push it strictly below that.
      expect(attackedScore, lessThan(safeScore - 500));
    });

    test('pawn structure: doubled pawns are penalized', () {
      // White has two pawns on d-file (doubled) vs two pawns on c+d.
      final stacked = Board()
        ..setupCustom(
          {
            sq('d8'): const Piece(PieceType.king, Side.white),
            sq('d4'): const Piece(PieceType.pawn, Side.white),
            sq('d5'): const Piece(PieceType.pawn, Side.white),
            sq('a1'): const Piece(PieceType.king, Side.black),
          },
          whiteKingKnightUsed: true,
          blackKingKnightUsed: true,
        );
      final spread = Board()
        ..setupCustom(
          {
            sq('d8'): const Piece(PieceType.king, Side.white),
            sq('c4'): const Piece(PieceType.pawn, Side.white),
            sq('d4'): const Piece(PieceType.pawn, Side.white),
            sq('a1'): const Piece(PieceType.king, Side.black),
          },
          whiteKingKnightUsed: true,
          blackKingKnightUsed: true,
        );
      expect(
        Evaluator.evaluate(spread),
        greaterThan(Evaluator.evaluate(stacked)),
      );
    });

    test('king-leap is worth more when own king is under attack', () {
      // Two positions, both with white retaining its knight leap. In one,
      // black's rook is harassing white's king; in the other, the king is
      // safe. The context-aware leap bonus should make the harassed
      // position lose *less* total value than the safe position would,
      // relative to a baseline where the leap was already spent.
      //
      // Strategy: compare (leap retained, king attacked) vs (leap spent,
      // king attacked). The retained-leap board should be better by MORE
      // than the +200 base bonus, because of the danger-scaled extra.
      final retained = Board()
        ..setupCustom(
          {
            sq('d8'): const Piece(PieceType.king, Side.white),
            sq('e7'): const Piece(PieceType.rook, Side.black),
            sq('a1'): const Piece(PieceType.king, Side.black),
          },
          blackKingKnightUsed: true,
          whiteKingKnightUsed: false,
        );
      final spent = Board()
        ..setupCustom(
          {
            sq('d8'): const Piece(PieceType.king, Side.white),
            sq('e7'): const Piece(PieceType.rook, Side.black),
            sq('a1'): const Piece(PieceType.king, Side.black),
          },
          blackKingKnightUsed: true,
          whiteKingKnightUsed: true,
        );
      final diff = Evaluator.evaluate(retained) - Evaluator.evaluate(spent);
      // Base bonus is 200; danger-scaled extra should push it above that.
      expect(diff, greaterThan(200));
    });

    test('piece-square tables reward central placement over the rim', () {
      // Same material both sides — only thing that varies is white knight
      // location. Central placement should evaluate higher.
      final centered = Board()
        ..setupCustom(
          {
            sq('d8'): const Piece(PieceType.king, Side.white),
            sq('d4'): const Piece(PieceType.knight, Side.white),
            sq('e1'): const Piece(PieceType.king, Side.black),
          },
          sideToMove: Side.white,
          whiteKingKnightUsed: true,
          blackKingKnightUsed: true,
        );
      final cornered = Board()
        ..setupCustom(
          {
            sq('d8'): const Piece(PieceType.king, Side.white),
            sq('a8'): const Piece(PieceType.knight, Side.white),
            sq('e1'): const Piece(PieceType.king, Side.black),
          },
          sideToMove: Side.white,
          whiteKingKnightUsed: true,
          blackKingKnightUsed: true,
        );
      // K+N vs K is a draw by rule; see the leap-bonus test above.
      expect(
        Evaluator.evaluate(centered, bareKingsStillCount),
        greaterThan(Evaluator.evaluate(cornered, bareKingsStillCount)),
      );
    });
  });

  group('Searcher', () {
    test('returns a legal move from initial position at depth 2', () {
      final board = Board();
      final result = Searcher().search(board, depth: 2);
      expect(result.move, isNotNull);
      expect(result.nodes, greaterThan(0));
    });

    test('returns null move at a stalemate', () {
      // Reuse the stalemate position from the game_state tests.
      final board = Board()
        ..setupCustom(
          {
            sq('a8'): const Piece(PieceType.king, Side.white),
            sq('a7'): const Piece(PieceType.pawn, Side.white),
            sq('a6'): const Piece(PieceType.pawn, Side.black),
            sq('c7'): const Piece(PieceType.king, Side.black),
            sq('b1'): const Piece(PieceType.rook, Side.black),
          },
          sideToMove: Side.white,
          whiteKingKnightUsed: true,
        );
      final result = Searcher().search(board, depth: 2);
      expect(result.move, isNull);
      expect(result.score, 0); // stalemate is a draw
    });

    test('finds mate-in-1 with a back-rank rook', () {
      // Black king cornered at h1; White rook at a8 swings to h8 for mate
      // along the h-file. White rook at g2 covers escape square g1. White
      // king at f3 protects g2 so black can't capture it. White is to move
      // at depth 2.
      final board = Board()
        ..setupCustom({
          sq('f3'): const Piece(PieceType.king, Side.white),
          sq('a8'): const Piece(PieceType.rook, Side.white),
          sq('g2'): const Piece(PieceType.rook, Side.white),
          sq('h1'): const Piece(PieceType.king, Side.black),
        }, sideToMove: Side.white);
      final result = Searcher().search(board, depth: 2);
      expect(result.move, isNotNull);
      expect(result.move!.from, sq('a8'));
      expect(result.move!.to, sq('h8'));
      // The score should reflect a mate find (very large positive value
      // from white's perspective).
      expect(result.score, greaterThan(Evaluator.mateScore ~/ 2));
    });

    test('quiescence: avoids losing material to a recapture at horizon', () {
      // White rook at e5; black pawn at e6 defended by black pawn at d5
      // (black pawns capture diagonally forward — i.e. rank-increasing for
      // black — so d5 attacks e6 and c6).
      //
      // At depth 1 with a naïve leaf eval, after Rxe6 white sees "I'm up a
      // pawn" and plays it. With quiescence search at the leaf, black's
      // recapture dxe6 is found and the line evaluates to -400 (white
      // trades a 500-value rook for a 100-value pawn). Quiescence should
      // make white reject Rxe6 and play something safer instead — most
      // likely Rxd5, which captures the defender for free.
      final board = Board()
        ..setupCustom({
          sq('d8'): const Piece(PieceType.king, Side.white),
          sq('e5'): const Piece(PieceType.rook, Side.white),
          sq('e6'): const Piece(PieceType.pawn, Side.black),
          sq('d5'): const Piece(PieceType.pawn, Side.black),
          sq('a1'): const Piece(PieceType.king, Side.black),
        }, sideToMove: Side.white);
      final result = Searcher().search(board, depth: 1);
      expect(result.move, isNotNull);
      // The rook should NOT march into e6 — quiescence sees the recapture.
      expect(result.move!.to, isNot(sq('e6')));
    });

    test('prefers higher-value capture (knight vs pawn)', () {
      // White rook at e5 can capture either a pawn or a knight in one move.
      // A higher-value capture should be preferred.
      final board = Board()
        ..setupCustom({
          sq('d8'): const Piece(PieceType.king, Side.white),
          sq('e5'): const Piece(PieceType.rook, Side.white),
          sq('e1'): const Piece(PieceType.knight, Side.black), // value 300
          sq('h5'): const Piece(PieceType.pawn, Side.black), // value 100
          sq('a1'): const Piece(PieceType.king, Side.black),
        }, sideToMove: Side.white);
      final result = Searcher().search(board, depth: 2);
      expect(result.move, isNotNull);
      expect(result.move!.from, sq('e5'));
      expect(result.move!.to, sq('e1')); // capture the knight, not the pawn
    });
  });
}
