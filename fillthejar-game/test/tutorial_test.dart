import 'dart:io';
import 'package:fill_the_jar/game/geometry.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fill_the_jar/ui/picture_art.dart';
import 'package:fill_the_jar/ui/wooden_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fill_the_jar/main.dart';
import 'package:fill_the_jar/services/audience.dart';
import 'package:fill_the_jar/services/services.dart';
import 'package:fill_the_jar/ui/tutorial.dart';
import 'widget_test.dart' show session;

void main() {
  test('demo begins empty, uses slanted shapes and finishes without gaps', () {
    expect(TutorialPainter(0, 0).demoBoard, isEmpty);
    expect(TutorialPainter(0, 1).demoBoard, isEmpty);
    expect(TutorialPainter.triangle.name, 'Triangle');
    expect(TutorialPainter.parallelogram.name, 'Parallelogram');
    final puzzle = TutorialPainter.puzzle;
    expect(solution(puzzle).length, puzzle.pieces.length);
    for (int step = 1; step < 8; step++) {
      final board = TutorialPainter(step, 1).demoBoard;
      for (final p in board) {
        expect(
          p.x >= 0 &&
              p.y >= 0 &&
              p.x + p.w <= puzzle.w &&
              p.y + p.h <= puzzle.h,
          isTrue,
        );
        for (final q in board.where((q) => q.id != p.id)) {
          expect(overlaps(p, q), isFalse, reason: 'Stage $step');
        }
      }
    }
    expect(solved(TutorialPainter(7, 1).demoBoard, puzzle), isTrue);
  });

  testWidgets('tutorial pauses, mutes, resumes and renders real game artwork', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (const bool.fromEnvironment('CAPTURE_TUTORIAL')) {
      await tester.runAsync(() async {
        await WoodMaterial.load();
        await PictureArt.load();
        await (FontLoader('Roboto')..addFont(
              Future.value(
                ByteData.sublistView(
                  File(
                    '/opt/homebrew/share/flutter/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
                  ).readAsBytesSync(),
                ),
              ),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
    }
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showTutorial(context),
                child: const Text('Demo'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Demo'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('Slide into place'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause tutorial'));
    await tester.pump();
    await tester.tap(find.byTooltip('Unmute tutorial'));
    await tester.pump();
    expect(find.byTooltip('Mute tutorial'), findsOneWidget);
    await tester.tap(find.byTooltip('Mute tutorial'));
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Slide into place'), findsOneWidget);
    if (const bool.fromEnvironment('CAPTURE_TUTORIAL')) {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../artifacts/tutorial-slide.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.tap(find.byTooltip('Play tutorial'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 18));
    expect(find.text('Everything fits.'), findsOneWidget);
    await tester.tap(find.text('Let’s play'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'first-run tutorial is skippable, remembered and preserves game',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = SaveStore(await SharedPreferences.getInstance());
      final game = session();
      final before = game.encode();
      await tester.pumpWidget(
        JarApp(session: game, store: store, audience: Audience(2020)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Choose a piece'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(store.prefs.getBool(tutorialSeenKey), isTrue);
      expect(game.encode(), before);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        JarApp(session: game, store: store, audience: Audience(2020)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Choose a piece'), findsNothing);
    },
  );

  testWidgets(
    'demo completes on small screen and replay does not mutate progress',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = session()..unlocked = 2;
      game.load(game.levels[1]);
      final before = game.encode();
      await tester.pumpWidget(JarApp(session: game, audience: Audience(2020)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Watch tutorial'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 29));
      expect(find.text('Everything fits.'), findsOneWidget);
      await tester.ensureVisible(find.text('Replay'));
      await tester.tap(find.text('Replay'));
      await tester.pump();
      expect(find.text('Choose a piece'), findsOneWidget);
      await tester.tap(find.text('Let’s play'));
      await tester.pumpAndSettle();
      expect(game.encode(), before);
      expect(tester.takeException(), isNull);
    },
  );
}
