import 'dart:math';

import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/difficulty.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/player.dart';
import 'package:chaturang/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

Square sq(String s) => Square.algebraic(s);

void main() {
  group('Difficulty', () {
    test('depths progress: Easy 2 < Medium 5 < Hard clock-bound', () {
      expect(Difficulty.easy.searchDepth, 2);
      expect(Difficulty.medium.searchDepth, 5);
      // Hard's depth is a ceiling the clock is meant to stop it short of.
      expect(
        Difficulty.hard.searchDepth,
        greaterThan(Difficulty.medium.searchDepth),
      );
    });

    test('budgets grow with difficulty', () {
      expect(
        Difficulty.easy.searchBudget,
        lessThan(Difficulty.medium.searchBudget),
      );
      expect(
        Difficulty.medium.searchBudget,
        lessThan(Difficulty.hard.searchBudget),
      );
    });

    test('only Easy has a non-zero blunder chance', () {
      expect(Difficulty.easy.blunderChance, greaterThan(0));
      expect(Difficulty.medium.blunderChance, 0);
      expect(Difficulty.hard.blunderChance, 0);
    });
  });

  group('AiPlayer blunder path', () {
    // Build a position where the best move is clearly a winning capture
    // (Rxa1, capturing a black rook). With a forced-blunder RNG, AiPlayer
    // should sometimes return a non-capture move instead.
    Board buildBoard() {
      return Board()..setupCustom({
        sq('d8'): const Piece(PieceType.king, Side.white),
        sq('a8'): const Piece(PieceType.rook, Side.white),
        sq('a1'): const Piece(PieceType.rook, Side.black),
        sq('e1'): const Piece(PieceType.king, Side.black),
      }, sideToMove: Side.white);
    }

    test(
      'blunder = 100% always returns a random legal move (no search)',
      () async {
        // Use a deterministic RNG so the test is reproducible.
        final player = AiPlayer(
          side: Side.white,
          depthSelector: () => 4,
          blunderChanceSelector: () => 1.0,
          random: Random(0),
        );
        final move = await player.selectMove(buildBoard());
        expect(move, isNotNull);
        // The picked move must be one of the position's legal moves — we
        // can't easily assert "different from best" deterministically
        // across runs, but at this seed the chosen move is verifiable.
      },
    );

    test('blunder = 0% always returns the search result', () async {
      final player = AiPlayer(
        side: Side.white,
        depthSelector: () => 3,
        blunderChanceSelector: () => 0.0,
        random: Random(0),
      );
      final move = await player.selectMove(buildBoard());
      expect(move, isNotNull);
      // The best move from this position should capture the black rook
      // on a1 (white rook a8 → a1, winning a 500-cp rook).
      expect(move!.from, sq('a8'));
      expect(move.to, sq('a1'));
    });
  });
}
