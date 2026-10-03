import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/game/geometry.dart';
import 'package:fill_the_jar/ui/landing_arrows.dart';
import 'widget_test.dart' show session;

void main() {
  test('destinations follow rotation, blocked columns, and removal', () {
    final game = session();
    const block = Piece(
      id: 99,
      x: 0,
      y: 0,
      w: 1,
      h: 2,
      points: [Offset(0, 0), Offset(1, 0), Offset(1, 2), Offset(0, 2)],
    );
    game.select(block);
    expect(
      game.availableLandings.length,
      ((game.puzzle.w - 1) * 2).floor() + 1,
    );
    final initial = game.availableLandings.length;
    game.rotate();
    expect(game.availableLandings.length, lessThan(initial));
    game.board.add(
      Piece(
        id: 100,
        x: 0,
        y: 0,
        w: game.puzzle.w,
        h: game.puzzle.h,
        points: [
          const Offset(0, 0),
          Offset(game.puzzle.w, 0),
          Offset(game.puzzle.w, game.puzzle.h),
          Offset(0, game.puzzle.h),
        ],
      ),
    );
    expect(game.availableLandings, isEmpty);
    game.board.clear();
    expect(game.availableLandings, isNotEmpty);
  });

  testWidgets(
    'a paid hint shows only its destination; rotation restores choices',
    (tester) async {
      final game = session();
      game.load(game.levels[7]);
      expect(game.buyHint(), isTrue);
      final hint = game.hintedPlacement!;
      expect(game.availableLandings.length, greaterThan(1));
      Piece? chosen;
      Widget view() => MaterialApp(
        home: SizedBox(
          width: 300,
          height: 400,
          child: LandingArrows(
            landings: game.availableLandings,
            recommended: game.hintedPlacement,
            bounds: const Rect.fromLTWH(0, 0, 280, 350),
            jarWidth: game.puzzle.w,
            motion: false,
            onChoose: (p) => chosen = p,
          ),
        ),
      );
      await tester.pumpWidget(view());
      final arrows = find.byIcon(Icons.arrow_downward_rounded);
      expect(arrows, findsOneWidget);
      await tester.tap(arrows);
      expect(chosen!.id, hint.id);
      expect(chosen!.x, hint.x);
      expect(chosen!.y, hint.y);
      game.rotate();
      await tester.pumpWidget(view());
      expect(game.hintedPlacement, isNull);
      expect(arrows, findsNWidgets(game.availableLandings.length));
      expect(game.availableLandings.length, greaterThan(1));
    },
  );

  testWidgets('arrows animate and choose the exact destination', (
    tester,
  ) async {
    final game = session();
    game.load(game.levels[7]);
    game.select(game.puzzle.pieces.first);
    final targets = game.availableLandings;
    expect(targets.length, greaterThan(1));
    Piece? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 400,
          child: LandingArrows(
            landings: targets,
            bounds: const Rect.fromLTWH(0, 0, 280, 350),
            jarWidth: game.puzzle.w,
            motion: true,
            onChoose: (p) => chosen = p,
          ),
        ),
      ),
    );
    final arrows = find.byIcon(Icons.arrow_downward_rounded);
    expect(arrows, findsNWidgets(targets.length));
    final before = tester.getTopLeft(arrows.last);
    await tester.pump(const Duration(milliseconds: 225));
    expect(tester.getTopLeft(arrows.last), isNot(before));
    await tester.tap(arrows.last);
    expect(chosen, same(targets.last));
    await tester.pumpWidget(const SizedBox());
  });
}
