import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/data/maze_pack.dart';
import 'package:maze_words/main.dart';
import 'package:maze_words/ui/maze_board.dart';
import 'package:maze_words/ui/hunt_screen.dart';
import 'package:maze_words/services/game_services.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/ui/style.dart';
import 'package:maze_words/ui/vault_sheet.dart';
import 'dart:io';

Future<PlayerStore> player() async {
  SharedPreferences.setMockInitialValues({});
  final store = PlayerStore(await SharedPreferences.getInstance());
  await store.set('onboarded', true);
  await store.set('sound', false);
  await store.set('haptics', false);
  return store;
}

Future<void> preload(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final level in MazeLevel.values) {
      await MazePackLoader.load(level);
    }
  });
}

void main() {
  testWidgets('home, settings, relaxed play and review work on a phone', (
    tester,
  ) async {
    await preload(tester);
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MazeWordsApp(store: await player()));
    await tester.pumpAndSettle();
    expect(find.text('Find your\nway with words.'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Puzzlecub'), findsNothing);
    await tester.tap(find.byTooltip('Close settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Let’s wander'));
    await tester.tap(find.text('Let’s wander'));
    await tester.pumpAndSettle();
    expect(find.text('no rush'), findsOneWidget);
    expect(find.byType(MazeBoard), findsOneWidget);
    await tester.ensureVisible(find.text('End hunt').first);
    await tester.tap(find.text('End hunt').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('End hunt').last);
    await tester.pumpAndSettle();
    expect(find.text('A trail well travelled.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('board keeps a fast drag on the actual traversed cells', (
    tester,
  ) async {
    await preload(tester);
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await player();
    await tester.pumpWidget(
      MaterialApp(
        theme: mazeTheme(),
        home: HuntScreen(
          store: store,
          services: GameServices(store),
          level: MazeLevel.easy,
          relaxed: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final board = tester.widget<MazeBoard>(find.byType(MazeBoard));
    final maze = board.maze;
    final path = maze.commonPaths[maze.seedWord]!;
    final box = tester.getRect(find.byType(MazeBoard));
    final floor = boardRect(box.size);
    Offset center(int cell) =>
        box.topLeft +
        Offset(
          floor.left + (cell % maze.width + .5) * floor.width / maze.width,
          floor.top + (cell ~/ maze.width + .5) * floor.height / maze.height,
        );
    final gesture = await tester.startGesture(center(path.first));
    for (final cell in path.skip(1)) {
      await gesture.moveTo(center(cell));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<MazeBoard>(find.byType(MazeBoard)).path, isEmpty);
    expect(find.textContaining(maze.seedWord), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'tap B A T on the user’s maze, undo, and submit without scrolling',
    (tester) async {
      await preload(tester);
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await player();
      final pack = await MazePackLoader.load(MazeLevel.medium);
      final index = pack.mazes.indexWhere((m) => m.id == 'medium-048');
      await tester.pumpWidget(
        MaterialApp(
          theme: mazeTheme(),
          home: HuntScreen(
            store: store,
            services: GameServices(store),
            level: MazeLevel.medium,
            relaxed: true,
            daily: index,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap letters'));
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(MazeBoard));
      expect(box.top, lessThan(210));
      expect(box.width, greaterThanOrEqualTo(390));
      final floor = boardRect(box.size);
      Offset cell(int index) =>
          box.topLeft +
          Offset(
            floor.left + (index % 7 + .5) * floor.width / 7,
            floor.top + (index ~/ 7 + .5) * floor.height / 7,
          );
      await tester.tapAt(cell(41));
      await tester.pump();
      expect(find.text('B'), findsOneWidget);
      await tester.tapAt(cell(13));
      await tester.pump();
      expect(find.textContaining('No clear route'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      await tester.tapAt(cell(27));
      await tester.pump();
      await tester.tapAt(cell(13));
      await tester.pump();
      expect(find.text('BAT'), findsOneWidget);
      await tester.tap(find.byTooltip('Undo last letter'));
      await tester.pump();
      expect(find.text('BA'), findsOneWidget);
      await tester.tapAt(cell(13));
      await tester.pump();
      expect(tester.getRect(find.text('Submit')).bottom, lessThan(874));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(find.textContaining('BAT · +30 points'), findsOneWidget);
      expect(find.textContaining('Maze 1/'), findsWidgets);
      expect(find.text('Bonus 0'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('found-words')));
      await tester.pumpAndSettle();
      expect(find.text('BAT'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('small screen and large text remain usable', (tester) async {
    await preload(tester);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: mazeTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: HuntScreen(
          store: await player(),
          services: GameServices(await player()),
          level: MazeLevel.hard,
          relaxed: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tap letters'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit'));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('play sound and haptics controls persist independently', (
    tester,
  ) async {
    await preload(tester);
    final store = await player();
    final services = GameServices(store);
    await tester.pumpWidget(
      MaterialApp(
        theme: mazeTheme(),
        home: HuntScreen(
          store: store,
          services: services,
          level: MazeLevel.easy,
          relaxed: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sound and haptics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sound off'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(store.sound, isTrue);
    expect(store.haptics, isFalse);
    await tester.tap(find.byTooltip('Sound and haptics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Haptics off'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(store.haptics, isTrue);
    final restored = PlayerStore(await SharedPreferences.getInstance());
    expect(restored.sound, isTrue);
    expect(restored.haptics, isTrue);
    await tester.tap(find.byTooltip('Sound and haptics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sound on'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sound and haptics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Haptics on'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(store.sound, isFalse);
    expect(store.haptics, isFalse);
    expect(find.byTooltip('Pause'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    services.dispose();
  });

  testWidgets('coin vault pauses a timed trail and resumes on closing', (
    tester,
  ) async {
    await preload(tester);
    final store = await player();
    await tester.pumpWidget(
      MaterialApp(
        theme: mazeTheme(),
        home: HuntScreen(
          store: store,
          services: GameServices(store),
          level: MazeLevel.easy,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Coin vault'));
    await tester.pumpAndSettle();
    expect(find.byType(VaultSheet), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    Navigator.of(tester.element(find.byType(VaultSheet))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Paused'), findsNothing);
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(find.text('1:30'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('render home and board for visual review', (tester) async {
    await preload(tester);
    await tester.runAsync(() async {
      final font = FontLoader('PlusJakartaSans');
      for (final weight in [
        'Regular',
        'Medium',
        'SemiBold',
        'Bold',
        'ExtraBold',
      ]) {
        font.addFont(
          rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'),
        );
      }
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await player();
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MazeWordsApp(store: store),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = (await tester.runAsync(
        () => boundary.toImage(pixelRatio: 2),
      ))!;
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      );
      await tester.runAsync(() async {
        await Directory('build/previews').create(recursive: true);
        await File(
          'build/previews/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      });
      image.dispose();
    }

    await capture('home');
    await tester.ensureVisible(find.text('Let’s wander'));
    await tester.tap(find.text('Let’s wander'));
    await tester.pumpAndSettle();
    await capture('play');
    await tester.pumpWidget(const SizedBox());
  });
}
