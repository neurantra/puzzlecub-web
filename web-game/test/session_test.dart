import 'package:alphadoku/game/axis.dart';
import 'package:alphadoku/game/difficulty.dart';
import 'package:alphadoku/game/generator.dart';
import 'package:alphadoku/game/grid.dart';
import 'package:alphadoku/game/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

void main() {
  late Session session;

  setUp(() {
    final puzzle = Generator(random: Random(3)).generate(Difficulty.medium);
    session = Session(puzzle);
  });

  (int, int) firstBlank(Session s) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (s.board.isEmpty(r, c)) return (r, c);
      }
    }
    throw StateError('no blank cell');
  }

  test('placing a letter fills the selected cell', () {
    final (r, c) = firstBlank(session);
    session.select(r, c);
    expect(session.place(4), isTrue);
    expect(session.board.at(r, c), 4);
  });

  test('givens cannot be overwritten', () {
    final puzzle = session.puzzle;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (!puzzle.givens.isEmpty(r, c)) {
          session.select(r, c);
          expect(session.place(0), isFalse);
          expect(session.board.at(r, c), puzzle.givens.at(r, c));
          return;
        }
      }
    }
  });

  test('undo restores the previous value', () {
    final (r, c) = firstBlank(session);
    session.select(r, c);
    session.place(2);
    session.place(5);
    session.undo();
    expect(session.board.at(r, c), 2);
    session.undo();
    expect(session.board.isEmpty(r, c), isTrue);
  });

  test('notes toggle on and off without filling the cell', () {
    final (r, c) = firstBlank(session);
    session.select(r, c);
    session.toggleNoteMode();
    session.place(7);
    expect(session.notes[r * 9 + c], {7});
    expect(session.board.isEmpty(r, c), isTrue);
    session.place(7);
    expect(session.notes[r * 9 + c], isEmpty);
  });

  test('placing a letter clears that cell\'s notes', () {
    final (r, c) = firstBlank(session);
    session.select(r, c);
    session.toggleNoteMode();
    session.place(1);
    session.toggleNoteMode();
    session.place(3);
    expect(session.notes.containsKey(r * 9 + c), isFalse);
    expect(session.board.at(r, c), 3);
  });

  test('a wrong placement counts as a mistake', () {
    final (r, c) = firstBlank(session);
    final right = session.puzzle.solution.at(r, c);
    session.select(r, c);
    session.place((right + 1) % 9);
    expect(session.mistakes, 1);
  });

  test('committing the wrong axis is rejected and crosses it off', () {
    final wrong = AxisTrack.all.firstWhere((a) => a != session.puzzle.axis);
    expect(session.commitAxis(wrong), isFalse);
    expect(session.ruledOut, contains(wrong));
    expect(session.lockedAxis, isNull);
    expect(session.mistakes, 1);
  });

  test('committing the right axis writes the phrase along it', () {
    expect(session.commitAxis(session.puzzle.axis), isTrue);
    expect(session.lockedAxis, session.puzzle.axis);
    for (var step = 0; step < Grid.size; step++) {
      final (r, c) = session.puzzle.axis.cell(step);
      expect(session.board.at(r, c), step);
    }
  });

  test('toggling a header adds and removes it from the shortlist', () {
    final axis = AxisTrack.all[2];
    final before = session.shortlist.length;
    session.toggleAxis(axis);
    expect(session.shortlist.length, before - 1);
    session.toggleAxis(axis);
    expect(session.shortlist.length, before);
  });

  test(
    'lock corrects a wrong axis letter and undo restores the whole move',
    () {
      final axis = session.puzzle.axis;
      final step = List.generate(9, (i) => i).firstWhere((i) {
        final (r, c) = axis.cell(i);
        return session.board.isEmpty(r, c);
      });
      final (r, c) = axis.cell(step);
      session.select(r, c);
      session.place((step + 1) % 9);
      final previous = session.board.cells.toList();
      final shortlist = session.shortlist.toList();
      session.commitAxis(axis);
      expect(session.board.at(r, c), step);
      session.undo();
      expect(session.board.cells, previous);
      expect(session.lockedAxis, isNull);
      expect(session.shortlist, shortlist);
      session.place(step);
      session.undo();
      expect(session.board.at(r, c), (step + 1) % 9);
    },
  );

  test('notes cannot be hidden underneath a placed letter', () {
    final (r, c) = firstBlank(session);
    session.select(r, c);
    session.place(2);
    session.toggleNoteMode();
    expect(session.place(3), isFalse);
    expect(session.notes, isEmpty);
  });

  test('a hint places the correct letter', () {
    final (r, c) = firstBlank(session);
    session.select(r, c);
    expect(session.hint(), isTrue);
    expect(session.board.at(r, c), session.puzzle.solution.at(r, c));
  });

  test('inventory counts down as letters are placed', () {
    final puzzle = session.puzzle;
    for (var v = 0; v < 9; v++) {
      var placed = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (puzzle.givens.at(r, c) == v) placed++;
        }
      }
      expect(session.remaining(v), 9 - placed);
    }
  });

  test('an easy puzzle starts with its axis revealed', () {
    final easy = Generator(random: Random(8)).generate(Difficulty.easy);
    final s = Session(easy);
    expect(s.lockedAxis, easy.axis);
    expect(s.shortlist, [easy.axis]);
  });
}
