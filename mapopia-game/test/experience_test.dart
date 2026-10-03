import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapopia/main.dart';
import 'package:mapopia/game/expedition.dart';
import 'package:mapopia/geo/data/geo_pack.dart';
import 'package:mapopia/geo/domain/geo_region.dart';
import 'package:mapopia/ui/cartography.dart';
import 'package:mapopia/ui/play.dart';
import 'package:mapopia/ui/theme.dart';
import 'support/fake_billing.dart';

Future<AtlasStore> store({bool fullAtlas = true}) async {
  SharedPreferences.setMockInitialValues({
    'fullAtlas': fullAtlas,
    'sound': false,
    'haptics': false,
    'reducedMotion': true,
  });
  return AtlasStore(await SharedPreferences.getInstance());
}

Future<void> fonts() async {
  final loader = FontLoader('PlusJakartaSans');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'));
  }
  await loader.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  for (final region in GeoRegion.values) {
    await GeoPack.load(region);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(fonts);
  testWidgets('phone atlas, setup and journal render with real artwork', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = await store();
    await tester.pumpWidget(MapopiaApp(store: s, today: DateTime(2026, 9, 25)));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/art/atlas-island.png'),
        tester.element(find.byType(MaterialApp)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Where to today?'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/atlas.png'),
    );
    await tester.tap(find.text('Let’s explore Europe'));
    await tester.pumpAndSettle();
    expect(find.text('Begin expedition'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/setup.png'),
    );
    await tester.tap(find.text('Begin expedition'));
    await tester.pumpAndSettle();
    expect(find.text('Your pieces'.toUpperCase()), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Pause expedition').first);
    await tester.pumpAndSettle();
    expect(find.text('Your world can wait.'), findsOneWidget);
    await tester.tap(find.text('Save & return to atlas'));
    await tester.pumpAndSettle();
    expect(find.text('Your adventure is waiting'), findsOneWidget);
    await tester.tap(find.text('My journal'));
    await tester.pumpAndSettle();
    expect(find.text('Your travel journal'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'ACT remains accessible inside placed NSW and zooms without penalty',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pack = await GeoPack.load(GeoRegion.australia);
      final act = pack.pieces.firstWhere((p) => p.id == 'AU-ACT');
      final nsw = pack.pieces.firstWhere((p) => p.id == 'AU-NSW');
      final r = Expedition(pack: pack, seed: 1);
      expect(pack.pieceAt(act.target), act);
      expect(r.accepts(nsw, act.target), false);
      r.placed.add(nsw.id);
      r.select(act.id);
      await tester.pumpWidget(
        MaterialApp(
          theme: atlasTheme(),
          debugShowCheckedModeBanner: false,
          home: PlayScreen(round: r, store: await store()),
        ),
      );
      await tester.pumpAndSettle();
      final board = find
          .byWidgetPredicate((w) => w is CustomPaint && w.painter is MapPainter)
          .first;
      final box = tester.renderObject<RenderBox>(board);
      final fit = MapPainter(pack: pack).actualFit(box.size);
      expect(MapPainter(pack: pack).smallPieces(box.size), contains(act));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../docs/screenshots/australia-act.png'),
      );
      await tester.tapAt(box.localToGlobal(fit.toScreen(act.target)));
      await tester.pumpAndSettle();
      final transform = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;
      expect(transform.value.getMaxScaleOnAxis(), greaterThan(5));
      expect(r.mistakes, 0);
      expect(r.hints, 0);
      expect(r.placed, isNot(contains(act.id)));
      await tester.tapAt(box.localToGlobal(fit.toScreen(act.target)));
      await tester.pumpAndSettle();
      expect(r.placed, contains(act.id));
      expect(r.mistakes, 0);
      // Placement changes the tray height; use the board's current fit.
      final placedFit = MapPainter(pack: pack).actualFit(box.size);
      await tester.tapAt(box.localToGlobal(placedFit.toScreen(act.target)));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.text(act.fact)),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('saved maps at the free third pause without deleting progress', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = await store(fullAtlas: false);
    final saved = Expedition(
      pack: await GeoPack.load(GeoRegion.india),
      seed: 1,
    );
    final quota = s.commerce.trialLimit(saved.pack.pieces.length);
    saved.placed.addAll(saved.pack.pieces.take(quota).map((p) => p.id));
    saved.select(saved.remaining.first.id);
    final originalPlaced = Set.of(saved.placed);
    await s.save(saved);
    saved.dispose();
    await tester.pumpWidget(MapopiaApp(store: s));
    await tester.pumpAndSettle();
    expect(find.text('Explore Australia · Free'), findsOneWidget);
    await tester.tap(find.text('Your adventure is waiting'));
    await tester.pumpAndSettle();
    expect(find.text('So much more to discover.'), findsOneWidget);
    expect(find.byType(PlayScreen), findsNothing);
    final persisted = await Expedition.restore(s.savedRound!);
    expect(persisted.placed, originalPlaced);
    persisted.dispose();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/full-atlas.png'),
    );
    await tester.tap(find.text('Back to atlas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore Australia · Free'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Begin expedition'));
    await tester.pumpAndSettle();
    final round = tester.widget<PlayScreen>(find.byType(PlayScreen)).round;
    expect(round.pack.region, GeoRegion.australia);
    await tester.tap(find.text('A little nudge'));
    await tester.pump();
    expect(round.hints, 1);
    round.clearHint();
    await tester.pump();
    await tester.tap(find.text('A little nudge'));
    await tester.pumpAndSettle();
    expect(find.text('Watch ad · 1 hint'), findsOneWidget);
    expect(round.paused, true);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(round.hints, 1);
    expect(round.paused, false);
    await tester.tap(find.text('A little nudge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch ad · 1 hint'));
    await tester.pumpAndSettle();
    expect(round.hints, 1);
    expect(round.paused, false);
    expect(find.textContaining('No hint earned.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'free placement reaches a third and purchase continues the same map without ads',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await store(fullAtlas: false);
      final billing = FakeBilling();
      final s = AtlasStore(
        await SharedPreferences.getInstance(),
        billing: billing,
      );
      await s.commerce.initialize();
      final pack = await GeoPack.load(GeoRegion.uk);
      final round = Expedition(pack: pack, seed: 2, timed: true);
      final quota = s.commerce.trialLimit(pack.pieces.length);
      round.placed.addAll(pack.pieces.take(quota - 1).map((p) => p.id));
      final piece = round.remaining.firstWhere(
        (p) => pack.pieceAt(p.target)?.id == p.id,
      );
      round.select(piece.id);
      await tester.pumpWidget(
        MaterialApp(
          theme: atlasTheme(),
          home: PlayScreen(round: round, store: s),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('So much more to discover.'), findsNothing);
      final board = find
          .byWidgetPredicate((w) => w is CustomPaint && w.painter is MapPainter)
          .first;
      final box = tester.renderObject<RenderBox>(board);
      final fit = MapPainter(pack: pack).actualFit(box.size);
      await tester.tapAt(box.localToGlobal(fit.toScreen(piece.target)));
      await tester.pumpAndSettle();
      expect(round.placed.length, quota);
      expect(round.paused, true);
      final seconds = round.seconds;
      await tester.pump(const Duration(seconds: 8));
      expect(round.seconds, seconds);
      expect(find.text('So much more to discover.'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(round.placed.length, quota);
      expect(round.paused, true);
      await tester.tap(find.text('Unlock Full Atlas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock Full Atlas · €4.99'));
      await tester.pumpAndSettle();
      expect(s.commerce.fullAtlas, true);
      expect(s.ads.eligible, false);
      await tester.tap(find.text('Keep exploring'));
      await tester.pumpAndSettle();
      expect(round.paused, false);
      expect(round.placed.length, quota);
      final next = round.selected;
      await tester.tapAt(box.localToGlobal(fit.toScreen(next.target)));
      await tester.pumpAndSettle();
      expect(round.placed.length, quota + 1);
      expect(find.text('So much more to discover.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('settings lists all four family games', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MapopiaApp(store: await store(fullAtlas: false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Chaturang'), 250);
    await tester.pumpAndSettle();
    for (final title in [
      'Puzzlecub',
      'Fill the Jar',
      'Maze Words',
      'Chaturang',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/family-games.png'),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('placement by tap, hint, pause and results work end to end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = await store();
    final pack = await GeoPack.load(GeoRegion.europe);
    final r = Expedition(pack: pack, seed: 3);
    // Begin with a genuinely played section to review the filled ceramic map.
    for (final name in [
      'France',
      'Spain',
      'Portugal',
      'Germany',
      'Italy',
      'Poland',
      'Switzerland',
      'Austria',
      'Belgium',
      'Netherlands',
    ]) {
      final pieces = pack.pieces.where((p) => p.name == name);
      if (pieces.isNotEmpty) {
        final p = pieces.first;
        r.select(p.id);
        r.place(p.rings.first.first);
      }
    }
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: atlasTheme(),
        home: PlayScreen(round: r, store: s),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/expedition.png'),
    );
    await tester.tap(find.byTooltip('Switch to daytime map'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/expedition-day.png'),
    );
    final count = r.placed.length;
    final board = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is MapPainter,
    );
    final size = tester.getSize(board.first);
    final fit = MapPainter(pack: pack).actualFit(size);
    await tester.tapAt(
      tester.getTopLeft(board.first) +
          fit.toScreen(r.selected.rings.first.first),
    );
    await tester.pumpAndSettle();
    expect(r.placed.length, count + 1);
    await tester.tap(find.text('A little nudge'));
    await tester.pump();
    expect(r.hints, 1);
    await tester.tap(find.byTooltip('Pause expedition').first);
    await tester.pumpAndSettle();
    expect(r.paused, true);
    await tester.tap(find.text('Back to exploring'));
    await tester.pumpAndSettle();
    expect(r.paused, false);
    while (!r.complete) {
      r.place(r.selected.rings.first.first);
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Beautifully explored.'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/completed-day.png'),
    );
    await tester.tap(find.byTooltip('Switch to nighttime map'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/completed.png'),
    );
    expect(s.completedMaps, 1);
    final france = pack.pieces.firstWhere((p) => p.name == 'France');
    final resultBoard = find
        .byWidgetPredicate((w) => w is CustomPaint && w.painter is MapPainter)
        .first;
    final resultBox = tester.renderObject<RenderBox>(resultBoard);
    await tester.tapAt(
      resultBox.localToGlobal(
        MapPainter(
          pack: pack,
        ).actualFit(resultBox.size).toScreen(france.target),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text(france.fact),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Close place information'));
    await tester.pumpAndSettle();
    expect(r.complete, isTrue);
    expect(s.completedMaps, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'saving and reopening USA tile restores progress, view and tray',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = await store();
      await tester.pumpWidget(
        MapopiaApp(store: s, today: DateTime(2026, 9, 25)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'United States');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byWidgetPredicate((w) => w is Text && w.data == 'United States'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((w) => w is Text && w.data == 'United States'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin expedition'));
      await tester.pumpAndSettle();
      final r = tester.widget<PlayScreen>(find.byType(PlayScreen)).round;
      final texas = r.pack.pieces.firstWhere((p) => p.name == 'Texas');
      r.select(texas.id);
      expect(r.place(texas.target), isTrue);
      r.hint();
      expect(r.place(const Offset(-100, -100)), isFalse);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(InteractiveViewer), const Offset(-35, 18));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(-160, 0));
      await tester.pumpAndSettle();
      final before = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value
          .clone();
      final tray = tester
          .widget<ListView>(find.byType(ListView))
          .controller!
          .offset;
      expect(tray, greaterThan(0));
      final selected = r.selectedId;
      final order = r.order.map((p) => p.id).toList();
      final score = r.score;
      await tester.tap(find.byTooltip('Pause expedition').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & return to atlas'));
      await tester.pumpAndSettle();
      expect(s.savedRoundFor(GeoRegion.usa), isNotNull);
      // Simulate reopening the app, then choose the original region tile rather
      // than relying on the separate "continue" banner.
      await tester.pumpWidget(const SizedBox());
      final reopened = AtlasStore(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        MapopiaApp(store: reopened, today: DateTime(2026, 9, 25)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(TextField),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'United States');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byWidgetPredicate((w) => w is Text && w.data == 'United States'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((w) => w is Text && w.data == 'United States'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Begin expedition'), findsNothing);
      final restored = tester.widget<PlayScreen>(find.byType(PlayScreen)).round;
      expect(restored.placed, {texas.id});
      expect(restored.selectedId, selected);
      expect(restored.order.map((p) => p.id).toList(), order);
      expect(restored.hints, 1);
      expect(restored.mistakes, 1);
      expect(restored.score, score);
      final after = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value;
      for (var i = 0; i < 16; i++) {
        expect(
          after.storage[i],
          moreOrLessEquals(before.storage[i], epsilon: 1e-8),
        );
      }
      expect(
        tester.widget<ListView>(find.byType(ListView)).controller!.offset,
        moreOrLessEquals(tray),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'resumed India can change from Clues to Shapes without losing other maps',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = await store();
      final usa = Expedition(pack: await GeoPack.load(GeoRegion.usa), seed: 1);
      await s.save(usa);
      usa.dispose();
      final original = Expedition(
        pack: await GeoPack.load(GeoRegion.india),
        trail: Trail.clues,
        timed: true,
        seed: 2,
      );
      final piece = original.pack.pieces.firstWhere(
        (p) => p.name == 'Maharashtra',
      );
      original.select(piece.id);
      expect(original.place(piece.target), isTrue);
      await s.save(original);
      original.dispose();
      final usaSave = s.savedRoundFor(GeoRegion.usa);
      await tester.pumpWidget(
        MapopiaApp(store: s, today: DateTime(2026, 9, 25)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Your adventure is waiting'));
      await tester.pumpAndSettle();
      final round = tester.widget<PlayScreen>(find.byType(PlayScreen)).round;
      expect(round.trail, Trail.clues);
      await tester.tap(find.byTooltip('Pause expedition').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change play mode'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Clues'))
            .selected,
        isTrue,
      );
      // Changing a choice and dismissing the sheet must not discard the old round.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Shapes'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(round.trail, Trail.clues);
      expect(round.placed, {piece.id});
      expect(round.timed, isTrue);
      expect(round.paused, isTrue);
      final kept = await Expedition.restore(s.savedRoundFor(GeoRegion.india)!);
      expect(kept.trail, Trail.clues);
      expect(kept.placed, {piece.id});
      kept.dispose();
      await tester.tap(find.text('Change play mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Shapes'));
      await tester.tap(find.text('Relaxed'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start new expedition'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start new expedition'));
      await tester.pumpAndSettle();
      final next = tester.widget<PlayScreen>(find.byType(PlayScreen)).round;
      expect(next, isNot(same(round)));
      expect(next.pack.region, GeoRegion.india);
      expect(next.trail, Trail.shapes);
      expect(next.timed, isFalse);
      expect(next.placed, isEmpty);
      expect(next.score, 0);
      expect(next.paused, isFalse);
      expect(s.savedRoundFor(GeoRegion.usa), usaSave);
      // Old-round timers must not overwrite the replacement's save.
      await tester.pump(const Duration(seconds: 6));
      await tester.tap(find.byTooltip('Pause expedition').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & return to atlas'));
      await tester.pumpAndSettle();
      expect(find.text('Where to today?'), findsOneWidget);
      await tester.tap(find.text('Your adventure is waiting'));
      await tester.pumpAndSettle();
      final resumed = tester.widget<PlayScreen>(find.byType(PlayScreen)).round;
      expect(resumed.trail, Trail.shapes);
      expect(resumed.timed, isFalse);
      expect(resumed.placed, isEmpty);
      expect(s.savedRoundFor(GeoRegion.usa), usaSave);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('map lighting persists without changing play or zoom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = await store();
    final pack = await GeoPack.load(GeoRegion.uk);
    final r = Expedition(pack: pack, seed: 3);
    expect(r.place(r.selected.target), isTrue);
    r.hint();
    await tester.pumpWidget(
      MaterialApp(
        theme: atlasTheme(),
        home: PlayScreen(round: r, store: s),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    final controller = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    final transform = controller.value.clone();
    final selected = r.selectedId;
    final placed = Set.of(r.placed);
    final hint = r.hintId;
    final score = r.score;
    await tester.tap(find.byTooltip('Switch to daytime map'));
    await tester.pumpAndSettle();
    expect(s.nightMap, isFalse);
    final reopened = AtlasStore(await SharedPreferences.getInstance());
    expect(reopened.nightMap, isFalse);
    reopened.dispose();
    final board = tester.widget<CustomPaint>(
      find
          .byWidgetPredicate((w) => w is CustomPaint && w.painter is MapPainter)
          .first,
    );
    expect((board.painter! as MapPainter).dark, isFalse);
    expect(controller.value, transform);
    expect(r.selectedId, selected);
    expect(r.placed, placed);
    expect(r.hintId, hint);
    expect(r.score, score);
    expect(r.mistakes, 0);
    await tester.tap(find.byTooltip('Switch to nighttime map'));
    await tester.pumpAndSettle();
    expect(s.nightMap, isTrue);
    expect(controller.value, transform);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  for (final destination in [
    (GeoRegion.uk, 'England'),
    (GeoRegion.usa, 'Texas'),
  ]) {
    testWidgets('placed ${destination.$2} opens info without changing play', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = await store();
      final pack = await GeoPack.load(destination.$1);
      final piece = pack.pieces.firstWhere((p) => p.name == destination.$2);
      final r = Expedition(pack: pack, seed: 3, timed: true);
      r.select(piece.id);
      expect(r.place(piece.target), isTrue);
      final selected = r.selectedId;
      final score = r.score;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: atlasTheme(),
          home: PlayScreen(round: r, store: s),
        ),
      );
      await tester.pumpAndSettle();
      final board = find
          .byWidgetPredicate((w) => w is CustomPaint && w.painter is MapPainter)
          .first;
      Offset piecePosition() {
        final box = tester.renderObject<RenderBox>(board);
        return box.localToGlobal(
          MapPainter(pack: pack).actualFit(box.size).toScreen(piece.target),
        );
      }

      for (final zoom in [false, true]) {
        if (zoom) {
          await tester.tap(find.byTooltip('Switch to daytime map'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Zoom in'));
          await tester.pumpAndSettle();
        }
        await tester.tapAt(piecePosition());
        await tester.pumpAndSettle();
        final dialog = find.byType(Dialog);
        expect(dialog, findsOneWidget);
        for (final text in [piece.name, piece.capital, piece.fact]) {
          expect(
            find.descendant(of: dialog, matching: find.text(text)),
            findsOneWidget,
          );
        }
        expect(r.selectedId, selected);
        expect(r.placed, {piece.id});
        expect(r.mistakes, 0);
        expect(r.hints, 0);
        expect(r.score, score);
        await tester.tap(find.byTooltip('Close place information'));
        await tester.pumpAndSettle();
      }
      // A drag onto a placed region is still a wrong placement, not inspection.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(LongPressDraggable<String>).first),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.moveTo(piecePosition());
      await tester.pump(const Duration(milliseconds: 80));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(r.mistakes, 1);
      expect(r.placed, {piece.id});
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('hold and drag places a piece on a zoomed map', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = await store();
    final pack = await GeoPack.load(GeoRegion.uk);
    final r = Expedition(pack: pack, seed: 3);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: atlasTheme(),
        home: PlayScreen(round: r, store: s),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    final board = find
        .byWidgetPredicate((w) => w is CustomPaint && w.painter is MapPainter)
        .first;
    final box = tester.renderObject<RenderBox>(board);
    final fit = MapPainter(pack: pack).actualFit(box.size);
    final target = box.localToGlobal(fit.toScreen(r.selected.target));
    final card = find.byType(LongPressDraggable<String>).first;
    final gesture = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(r.placed.length, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets('play adapts to $size without overflow', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = await store();
      final r = Expedition(pack: await GeoPack.load(GeoRegion.usa), seed: 4);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: atlasTheme(),
          home: PlayScreen(round: r, store: s),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
