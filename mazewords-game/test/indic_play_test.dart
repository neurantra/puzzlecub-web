import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/domain/maze.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/domain/hunt_options.dart';
import 'package:maze_words/services/game_services.dart';
import 'package:maze_words/services/packs/pack_validation.dart';
import 'package:maze_words/ui/hunt_screen.dart';
import 'package:maze_words/ui/hunt_setup.dart';
import 'package:maze_words/ui/maze_board.dart';
import 'package:maze_words/ui/style.dart';

void main() {
  for (final id in ['ta', 'hi', 'bn', 'ja']) {
    testWidgets('$id two-tile word submits in tap mode on a small phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = PlayerStore(await SharedPreferences.getInstance());
      await store.set('tapLetters', true);
      await store.set('sound', false);
      await store.set('haptics', false);
      final bundle = validateBundle(
        File('pack_hosting/packs/$id/1.json').readAsStringSync(),
        id,
        1,
      );
      final original = bundle.levels[MazeLevel.easy]!;
      List<int> tilePath(Maze m, String word) => m.commonPaths[word]!
          .where((c) => m.letterAt(c % m.width, c ~/ m.width) != null)
          .toList();
      final maze = original.mazes.firstWhere(
        (m) => m.commonWords.any((w) => tilePath(m, w).length == 2),
      );
      final word = maze.commonWords.firstWhere(
        (w) => tilePath(maze, w).length == 2,
      );
      final pack = MazePack(
        version: 1,
        level: MazeLevel.easy,
        width: 6,
        height: 6,
        letterCount: 9,
        targetMin: 2,
        targetMax: 3,
        mazes: [maze],
      );
      final services = GameServices(store);
      await tester.pumpWidget(
        MaterialApp(
          theme: mazeTheme(),
          home: HuntScreen(
            store: store,
            services: services,
            level: MazeLevel.easy,
            relaxed: true,
            prepared: PreparedHunt(pack, const HuntOptions(), language: id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(MazeBoard)),
          floor = boardRect(tester.getSize(find.byType(MazeBoard)));
      Offset center(int c) =>
          box.topLeft +
          Offset(
            floor.left + (c % 6 + .5) * floor.width / 6,
            floor.top + (c ~/ 6 + .5) * floor.width / 6,
          );
      final path = tilePath(maze, word);
      await tester.tapAt(center(path.first));
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(FilledButton, 'Submit');
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.tapAt(center(path.last));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.textContaining('Lovely find!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      services.dispose();
    });
  }
}
