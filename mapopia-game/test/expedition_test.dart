import 'dart:convert';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapopia/game/expedition.dart';
import 'package:mapopia/geo/data/geo_pack.dart';
import 'package:mapopia/geo/domain/geo_fit.dart';
import 'package:mapopia/geo/domain/geo_piece.dart';
import 'package:mapopia/geo/domain/geo_region.dart';
import 'package:shared_preferences/shared_preferences.dart';

GeoPiece square(String id, double x) => GeoPiece(
  id: id,
  name: id,
  capital: 'Capital $id',
  fact: 'Fact $id',
  expertClue: '',
  target: Offset(x + 25, 25),
  rings: [
    [Offset(x, 0), Offset(x + 50, 0), Offset(x + 50, 50), Offset(x, 50)],
  ],
  neighbors: [],
);
GeoPack sample() => GeoPack(
  region: GeoRegion.uk,
  name: 'Test',
  version: 1,
  viewBox: const Size(100, 50),
  pieces: [square('a', 0), square('b', 50)],
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('placement rejects neighbors, accepts polygon and coast grace', () {
    final r = Expedition(pack: sample(), seed: 2);
    addTearDown(r.dispose);
    r.select('a');
    expect(r.place(const Offset(75, 25)), false);
    expect(r.mistakes, 1);
    expect(r.place(const Offset(-4, 25)), true);
    expect(r.placed, {'a'});
    expect(r.place(const Offset(75, 25)), true);
    expect(r.complete, true);
    expect(r.score, 680);
    expect(r.place(const Offset(75, 25)), false);
  });
  test('hints, pause, and completion gate mutations', () {
    final r = Expedition(pack: sample());
    addTearDown(r.dispose);
    r.hint();
    r.hint();
    expect(r.hints, 1);
    r.pause();
    expect(r.place(r.selected.target), false);
    r.hint();
    expect(r.hints, 1);
    r.resume();
    expect(r.place(r.selected.target), true);
    expect(r.place(r.selected.target), true);
    expect(r.stars, 2);
    expect(r.score, 665);
  });
  test(
    'all 18 region packs have valid unique geometry and are solvable',
    () async {
      for (final region in GeoRegion.values) {
        final pack = await GeoPack.load(region);
        expect(pack.pieces.length, greaterThan(0));
        expect(pack.pieces.map((p) => p.id).toSet().length, pack.pieces.length);
        expect(pack.viewBox.width, greaterThan(0));
        expect(pack.viewBox.height, greaterThan(0));
        final r = Expedition(pack: pack, seed: 7);
        final fit = GeoFit(
          scale: 1,
          origin: Offset.zero,
          viewBox: pack.viewBox,
        );
        for (final piece in pack.pieces) {
          expect(piece.bounds.width, greaterThan(0), reason: piece.id);
          final path = fit.screenPath(piece);
          Offset? inside;
          if (path.contains(piece.target) &&
              pack.pieceAt(piece.target)?.id == piece.id) {
            inside = piece.target;
          } else {
            for (var y = 0; y < 35 && inside == null; y++) {
              for (var x = 0; x < 35 && inside == null; x++) {
                final pt = Offset(
                  piece.bounds.left + (x + .5) * piece.bounds.width / 35,
                  piece.bounds.top + (y + .5) * piece.bounds.height / 35,
                );
                if (path.contains(pt) && pack.pieceAt(pt)?.id == piece.id) {
                  inside = pt;
                }
              }
            }
          }
          expect(inside, isNotNull, reason: 'Interior point for ${piece.id}');
          r.select(piece.id);
          expect(r.place(inside!), true, reason: piece.id);
        }
        expect(r.complete, true, reason: region.name);
        r.dispose();
      }
    },
  );
  test(
    'saved expedition restores selections, penalties and elapsed time',
    () async {
      final p = await GeoPack.load(GeoRegion.uk);
      final r = Expedition(
        pack: p,
        trail: Trail.capitals,
        timed: true,
        seed: 4,
      );
      r.hint();
      r.place(r.selected.rings.first.first);
      r.pause();
      final restored = await Expedition.restore(jsonEncode(r.toJson()));
      expect(restored.placed, r.placed);
      expect(restored.selectedId, r.selectedId);
      expect(restored.order.map((p) => p.id), r.order.map((p) => p.id));
      expect(restored.trail, Trail.capitals);
      expect(restored.hints, 1);
      expect(restored.paused, true);
      r.dispose();
      restored.dispose();
    },
  );
  test(
    'restored timed round ends at deadline and cannot accept a late move',
    () async {
      final p = await GeoPack.load(GeoRegion.uk);
      final r = Expedition(pack: p, timed: true);
      final saved = r.toJson()..['seconds'] = r.allowance;
      final restored = await Expedition.restore(jsonEncode(saved));
      restored.resume();
      restored.tick();
      expect(restored.ended, true);
      expect(restored.complete, false);
      expect(restored.place(restored.selected.target), false);
      r.dispose();
      restored.dispose();
    },
  );
  test(
    'daily completion stamps region without double-counting an expedition',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = AtlasStore(await SharedPreferences.getInstance());
      final r = Expedition(pack: sample(), dailyKey: '2026-09-25');
      r.place(r.selected.target);
      r.place(r.selected.target);
      await store.finish(r);
      expect(store.completedMaps, 1);
      expect(store.expeditions, 1);
      expect(store.stars(GeoRegion.uk), 3);
      expect(store.records.containsKey('daily:2026-09-25'), true);
      expect(store.savedRound, null);
      r.dispose();
      store.dispose();
    },
  );
  test(
    'per-map saves migrate legacy progress and preserve other expeditions',
    () async {
      final usa = Expedition(pack: await GeoPack.load(GeoRegion.usa), seed: 2);
      final texas = usa.pack.pieces.firstWhere((p) => p.name == 'Texas');
      usa.select(texas.id);
      expect(usa.place(texas.target), isTrue);
      usa.mapZoom = 2.25;
      usa.mapCenter = const Offset(.6, .4);
      usa.trayOffset = 110;
      usa.pause();
      final legacy = usa.toJson()..['seconds'] = 42;
      SharedPreferences.setMockInitialValues({'round': jsonEncode(legacy)});
      final prefs = await SharedPreferences.getInstance();
      final store = AtlasStore(prefs);
      expect(store.savedRoundFor(GeoRegion.usa), isNotNull);
      final europe = Expedition(
        pack: await GeoPack.load(GeoRegion.europe),
        seed: 3,
      );
      final daily = Expedition(pack: usa.pack, dailyKey: '2026-09-25', seed: 4);
      await store.save(europe);
      await store.save(daily);
      final reopened = AtlasStore(await SharedPreferences.getInstance());
      final restored = await Expedition.restore(
        reopened.savedRoundFor(GeoRegion.usa)!,
      );
      expect(restored.placed, {texas.id});
      expect(restored.seconds, 42);
      expect(restored.mapZoom, 2.25);
      expect(restored.mapCenter, const Offset(.6, .4));
      expect(restored.trayOffset, 110);
      expect(restored.lastPlaced?.id, texas.id);
      expect(reopened.savedRoundFor(GeoRegion.europe), isNotNull);
      expect(
        reopened.savedRoundFor(GeoRegion.usa, dailyKey: '2026-09-25'),
        isNotNull,
      );
      while (!daily.complete) {
        expect(daily.place(daily.selected.rings.first.first), isTrue);
      }
      await reopened.finish(daily);
      expect(
        reopened.savedRoundFor(GeoRegion.usa, dailyKey: '2026-09-25'),
        isNull,
      );
      expect(reopened.savedRoundFor(GeoRegion.usa), isNotNull);
      expect(reopened.savedRoundFor(GeoRegion.europe), isNotNull);
      await reopened.clearRound(
        saved: reopened.savedRoundFor(GeoRegion.europe),
      );
      expect(reopened.savedRoundFor(GeoRegion.usa), isNotNull);
      usa.dispose();
      europe.dispose();
      daily.dispose();
      restored.dispose();
      store.dispose();
      reopened.dispose();
    },
  );

  test('legacy saves without view state remain playable', () async {
    final r = Expedition(pack: await GeoPack.load(GeoRegion.uk));
    final saved = r.toJson()
      ..remove('view')
      ..remove('lastPlaced');
    final restored = await Expedition.restore(jsonEncode(saved));
    expect(restored.mapZoom, isNull);
    expect(restored.mapCenter, isNull);
    restored.resume();
    expect(restored.place(restored.selected.target), isTrue);
    r.dispose();
    restored.dispose();
  });

  test('daily selection ignores time of day and is repeatable', () {
    expect(
      dailySeed(DateTime(2026, 9, 25, 3)),
      dailySeed(DateTime(2026, 9, 25, 20)),
    );
    expect(
      dailyRegion(DateTime(2026, 9, 25, 3)),
      dailyRegion(DateTime(2026, 9, 25, 20)),
    );
  });
}
