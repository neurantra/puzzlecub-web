import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrange_alphabets/game/puzzle_board.dart';
import 'package:arrange_alphabets/ui/toy_box.dart';

void main() {
  for (final (index, direction) in [
    (11, 'right'),
    (13, 'left'),
    (7, 'down'),
    (17, 'up'),
  ]) {
    for (final reduced in [false, true]) {
      testWidgets(
        'touch points $direction, moves once, reduced motion $reduced',
        (t) async {
          var board = PuzzleBoard.solved().move(23).move(18).move(13).move(12);
          final letter = board.tiles[index]!;
          var moves = 0;
          await t.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduced),
                child: StatefulBuilder(
                  builder: (context, setState) => Center(
                    child: SizedBox(
                      width: 300,
                      child: AlphabetBoard(
                        board: board,
                        onMove: (i) => setState(() {
                          board = board.move(i);
                          moves++;
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          final tile = find.byWidgetPredicate(
            (w) => w is ToyTile && w.letter == letter,
          );
          final gesture = await t.startGesture(t.getCenter(tile));
          await t.pump(const Duration(milliseconds: 110));
          final arrow = find.byKey(ValueKey('slide-$direction'));
          expect(arrow, findsOneWidget);
          final position = t.getCenter(arrow);
          await t.pump(const Duration(milliseconds: 100));
          if (reduced) {
            expect(t.getCenter(arrow), position);
          } else {
            final delta = t.getCenter(arrow) - position;
            switch (direction) {
              case 'right':
                expect(delta.dx, greaterThan(0));
              case 'left':
                expect(delta.dx, lessThan(0));
              case 'up':
                expect(delta.dy, lessThan(0));
              case 'down':
                expect(delta.dy, greaterThan(0));
            }
          }
          expect(moves, 0);
          await gesture.up();
          await t.pump();
          expect(moves, 1);
          expect(board.blankIndex, index);
          await t.pump(const Duration(milliseconds: 500));
          expect(arrow, findsNothing);
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('cancelled touch clears the arrow without making a move', (
    t,
  ) async {
    var moves = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            child: AlphabetBoard(
              board: PuzzleBoard.solved(),
              onMove: (_) => moves++,
            ),
          ),
        ),
      ),
    );
    final tile = find.byWidgetPredicate((w) => w is ToyTile && w.letter == 'X');
    final gesture = await t.startGesture(t.getCenter(tile));
    await t.pump(const Duration(milliseconds: 110));
    expect(find.byKey(const ValueKey('slide-right')), findsOneWidget);
    await gesture.cancel();
    await t.pump();
    expect(find.byKey(const ValueKey('slide-right')), findsNothing);
    expect(moves, 0);
  });
  testWidgets('fixed letters do not show movement cues', (t) async {
    var moves = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            child: AlphabetBoard(
              board: PuzzleBoard.solved(),
              onMove: (_) => moves++,
            ),
          ),
        ),
      ),
    );
    await t.tap(find.byWidgetPredicate((w) => w is ToyTile && w.letter == 'Y'));
    await t.pump();
    expect(moves, 0);
    for (final direction in ['up', 'down', 'left', 'right']) {
      expect(find.byKey(ValueKey('slide-$direction')), findsNothing);
    }
  });
}
