import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/domain/maze.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/domain/maze_theme.dart';
import 'package:maze_words/domain/hunt_options.dart';
import 'package:maze_words/services/game_services.dart';
import 'package:maze_words/ui/hunt_screen.dart';
import 'package:maze_words/ui/hunt_setup.dart';
import 'package:maze_words/ui/maze_board.dart';
import 'hunt_test.dart' show fixture;

void main() {
  for (final theme in MazeTheme.values) {
    testWidgets(
      '${theme.name} keeps swipe coordinates and clear invalid/rare feedback',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final store = PlayerStore(await SharedPreferences.getInstance());
        await store.set('mazeTheme', theme.name);
        await store.set('sound', false);
        await store.set('haptics', false);
        expect(PlayerStore(store.prefs).mazeTheme, theme);
        final pack = MazePack(
          version: 1,
          level: MazeLevel.easy,
          width: 3,
          height: 2,
          letterCount: 3,
          targetMin: 3,
          targetMax: 4,
          mazes: [fixture()],
        );
        final services = GameServices(store);
        await tester.pumpWidget(
          MaterialApp(
            home: HuntScreen(
              store: store,
              services: services,
              level: MazeLevel.easy,
              relaxed: true,
              prepared: PreparedHunt(pack, const HuntOptions()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<MazeBoard>(find.byType(MazeBoard)).theme, theme);
        final box = tester.getRect(find.byType(MazeBoard));
        final floor = boardRect(box.size);
        Offset cell(int x) =>
            box.topLeft +
            Offset(
              floor.left + (x + .5) * floor.width / 3,
              floor.top + .5 * floor.width / 3,
            );
        var swipe = await tester.startGesture(cell(0));
        await swipe.moveTo(cell(1));
        await swipe.up();
        await tester.pumpAndSettle();
        expect(find.text('That word is not in the maze: CA'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
        swipe = await tester.startGesture(cell(2));
        await swipe.moveTo(cell(1));
        await swipe.moveTo(cell(0));
        await swipe.up();
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Bonus word discovered! TAC'),
          findsOneWidget,
        );
        expect(find.text('Bonus 1'), findsWidgets);
        expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        services.dispose();
      },
    );
  }
}
