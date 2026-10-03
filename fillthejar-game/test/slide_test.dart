import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/game/geometry.dart';
import 'package:fill_the_jar/game/session.dart';
import 'package:fill_the_jar/ui/game_screen.dart';
import 'package:fill_the_jar/ui/wooden_jar.dart';

Piece square(int id, double x, double y) => Piece(
  id: id,
  x: x,
  y: y,
  w: 1,
  h: 1,
  points: const [Offset.zero, Offset(1, 0), Offset(1, 1), Offset(0, 1)],
);
GameSession gameWith(List<Piece> board) =>
    GameSession([
        Puzzle(
          number: 1,
          title: 'Slide',
          w: 4,
          h: 4,
          pieces: [square(1, 0, 3), square(2, 1, 3), square(3, 2, 3)],
        ),
      ], [])
      ..board = board
      ..sound = false
      ..haptics = false
      ..motion = false;

void main() {
  test('slides both directions, clamps walls and cannot lift', () {
    final game = gameWith([square(1, 1, 3)]);
    expect(game.movePlacedPiece(1, const Offset(3, 0)), isTrue);
    expect(game.board.single.x, 3);
    expect(game.board.single.y, 3);
    game.movePlacedPiece(1, const Offset(-20, 3));
    expect(game.board.single.x, 0);
    expect(game.movePlacedPiece(1, const Offset(0, -5)), isFalse);
  });
  test('fast drags stop at a block rather than tunneling through it', () {
    final game = gameWith([square(1, 0, 3), square(2, 2, 3)]);
    game.movePlacedPiece(1, const Offset(3, 3));
    expect(game.board.first.x, 1);
    expect(overlaps(game.board[0], game.board[1]), isFalse);
  });
  test('covered pieces cannot move, even when a gap exists sideways', () {
    final game = gameWith([square(1, 0, 3), square(2, 0, 2)]);
    expect(game.movePlacedPiece(1, const Offset(2, 3)), isFalse);
    expect(game.board.first.x, 0);
  });
  test('sliding off support falls to the floor and persists', () {
    final game = gameWith([square(1, 0, 2), square(2, 0, 3)]);
    game.movePlacedPiece(1, const Offset(1, 2.5));
    expect(game.board.first.x, 1);
    expect(game.board.first.y, 3);
    final restored = gameWith([])..restore(game.encode());
    expect(restored.board.first.toJson(), game.board.first.toJson());
    expect(game.coins, Economy.starting);
    expect(game.board.length, 2);
  });
  test('downward moves stop on support, and movement locks are enforced', () {
    final game = gameWith([square(1, 0, 0), square(2, 0, 3)]);
    game.movePlacedPiece(1, const Offset(0, 3));
    expect(game.board.first.y, 2);
    game.walletBusy = true;
    expect(game.movePlacedPiece(1, const Offset(2, 2)), isFalse);
    game.walletBusy = false;
    game.rewardBusy = true;
    expect(game.movePlacedPiece(1, const Offset(2, 2)), isFalse);
    game.rewardBusy = false;
    game.solving = true;
    expect(game.movePlacedPiece(1, const Offset(2, 2)), isFalse);
    game.solving = false;
    game.complete = true;
    expect(game.movePlacedPiece(1, const Offset(2, 2)), isFalse);
  });
  test(
    'swept polygons allow diagonal contact without rectangular false positives',
    () {
      const triangle = Piece(
        id: 2,
        x: 1,
        y: 2,
        w: 2,
        h: 2,
        points: [Offset(2, 0), Offset(2, 2), Offset(0, 2)],
      );
      final moving = square(1, 0, 2);
      final moved = slidePiece(
        [moving, triangle],
        moving,
        const Offset(3, 2),
        4,
        4,
      );
      expect(moved.x, closeTo(1, epsilon));
      expect(moved.y, closeTo(2, epsilon));
      expect(overlaps(moved, triangle), isFalse);
    },
  );
  testWidgets('drag moves a placed block inside jar; tap still removes', (
    tester,
  ) async {
    final game = gameWith([square(1, 0, 3)]);
    await tester.pumpWidget(MaterialApp(home: GameScreen(session: game)));
    await tester.pumpAndSettle();
    final jar = find.byType(WoodenJar);
    final rect = WoodenJarPainter.bounds(tester.getSize(jar), game.puzzle);
    final unit = rect.width / game.puzzle.w;
    final start =
        tester.getTopLeft(jar) + rect.topLeft + Offset(.5, 3.5) * unit;
    await tester.dragFrom(start, Offset(unit * 2, 0));
    await tester.pumpAndSettle();
    expect(game.board.length, 1);
    expect(game.board.single.x, 2);
    expect(game.board.single.y, 3);
    expect(game.selected, isNull);
    await tester.tapAt(start + Offset(unit * 2, 0));
    await tester.pumpAndSettle();
    expect(game.board, isEmpty);
  });
}
