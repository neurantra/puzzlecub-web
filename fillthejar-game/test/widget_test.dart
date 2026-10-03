import 'package:fill_the_jar/services/audience.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/main.dart';
import 'package:fill_the_jar/ui/art.dart';
import 'package:fill_the_jar/ui/wooden_jar.dart';
import 'package:fill_the_jar/ui/game_screen.dart';
import 'package:fill_the_jar/ui/scene_backdrop.dart';
import 'package:fill_the_jar/game/geometry.dart';
import 'package:fill_the_jar/game/session.dart';

GameSession session({bool freePlayLimited = false}) {
  final j = jsonDecode(File('assets/levels.json').readAsStringSync());
  return GameSession(
      (j['levels'] as List)
          .map((p) => Puzzle.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      (j['previews'] as List)
          .map((p) => Puzzle.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      freePlayLimited: freePlayLimited,
      replayCampaigns: (j['replayCampaigns'] as List)
          .map(
            (tour) => (tour as List)
                .map((p) => Puzzle.fromJson(Map<String, dynamic>.from(p)))
                .toList(),
          )
          .toList(),
    )
    ..motion = false
    ..sound = false
    ..haptics = false;
}

void main() {
  testWidgets(
    'family games appear below the full play area and in the drawer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        JarApp(audience: Audience(1990), session: session()),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Play PuzzleCub')).dy,
        greaterThan(844),
      );
      await tester.drag(
        find.byKey(const ValueKey('home-scroll')),
        const Offset(0, -550),
      );
      await tester.pumpAndSettle();
      expect(find.text('Play PuzzleCub').hitTestable(), findsOneWidget);
      expect(find.text('Play Chaturang').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byKey(const ValueKey('home-scroll')),
        const Offset(0, 800),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Play PuzzleCub'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Play Chaturang'), findsOneWidget);
    },
  );
  test('four scenes each contain exactly 25 contiguous campaign levels', () {
    for (var scene = 0; scene < 4; scene++) {
      final levels = List.generate(
        100,
        (i) => i + 1,
      ).where((n) => sceneForLevel(n) == scene).toList();
      expect(levels, List.generate(25, (i) => scene * 25 + i + 1));
    }
  });
  testWidgets('phone layout, coin-priced hint, drawer and settings work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = session();
    await tester.pumpWidget(JarApp(audience: Audience(1990), session: s));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Level 01'), findsOneWidget);
    await tester.tap(find.byTooltip('Hint · 10 coins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use 10 coins'));
    await tester.pumpAndSettle();
    expect(s.coins, 50);
    expect(s.selected, isNotNull);
    expect(find.byTooltip('Drop'), findsNothing);
    await tester.tap(find.byIcon(Icons.arrow_downward_rounded).first);
    await tester.pumpAndSettle();
    expect(s.board.length, 1);
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Sound effects'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('late-level piles fit small phones and larger screens', (
    tester,
  ) async {
    for (final size in [
      const Size(320, 568),
      const Size(430, 932),
      const Size(768, 1024),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final s = session();
      s.load(s.levels.last);
      await tester.pumpWidget(
        JarApp(audience: Audience(1990), key: UniqueKey(), session: s),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('wooden design has no separate studio or inspection controls', (
    tester,
  ) async {
    final s = session()
      ..dimensionUnlocked = true
      ..dimension = true;
    await tester.pumpWidget(JarApp(audience: Audience(1990), session: s));
    await tester.pumpAndSettle();
    expect(find.byTooltip('3D studio'), findsNothing);
    expect(find.text('Turn jar & pieces'), findsNothing);
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('3D studio'), findsNothing);
  });
  testWidgets('Level 6 triangle drops on first tap anywhere across its gap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final point in [
      const Offset(.4, .15),
      const Offset(1.35, .6),
      const Offset(1.85, 1.4),
    ]) {
      final s = session()..dimension = true;
      final data = jsonDecode(File('assets/levels.json').readAsStringSync());
      final oldSix = (data['legacyLevels'] as List).firstWhere(
        (p) => p['number'] == 6,
      );
      s.load(Puzzle.fromJson(Map<String, dynamic>.from(oldSix)));
      final pieces = s.puzzle.pieces;
      // The user's alternative Level 6 arrangement: triangle gap at top left.
      s.board = [
        pieces[0].at(0, 0),
        pieces[2].at(2, 2.5),
        pieces[3].at(2, 0),
        pieces[4].at(0, 3.5),
        pieces[5].at(0, 2),
      ];
      s.select(pieces[1]);
      await tester.pumpWidget(
        JarApp(audience: Audience(1990), key: UniqueKey(), session: s),
      );
      await tester.pumpAndSettle();
      final jar = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            (w.painter is JarPainter || w.painter is WoodenJarPainter),
      );
      final rect = WoodenJarPainter.bounds(tester.getSize(jar), s.puzzle);
      await tester.tapAt(
        tester
            .renderObject<RenderBox>(jar)
            .localToGlobal(rect.topLeft + point * (rect.width / s.puzzle.w)),
      );
      await tester.pumpAndSettle();
      expect(s.complete, isTrue, reason: 'First tap at $point');
      expect(s.board.length, 6);
      expect(s.board.last.x, 0);
      expect(s.board.last.y, 0);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'toolbar, bottom piles, sound and scenery settings remain accessible',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = session()..unlocked = 100;
      s.load(s.levels[25]);
      await tester.pumpWidget(JarApp(audience: Audience(1990), session: s));
      await tester.pumpAndSettle();
      final jar = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            (w.painter is JarPainter || w.painter is WoodenJarPainter),
      );
      expect(tester.getSize(jar).height, greaterThan(400));
      expect(
        tester.getTopLeft(find.byTooltip('Rotate')).dy,
        lessThan(tester.getTopLeft(jar).dy),
      );
      expect(
        tester.getTopLeft(find.text('YOUR LITTLE PIECE PILES')).dy,
        greaterThan(844 * .75),
      );
      expect(find.byType(WoodenJar), findsOneWidget);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Glass jar & wooden pieces'));
      await tester.pumpAndSettle();
      expect(tester.widget<SceneBackdrop>(find.byType(SceneBackdrop)).scene, 1);
      await tester.tap(find.text('Sound effects'));
      await tester.pumpAndSettle();
      expect(s.sound, isTrue);
      await tester.tap(find.text('Animated scenery'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(s.motion, isTrue);
      final saved = session()..restore(s.encode());
      expect(saved.sound, isTrue);
      expect(saved.motion, isTrue);
      await tester.tap(find.text('Animated scenery'));
      await tester.pumpAndSettle();
      expect(s.motion, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'level picker keeps campaign progress and hides prototype samplers',
    (tester) async {
      final s = session()..unlocked = 2;
      s.load(s.levels[1]);
      await tester.pumpWidget(JarApp(audience: Audience(1990), session: s));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Levels & scenes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Campaign progress: level 2'), findsOneWidget);
      expect(find.textContaining('Mixed'), findsNothing);
      expect(find.textContaining('Angle play'), findsNothing);
      expect(s.puzzle.number, 2);
      expect(s.unlocked, 2);
    },
  );
  testWidgets('loaded banner takes its own space below all piles', (
    tester,
  ) async {
    for (final screen in [const Size(320, 568), const Size(390, 844)]) {
      for (final height in [50.0, 90.0]) {
        tester.view.physicalSize = screen;
        tester.view.devicePixelRatio = 1;
        final s = session()..dimension = true;
        s.load(s.levels.last);
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              audience: Audience(1990),
              key: UniqueKey(),
              session: s,
              bannerSize: Size(320, height),
              banner: const ColoredBox(
                key: Key('test-banner'),
                color: Colors.grey,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bannerRect = tester.getRect(find.byKey(const Key('test-banner')));
        final gridRect = tester.getRect(find.byType(GridView));
        expect(gridRect.bottom, lessThan(bannerRect.top));
        expect(bannerRect.height, height);
        expect(bannerRect.bottom, lessThanOrEqualTo(screen.height));
        expect(tester.takeException(), isNull, reason: '$screen / $height');
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets(
    'Level 100 completion starts a fresh saved journey from the inline completion controls',
    (tester) async {
      final s = session()..unlocked = 100;
      s.completed.addAll(s.levels.map((p) => p.key));
      s.load(s.levels.last);
      s.board = solution(s.puzzle);
      s.checkComplete();
      final coins = s.coins;
      await tester.pumpWidget(JarApp(audience: Audience(1990), session: s));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start a fresh journey >>'));
      await tester.pumpAndSettle();
      expect(find.text('Level 01'), findsOneWidget);
      expect(s.journey, 2);
      expect(s.campaign, isNot(0));
      expect(s.coins, coins);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'finished jar remains visible until Next is tapped on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = session();
      s.board = solution(s.puzzle);
      s.checkComplete();
      final coins = s.coins;
      final pieces = s.board.length;
      await tester.pumpWidget(JarApp(audience: Audience(1990), session: s));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('completion-bar')), findsOneWidget);
      expect(find.text('One jar full. A little more joy.'), findsNothing);
      expect(find.text('YOUR LITTLE PIECE PILES'), findsNothing);
      expect(s.board.length, pieces);
      expect(s.complete, isTrue);
      expect(tester.getBottomRight(find.text('Next >>')).dy, lessThan(568));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Next >>'));
      await tester.pumpAndSettle();
      expect(s.puzzle.number, 2);
      expect(s.board, isEmpty);
      expect(s.coins, coins);
      expect(find.byKey(const ValueKey('completion-bar')), findsNothing);
    },
  );
  testWidgets('insufficient funds offer rewarded ad, never silently charge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = session()..coins = 0;
    await tester.pumpWidget(JarApp(audience: Audience(1990), session: s));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hint · 10 coins'));
    await tester.pumpAndSettle();
    expect(find.text('Use 10 coins'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Use 10 coins'),
          )
          .onPressed,
      isNull,
    );
    expect(find.textContaining('View ad'), findsOneWidget);
    expect(s.coins, 0);
  });
}
