import 'dart:convert';
import 'dart:math';
import 'package:alphadoku/game/axis.dart';
import 'package:alphadoku/game/difficulty.dart';
import 'package:alphadoku/game/generator.dart';
import 'package:alphadoku/game/grid.dart';
import 'package:alphadoku/game/session.dart';
import 'package:alphadoku/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Session make(Difficulty tier) =>
    Session(Generator(random: Random(21)).generate(tier));
int blank(Session session) => List.generate(81, (i) => i).firstWhere(
  (i) =>
      session.board.cells[i] == Grid.empty && !session.isFixed(i ~/ 9, i % 9),
);
Map<String, dynamic> snapshot(Session s) =>
    jsonDecode(jsonEncode(s.toSave())) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final tier in [Difficulty.hard, Difficulty.pro]) {
    test('${tier.label} confirmation preserves every cell and note', () {
      final s = make(tier);
      final i = blank(s);
      s.select(i ~/ 9, i % 9);
      s.toggleNoteMode();
      s.place(2);
      final before = s.board.cells;
      expect(s.commitAxis(s.puzzle.axis), isTrue);
      expect(s.board.cells, before);
      expect(s.notes[i], {2});
      s.undo();
      expect(s.lockedAxis, isNull);
      expect(s.notes[i], {2});
    });
  }

  test('Hard retains hints; Pro rejects hints at model level', () {
    for (final tier in [Difficulty.hard, Difficulty.pro]) {
      final s = make(tier);
      final i = blank(s);
      s.select(i ~/ 9, i % 9);
      expect(s.hint(), tier == Difficulty.hard);
      expect(s.hintsUsed, tier == Difficulty.hard ? 1 : 0);
    }
  });

  test('Easy fills and protects its revealed line', () {
    final s = make(Difficulty.easy);
    expect(s.puzzle.axis.spellsPhrase(s.board), isTrue);
    final (r, c) = s.puzzle.axis.cell(0);
    s.select(r, c);
    expect(s.clear(), isFalse);
    expect(s.place(3), isFalse);
  });

  test(
    'Medium protects a revealed line and undo restores the pre-lock state',
    () {
      final s = make(Difficulty.medium);
      final before = s.board.cells;
      s.commitAxis(s.puzzle.axis);
      final (r, c) = s.puzzle.axis.cell(0);
      s.select(r, c);
      expect(s.clear(), isFalse);
      s.undo();
      expect(s.board.cells, before);
      expect(s.lockedAxis, isNull);
    },
  );

  test(
    'round trip restores notes, selections, counters, shortlist and undo',
    () {
      final s = make(Difficulty.hard);
      final i = blank(s);
      s.select(i ~/ 9, i % 9);
      s.toggleNoteMode();
      s.place(1);
      s.place(3);
      s.toggleNoteMode();
      s.place((s.puzzle.solution.cells[i] + 1) % 9);
      final wrong = AxisTrack.all.firstWhere((a) => a != s.puzzle.axis);
      s.toggleAxis(wrong);
      final restored = Session.fromSave(snapshot(s));
      expect(restored.board.cells, s.board.cells);
      expect(restored.selected, i);
      expect(restored.mistakes, 1);
      expect(restored.ruledOut, {wrong});
      restored.undo();
      expect(restored.board.cells[i], Grid.empty);
      expect(restored.notes[i], {1, 3});
      restored.undo();
      expect(restored.notes[i], {1});
      restored.undo();
      expect(restored.notes[i], isEmpty);
    },
  );

  test('line lock undo survives closing and restoring a game', () {
    final s = make(Difficulty.medium);
    final before = s.board.cells;
    s.commitAxis(s.puzzle.axis);
    final restored = Session.fromSave(snapshot(s));
    expect(restored.lockedAxis, s.puzzle.axis);
    restored.undo();
    expect(restored.board.cells, before);
    expect(restored.lockedAxis, isNull);
  });

  test('paused and restored clocks exclude time away', () {
    var now = DateTime(2026, 10, 1);
    final p = make(Difficulty.hard).puzzle;
    final s = Session(p, now: () => now);
    now = now.add(const Duration(seconds: 40));
    s.pause();
    now = now.add(const Duration(hours: 2));
    expect(s.elapsed.inSeconds, 40);
    final r = Session.fromSave(snapshot(s), now: () => now);
    now = now.add(const Duration(days: 1));
    expect(r.elapsed.inSeconds, 40);
    r.resume();
    now = now.add(const Duration(seconds: 5));
    expect(r.elapsed.inSeconds, 45);
  });

  test('finished boards cannot be mutated and their timer is frozen', () {
    var now = DateTime(2026, 10, 1);
    final s = Session(make(Difficulty.hard).puzzle, now: () => now);
    now = now.add(const Duration(minutes: 3));
    for (var i = 0; i < 81; i++) {
      if (s.board.cells[i] == Grid.empty) {
        s.select(i ~/ 9, i % 9);
        s.place(s.puzzle.solution.cells[i]);
      }
    }
    expect(s.isSolved, isTrue);
    final board = s.board.cells;
    now = now.add(const Duration(hours: 2));
    s.undo();
    expect(s.clear(), isFalse);
    expect(s.hint(), isFalse);
    expect(s.board.cells, board);
    expect(s.elapsed.inMinutes, 3);
  });

  test(
    'queued saves use their call-time snapshot and newest write wins',
    () async {
      final store = SessionStore();
      final s = make(Difficulty.hard);
      final i = blank(s);
      final first = store.save(s);
      s.select(i ~/ 9, i % 9);
      s.place(2);
      final second = store.save(s);
      await Future.wait([first, second]);
      final restored = await SessionStore().load();
      expect(restored!.board.cells[i], 2);
      restored.undo();
      expect(restored.board.cells[i], Grid.empty);
    },
  );

  test(
    'clear is ordered after pending writes and onboarding is independent',
    () async {
      final store = SessionStore();
      final s = make(Difficulty.medium);
      final writing = store.save(s);
      final clearing = store.clear();
      await Future.wait([writing, clearing]);
      expect(await store.load(), isNull);
      await store.save(s);
      await store.completeTutorial();
      expect(await store.tutorialCompleted(), isTrue);
      expect((await store.load())!.puzzle.id, s.puzzle.id);
    },
  );

  test(
    'unsupported and malformed saves are rejected without destroying bytes',
    () async {
      final prefs = await SharedPreferences.getInstance();
      for (final bytes in ['not JSON', '{"version":99}', '{"version":1}']) {
        await prefs.setString(SessionStore.saveKey, bytes);
        await expectLater(SessionStore().load(), throwsFormatException);
        expect(prefs.getString(SessionStore.saveKey), bytes);
      }
      final data = snapshot(make(Difficulty.hard));
      data['board'] = [9];
      expect(() => Session.fromSave(data), throwsFormatException);
    },
  );
}
