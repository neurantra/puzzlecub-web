import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrange_alphabets/game/puzzle_board.dart';
import 'package:arrange_alphabets/game/solver.dart';
import 'package:arrange_alphabets/game/round.dart';

void main() {
  test('number target, interchangeable duplicates, and movable sixth row', () {
    final board = PuzzleBoard.solved(kind: PuzzleKind.numbers);
    expect(
      board.tiles
          .take(30)
          .map((t) => t == null ? '_' : board.displaySymbol(t))
          .join(' '),
      '1 2 3 4 5 2 3 4 5 6 3 4 5 6 7 4 5 6 7 8 5 6 7 8 9 6 7 8 9 _',
    );
    final swapped = board.tiles.toList();
    final temp = swapped[1];
    swapped[1] = swapped[5];
    swapped[5] = temp;
    final equivalent = PuzzleBoard(
      rows: 6,
      columns: 5,
      tiles: swapped,
      kind: PuzzleKind.numbers,
    );
    expect(equivalent.isSolved, isTrue);
    expect(equivalent.correctlyPlacedCount, 29);
    expect(equivalent.completedRows, 6);
    expect(PuzzleBoard(rows: 6, columns: 5, tiles: swapped).isSolved, isFalse);
    expect(board.blankIndex, 29);
    expect(board.canMove(28), isTrue);
    expect(board.canMove(24), isTrue);
    var moved = board;
    for (final index in [28, 27, 26, 25, 20]) {
      expect(moved.canMove(index), isTrue);
      moved = moved.move(index);
    }
    expect(moved.blankIndex, 20);
  });
  test(
    '100 number shuffles have legal AI solutions and preserve the pattern',
    () {
      for (var seed = 0; seed < 100; seed++) {
        var board = PuzzleBoard.solved(
          kind: PuzzleKind.numbers,
        ).shuffled(moves: 32, random: Random(seed));
        for (final move in AlphaSolver(board).solve()) {
          if (board.isSolved) break;
          expect(board.canMove(move), isTrue);
          board = board.move(move);
          expect(board.kind, PuzzleKind.numbers);
        }
        expect(board.isSolved, isTrue, reason: 'seed $seed');
      }
    },
  );
  test('sequential target is 1 to 29 with the last cell blank', () {
    final board = PuzzleBoard.solved(kind: PuzzleKind.sequential);
    expect(
      board.tiles.take(29).map((tile) => board.displaySymbol(tile!)).toList(),
      List.generate(29, (i) => '${i + 1}'),
    );
    expect(board.blankIndex, 29);
    expect(board.correctlyPlacedCount, 29);
    expect(board.completedRows, 6);
    final swapped = board.tiles.toList();
    final first = swapped[1];
    swapped[1] = swapped[5];
    swapped[5] = first;
    expect(
      PuzzleBoard(
        rows: 6,
        columns: 5,
        kind: PuzzleKind.sequential,
        tiles: swapped,
      ).isSolved,
      isFalse,
    );
  });
  test('100 sequential AI races finish legally', () {
    for (var seed = 0; seed < 100; seed++) {
      final round = AlphabetRound(
        const PlayOptions(kind: PuzzleKind.sequential, againstAI: true),
        random: Random(seed),
      );
      expect(round.board.tiles, round.friendBoard.tiles);
      for (final move in AlphaSolver(round.board).solve()) {
        expect(round.board.canMove(move), isTrue);
        round.slide(move);
      }
      expect(round.outcome, RoundOutcome.solved);
      expect(round.board.kind, PuzzleKind.sequential);
      round.dispose();
    }
  });
  test('number AI starts on identical board, pauses and completes', () {
    final round = AlphabetRound(
      const PlayOptions(kind: PuzzleKind.numbers, againstAI: true),
      random: Random(42),
    );
    expect(round.board.tiles, round.friendBoard.tiles);
    round.pause(true);
    round.tick();
    expect(round.friendMoves, 0);
    round.pause(false);
    for (var t = 0; t < 10000 && round.active; t++) {
      round.tick();
    }
    expect(round.outcome, RoundOutcome.friendFinished);
    expect(round.friendBoard.isSolved, isTrue);
    round.dispose();
  });
}
