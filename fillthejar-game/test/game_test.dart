import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/game/geometry.dart';
import 'package:fill_the_jar/game/session.dart';

void main() {
  final data =
      jsonDecode(File('assets/levels.json').readAsStringSync())
          as Map<String, dynamic>;
  final levels = (data['levels'] as List)
      .map((j) => Puzzle.fromJson(Map<String, dynamic>.from(j)))
      .toList();
  final previews = (data['previews'] as List)
      .map((j) => Puzzle.fromJson(Map<String, dynamic>.from(j)))
      .toList();
  final legacy = (data['legacyLevels'] as List)
      .map((j) => Puzzle.fromJson(Map<String, dynamic>.from(j)))
      .toList();
  final remixes = (data['replayCampaigns'] as List)
      .map(
        (tour) => (tour as List)
            .map((j) => Puzzle.fromJson(Map<String, dynamic>.from(j)))
            .toList(),
      )
      .toList();
  GameSession fresh() => GameSession(
    levels,
    previews,
    freePlayLimited: false,
    legacyLevels: legacy,
    replayCampaigns: remixes,
  );
  test(
    'all imported puzzles solve and dismantle using actual polygon edges',
    () {
      for (final c in [...levels, ...previews, ...remixes.expand((p) => p)]) {
        var board = solution(c);
        expect(solved(board, c), true, reason: c.key);
        while (board.isNotEmpty) {
          final p = board.firstWhere((p) => canLift(board, p));
          board = board.where((q) => q.id != p.id).toList();
        }
      }
    },
  );
  test('old in-progress layouts resume without losing wallet or unlocks', () {
    final old = legacy.firstWhere((p) => p.number == 4);
    final s = GameSession([old], previews)
      ..load(old)
      ..coins = 83
      ..unlocked = 18;
    s.board.add(solution(old).first);
    final snapshot = jsonDecode(s.encode()) as Map<String, dynamic>;
    snapshot.remove('puzzleRevision'); // Saves from before revision tracking.
    final restored = fresh()..restore(jsonEncode(snapshot));
    expect(restored.puzzle.revision, 1);
    expect(restored.board.length, 1);
    expect(restored.coins, 83);
    expect(restored.unlocked, 18);
    expect(restored.ghost, isNull);
    final again = fresh()..restore(restored.encode());
    expect(again.puzzle.revision, 1);
    restored.load(restored.levels[3]);
    expect(restored.puzzle.revision, 2);
    expect(restored.board, isEmpty);
  });
  test('an empty old level opens the new distinct layout', () {
    final old = legacy.firstWhere((p) => p.number == 4);
    final s = GameSession([old], previews)..coins = 83;
    final restored = fresh()..restore(s.encode());
    expect(restored.puzzle.revision, 2);
    expect(restored.coins, 83);
  });
  test(
    'fresh journey picks a different saved campaign and preserves rewards and settings',
    () {
      final s = fresh()
        ..unlocked = 100
        ..coins = 321
        ..sound = false
        ..dimensionUnlocked = true
        ..dimension = true;
      expect(s.startNewJourney(), isFalse);
      s.completed.addAll(levels.map((p) => p.key));
      s.load(s.levels.last);
      s.board = solution(s.puzzle);
      s.checkComplete();
      final coins = s.coins;
      expect(s.startNewJourney(random: math.Random(42)), isTrue);
      expect(s.campaign, isNot(0));
      expect(s.journey, 2);
      expect(s.puzzle.number, 1);
      expect(s.coins, coins);
      expect(s.unlocked, 100);
      expect(s.sound, isFalse);
      expect(s.dimension, isTrue);
      s.select(solution(s.puzzle).first);
      s.column = solution(s.puzzle).first.x;
      s.drop();
      final restored = fresh()..restore(s.encode());
      expect(restored.campaign, s.campaign);
      expect(restored.puzzle.revision, s.puzzle.revision);
      expect(restored.board.length, 1);
      final previous = s.campaign;
      s.load(s.levels.last);
      s.board = solution(s.puzzle);
      s.checkComplete();
      expect(s.startNewJourney(random: math.Random(4)), isTrue);
      expect(s.campaign, isNot(previous));
      s.board = solution(s.puzzle);
      s.checkComplete();
      expect(s.lastReward, Economy.replay);
    },
  );
  test('piles contain only equal size, cut and orientation', () {
    for (final c in levels) {
      for (final pile in piles(c, [])) {
        expect(pile.members.every((p) => p.pileKey == pile.key), true);
      }
    }
    expect(
      piles(
        previews.firstWhere((p) => p.preview == 'gems'),
        [],
      ).where((p) => p.members.first.name == 'Triangle').length,
      8,
    );
  });
  test(
    'completion rewards once, replay rewards separately, hint costs exactly once',
    () {
      final s = fresh();
      expect(s.coins, 60);
      expect(s.buyHint(), true);
      expect(s.coins, 50);
      s.drop();
      while (!s.complete) {
        final p = nextHint(s.puzzle, s.board)!;
        s.select(p);
        s.column = p.x;
        s.drop();
      }
      expect(s.coins, 75);
      s.checkComplete();
      s.drop();
      expect(s.coins, 75);
      expect(s.unlocked, 2);
      s.load(levels.first);
      for (final p in solution(s.puzzle)) {
        s.select(p);
        s.column = p.x;
        s.drop();
      }
      expect(s.coins, 80);
    },
  );
  test('insufficient balances never go negative or change board', () {
    final s = fresh()..coins = 9;
    expect(s.buyHint(), false);
    expect(s.beginSolve(), false);
    expect(s.unlockDimension(), false);
    expect(s.coins, 9);
    expect(s.board, isEmpty);
  });
  test('failed hint does not spend coins', () {
    final s = fresh();
    final p = s.puzzle.pieces.first;
    s.board = [p.at(100, 100)];
    expect(s.buyHint(), false);
    expect(s.coins, 60);
  });
  test('paid auto solve survives restart, charges once and completes once', () {
    final s = fresh();
    expect(s.beginSolve(), true);
    expect(s.beginSolve(), false);
    final moves = solution(s.puzzle);
    s.solveStep(moves.first);
    expect(s.coins, 10);
    final restored = fresh()..restore(s.encode());
    expect(restored.solving, true);
    expect(restored.coins, 10);
    for (final p in moves.skip(restored.board.length)) {
      restored.solveStep(p);
    }
    expect(restored.complete, true);
    expect(restored.coins, 35);
    restored.solveStep(moves.last);
    expect(restored.coins, 35);
  });
  test('paid hint, wallet, settings and 3D unlock persist', () {
    final s = fresh()..coins = 200;
    s.unlockDimension();
    expect(s.coins, 80);
    s.buyHint();
    s.toggleSound(false);
    final restored = fresh()..restore(s.encode());
    expect(restored.coins, 70);
    expect(restored.dimensionUnlocked, true);
    expect(restored.dimension, true);
    expect(restored.sound, false);
    expect(restored.selected?.id, s.selected?.id);
    expect(restored.column, s.column);
    restored.unlockDimension();
    expect(restored.coins, 70);
  });
  test('reward grants only specified benefit', () {
    final s = fresh();
    s.earnedAd();
    expect(s.coins, 90);
    s.earnedAd(forDimension: true);
    expect(s.coins, 90);
    expect(s.dimensionUnlocked, true);
  });
  test(
    'blocked removals do not change piles, clear removals restore counts',
    () {
      final s = fresh()..load(previews.first);
      final moves = solution(s.puzzle);
      for (final p in moves.take(2)) {
        s.select(p);
        s.column = p.x;
        s.drop();
      }
      expect(s.remove(s.board.first), false);
      expect(s.board.length, 2);
      expect(s.remove(s.board.last), true);
      expect(s.board.length, 1);
    },
  );
  test('invalid save geometry cannot inject a completed jar', () {
    final s = fresh();
    final j = jsonDecode(s.encode());
    j['board'] = [
      {
        'id': 999,
        'x': 0,
        'y': 0,
        'w': 4,
        'h': 4,
        'points': [
          [0, 0],
          [4, 0],
          [4, 4],
          [0, 4],
        ],
      },
    ];
    final restored = fresh()..restore(jsonEncode(j));
    expect(restored.board, isEmpty);
    expect(restored.complete, false);
  });
}
