import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/data/maze_pack.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/ui/language_store_screen.dart';
import 'package:maze_words/services/game_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maze_words/services/purchases/purchase_catalog.dart';
import 'package:maze_words/services/purchases/purchase_service.dart';

class FakeGateway implements PurchaseGateway {
  PurchaseAccess access = PurchaseAccess([]);
  final calls = <String>[];
  bool offline = false;
  Completer<PurchaseAccess>? purchase;
  @override
  Future<void> initialize(void Function(PurchaseAccess) update) async =>
      update(access);
  @override
  Future<List<PurchaseListing>> products() async => PurchaseTier.values
      .map((p) => PurchaseListing(p.productId, 'store price'))
      .toList();
  @override
  Future<PurchaseAccess> refresh() async {
    if (offline) throw StateError('offline');
    return access;
  }

  @override
  Future<PurchaseAccess> buy(String productId) async {
    calls.add(productId);
    if (purchase != null) return purchase!.future;
    final tier = PurchaseTier.values.singleWhere(
      (p) => p.productId == productId,
    );
    return access = PurchaseAccess([...access.active, tier.entitlementId]);
  }

  @override
  Future<PurchaseAccess> restore() async => access;
  @override
  void dispose() {}
}

void main() {
  Future<PlayerStore> player() async {
    SharedPreferences.setMockInitialValues({});
    final store = PlayerStore(await SharedPreferences.getInstance());
    await store.setBirthYear(1990);
    return store;
  }

  test(
    'free choice is fixed; paid choices survive service recreation and restore',
    () async {
      final store = await player();
      final gateway = FakeGateway();
      final service = PurchaseService(gateway, store: store);
      await service.chooseFreeLanguage('ta');
      expect(service.mazeLimit('ta'), 10);
      expect(service.mazeLimit('en'), 0);
      await expectLater(service.chooseFreeLanguage('en'), throwsStateError);
      await service.buy(PurchaseTier.first, language: 'ta');
      expect(service.mazeLimit('ta'), 150);
      await expectLater(
        service.buy(PurchaseTier.second, language: 'ta'),
        throwsStateError,
      );
      await service.buy(PurchaseTier.second, language: 'hi');
      expect(service.mazeLimit('hi'), 150);
      final restored = PurchaseService(gateway, store: store);
      await restored.restore();
      expect(restored.languageFor(PurchaseTier.first), 'ta');
      expect(restored.languageFor(PurchaseTier.second), 'hi');
      gateway.access = PurchaseAccess([]);
      await restored.restore();
      expect(restored.mazeLimit('ta'), 10);
      expect(restored.mazeLimit('hi'), 0);
      service.dispose();
      restored.dispose();
    },
  );
  test(
    'restored empty language slot can be assigned once without checkout',
    () async {
      final store = await player();
      final gateway = FakeGateway()
        ..access = PurchaseAccess([PurchaseTier.first.entitlementId]);
      final service = PurchaseService(gateway, store: store);
      await service.restore();
      await service.selectRestoredLanguage(PurchaseTier.first, 'nl');
      expect(service.mazeLimit('nl'), 150);
      expect(gateway.calls, isEmpty);
      await expectLater(
        service.selectRestoredLanguage(PurchaseTier.first, 'it'),
        throwsStateError,
      );
      service.dispose();
    },
  );
  test(
    'free play truncates to 10 distinct boards and rejects other languages',
    () async {
      final store = await player();
      final service = PurchaseService(FakeGateway(), store: store);
      await service.chooseFreeLanguage('en');
      final pack = await MazePackLoader.load(MazeLevel.easy);
      expect(service.playablePack('en', pack).mazes.length, 10);
      expect(pack.mazes.length, greaterThan(10));
      expect(() => service.playablePack('ta', pack), throwsStateError);
      service.dispose();
    },
  );
  test(
    'free ownership enables configured ad formats; restore suppresses them',
    () async {
      final store = await player();
      final gateway = FakeGateway();
      final purchases = PurchaseService(gateway, store: store);
      final game = GameServices(store, purchaseService: purchases);
      await purchases.initialize();
      game.adsReady = true;
      expect(game.rewardedReady, GameServices.rewardsEnabled);
      expect(game.bannerReady, GameServices.bannersEnabled);
      for (var round = 1; round <= 3; round++) {
        await store.record(
          level: MazeLevel.easy,
          relaxed: true,
          score: 100,
          found: 3,
          cleared: true,
        );
        expect(store.interstitialDue, round == 3);
      }
      gateway.access = PurchaseAccess([PurchaseTier.first.entitlementId]);
      await purchases.restore();
      expect(game.rewardedReady, false);
      expect(game.bannerReady, false);
      await game.afterRound();
      expect(
        store.interstitialDue,
        true,
        reason: 'Paid players never enter the ad break path.',
      );
      expect(await game.bonusAd(), false);
      game.dispose();
    },
  );
  test('paid ownership suppresses every ad entry point', () async {
    final store = await player();
    final gateway = FakeGateway()
      ..access = PurchaseAccess([PurchaseTier.all.entitlementId]);
    final service = PurchaseService(gateway, store: store);
    final game = GameServices(store, purchaseService: service);
    await service.initialize();
    game.adsReady = true;
    expect(game.bannerReady, false);
    expect(game.rewardedReady, false);
    expect(await game.bonusAd(), false);
    await game.afterRound();
    game.dispose();
  });
  testWidgets('store locks both add-ons; restore first enables both buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await player();
    final gateway = FakeGateway();
    final service = PurchaseService(gateway, store: store);
    await tester.pumpWidget(
      MaterialApp(
        home: LanguageStoreScreen(store: store, purchases: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Requires First Language'), findsNWidgets(2));
    final locked = tester.widgetList<FilledButton>(
      find.widgetWithText(FilledButton, 'Buy First Language first'),
    );
    expect(locked.every((button) => button.onPressed == null), true);
    gateway.access = PurchaseAccess([PurchaseTier.first.entitlementId]);
    await service.restore();
    await tester.pumpAndSettle();
    expect(find.text('Requires First Language'), findsNothing);
    expect(find.text('Choose restored language'), findsOneWidget);
    expect(
      tester
          .widgetList<FilledButton>(
            find.widgetWithText(FilledButton, 'Unlock · store price'),
          )
          .every((button) => button.onPressed != null),
      true,
    );
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });

  test('both add-ons require first; all does not require second', () {
    final free = PurchaseAccess([]);
    expect(free.canBuy(PurchaseTier.first), true);
    expect(free.canBuy(PurchaseTier.second), false);
    expect(free.canBuy(PurchaseTier.all), false);
    final first = PurchaseAccess([PurchaseTier.first.entitlementId]);
    expect(first.canBuy(PurchaseTier.first), false);
    expect(first.canBuy(PurchaseTier.second), true);
    expect(first.canBuy(PurchaseTier.all), true);
    final all = PurchaseAccess([
      PurchaseTier.first.entitlementId,
      PurchaseTier.all.entitlementId,
    ]);
    expect(PurchaseTier.values.any(all.canBuy), false);
  });
  test(
    'any active paid entitlement removes ads, including restored all access',
    () {
      expect(PurchaseAccess([]).adFree, false);
      for (final tier in PurchaseTier.values) {
        expect(PurchaseAccess([tier.entitlementId]).adFree, true);
      }
      expect(PurchaseAccess(['unrelated']).adFree, false);
    },
  );
  test(
    'checkout blocks both add-ons without first, not just their buttons',
    () async {
      final gateway = FakeGateway();
      final service = PurchaseService(gateway);
      await service.initialize();
      for (final tier in [PurchaseTier.second, PurchaseTier.all]) {
        expect(service.canBuy(tier), false);
        await expectLater(service.buy(tier), throwsStateError);
      }
      expect(gateway.calls, isEmpty);
      service.dispose();
    },
  );
  test(
    'fresh ownership revocation blocks a previously enabled checkout',
    () async {
      final gateway = FakeGateway()
        ..access = PurchaseAccess([PurchaseTier.first.entitlementId]);
      final service = PurchaseService(gateway);
      await service.initialize();
      expect(service.canBuy(PurchaseTier.all), true);
      gateway.access = PurchaseAccess([]);
      await expectLater(service.buy(PurchaseTier.all), throwsStateError);
      expect(gateway.calls, isEmpty);
      expect(service.access.adFree, false);
      service.dispose();
    },
  );
  test('first then all succeeds without buying second', () async {
    final gateway = FakeGateway();
    final service = PurchaseService(gateway);
    await service.buy(PurchaseTier.first);
    await service.buy(PurchaseTier.all);
    expect(gateway.calls, [
      PurchaseTier.first.productId,
      PurchaseTier.all.productId,
    ]);
    expect(service.access.owns(PurchaseTier.all), true);
    expect(service.canBuy(PurchaseTier.second), false);
    service.dispose();
  });
  test(
    'offline preflight never opens checkout; restore enables prerequisites',
    () async {
      final gateway = FakeGateway()..offline = true;
      final service = PurchaseService(gateway);
      await expectLater(service.buy(PurchaseTier.first), throwsStateError);
      expect(gateway.calls, isEmpty);
      gateway.access = PurchaseAccess([PurchaseTier.first.entitlementId]);
      await service.restore();
      expect(service.canBuy(PurchaseTier.second), true);
      service.dispose();
    },
  );
  test('duplicate purchase attempts cannot open two store sheets', () async {
    final gateway = FakeGateway()..purchase = Completer<PurchaseAccess>();
    final service = PurchaseService(gateway);
    final buying = service.buy(PurchaseTier.first);
    await expectLater(service.buy(PurchaseTier.first), throwsStateError);
    gateway.purchase!.complete(
      PurchaseAccess([PurchaseTier.first.entitlementId]),
    );
    await buying;
    expect(gateway.calls, hasLength(1));
    expect(service.busy, false);
    service.dispose();
  });
}
