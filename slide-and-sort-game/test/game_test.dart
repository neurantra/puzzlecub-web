import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrange_alphabets/game/puzzle_board.dart';
import 'package:arrange_alphabets/game/solver.dart';
import 'package:arrange_alphabets/game/round.dart';
import 'package:arrange_alphabets/services/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    '100 shuffles have legal solutions, fixed Y/Z and no missing letters',
    () {
      for (var seed = 0; seed < 100; seed++) {
        var board = PuzzleBoard.solved().shuffled(
          moves: 32,
          random: Random(seed),
        );
        expect(
          board.tiles
              .whereType<String>()
              .where((s) => s.length == 1)
              .toSet()
              .length,
          26,
        );
        for (final move in AlphaSolver(board).solve()) {
          expect(board.canMove(move), isTrue);
          board = board.move(move);
          expect(board.tiles[25], 'Y');
          expect(board.tiles[26], 'Z');
        }
        expect(board.isSolved, isTrue);
      }
    },
  );
  test('invalid and fixed tiles never consume moves', () {
    final r = AlphabetRound(const PlayOptions(), random: Random(4));
    for (final i in [-1, 25, 26, 27, 30, r.board.blankIndex]) {
      expect(r.slide(i), isFalse);
    }
    expect(r.moves, 0);
    r.dispose();
  });
  test('winning on final allowed move beats move-limit failure', () {
    final r = AlphabetRound(
      const PlayOptions(limited: true),
      initial: PuzzleBoard.solved().move(23),
    );
    r.moves = 149;
    expect(r.slide(24), isTrue);
    expect(r.outcome, RoundOutcome.solved);
    r.dispose();
  });
  test('move cap ends round and blocks further taps', () {
    final r = AlphabetRound(
      const PlayOptions(limited: true),
      random: Random(1),
    );
    r.moves = 149;
    final next = List.generate(25, (i) => i).firstWhere(r.board.canMove);
    r.slide(next);
    expect(r.outcome, RoundOutcome.movesUp);
    expect(r.slide(r.board.blankIndex), isFalse);
    r.dispose();
  });
  test('timer and AI share lifecycle pause and expire fairly', () {
    final r = AlphabetRound(
      const PlayOptions(timed: true, againstAI: true),
      random: Random(2),
    );
    r.pause(true);
    for (var i = 0; i < 500; i++) {
      r.tick();
    }
    expect(r.seconds, 0);
    expect(r.friendMoves, 0);
    r.pause(false);
    r.seconds = 299;
    r.tick();
    expect(r.outcome, RoundOutcome.timeUp);
    expect(r.friendMoves, 0);
    r.dispose();
  });
  test('AI actually solves the identical initial board', () {
    final r = AlphabetRound(
      const PlayOptions(againstAI: true),
      random: Random(7),
    );
    expect(r.board.tiles, r.friendBoard.tiles);
    r.tick();
    expect(r.friendMoves, 1);
    r.tick();
    expect(r.friendMoves, 2);
    for (var i = 0; i < 3000 && r.active; i++) {
      r.tick();
    }
    expect(r.outcome, RoundOutcome.friendFinished);
    expect(r.friendBoard.isSolved, isTrue);
    r.dispose();
  });
  test('unlimited solo never ends merely from moves or time', () {
    final r = AlphabetRound(const PlayOptions(), random: Random(3));
    r.moves = 500;
    for (var i = 0; i < 601; i++) {
      r.tick();
    }
    expect(r.active, isTrue);
    r.dispose();
  });
  test('unknown, invalid and conservative 13/16 boundaries', () {
    final now = DateTime(2026, 9, 30);
    for (final year in [null, 1800, 2027]) {
      expect(protectedProfile(year, now, 'US'), isTrue);
    }
    expect(protectedProfile(2013, now, 'US'), isTrue);
    expect(protectedProfile(2013, DateTime(2026, 12, 31), 'US'), isFalse);
    expect(protectedProfile(2010, now, 'FR'), isTrue);
    expect(protectedProfile(2010, DateTime(2026, 12, 31), 'FR'), isFalse);
    expect(protectedProfile(2010, now, 'US'), isFalse);
  });
  test('age correction preserves progress and settings', () async {
    SharedPreferences.setMockInitialValues({'wins': 7, 'music': true});
    final p = Preferences(await SharedPreferences.getInstance());
    await p.saveYear(2020);
    expect(p.protected, isTrue);
    await p.saveYear(1980);
    expect(p.protected, isFalse);
    expect(p.wins, 7);
    expect(p.music, isTrue);
    p.dispose();
  });
}
