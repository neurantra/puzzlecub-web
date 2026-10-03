import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/main.dart';
import 'package:fill_the_jar/game/geometry.dart';
import 'package:fill_the_jar/services/audience.dart';
import 'package:fill_the_jar/ui/scene_backdrop.dart';
import 'package:fill_the_jar/ui/jar_presentation.dart';
import 'widget_test.dart' show session;

void main() {
  testWidgets(
    'wooden worlds follow level ranges; picture themes keep quiet background',
    (tester) async {
      final game = session();
      await tester.pumpWidget(JarApp(session: game, audience: Audience(2020)));
      for (var world = 0; world < 4; world++) {
        game.load(game.levels[world * 25]);
        await tester.pumpAndSettle();
        expect(
          tester.widget<SceneBackdrop>(find.byType(SceneBackdrop)).scene,
          world,
        );
        expect(find.byType(WorkshopBackdrop), findsNothing);
        final grid = tester.widget<GridView>(
          find.byKey(const ValueKey('piece-tray-scroll')),
        );
        if (grid.controller!.position.maxScrollExtent > 2) {
          expect(find.text('Swipe up for more'), findsOneWidget);
        }
      }
      game.activePictureTheme = 'woodland-fox';
      game.refresh();
      await tester.pumpAndSettle();
      expect(find.byType(WorkshopBackdrop), findsOneWidget);
      expect(find.byType(SceneBackdrop), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'swiping a piece scrolls within tray; hold enables dragging; hint reveals its row',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = session();
      for (final puzzle in game.levels.reversed) {
        game.load(puzzle);
        if (game.groups.length > 12) break;
      }
      expect(game.groups.length, greaterThan(8));
      await tester.pumpWidget(JarApp(session: game, audience: Audience(2020)));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Next piles'), findsNothing);
      expect(find.text('Swipe up for more'), findsOneWidget);
      final grid = tester.widget<GridView>(
        find.byKey(const ValueKey('piece-tray-scroll')),
      );
      final homeTop = tester.getTopLeft(
        find.byKey(const ValueKey('home-scroll')),
      );
      await tester.drag(
        find.byType(LongPressDraggable<Piece>).first,
        const Offset(0, -140),
      );
      await tester.pumpAndSettle();
      expect(grid.controller!.offset, greaterThan(0));
      expect(game.selected, isNull);
      expect(game.board, isEmpty);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('home-scroll'))),
        homeTop,
      );
      grid.controller!.jumpTo(grid.controller!.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('Swipe down for earlier'), findsOneWidget);
      final tile = find.byType(LongPressDraggable<Piece>).hitTestable().last;
      final gesture = await tester.startGesture(tester.getCenter(tile));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      expect(game.selected, isNotNull);
      await gesture.up();
      await tester.pumpAndSettle();
      // Reset scrolling, then let the real Hint flow reveal its selected group.
      await tester.tap(find.byTooltip('Hint · 10 coins'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use 10 coins'));
      await tester.pumpAndSettle();
      expect(game.selected, isNotNull);
      final chosen = find.byWidgetPredicate(
        (w) =>
            w is LongPressDraggable<Piece> && w.data?.id == game.selected!.id,
      );
      expect(chosen.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
