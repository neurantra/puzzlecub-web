import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:fill_the_jar/services/pack_purchases.dart';
import 'package:fill_the_jar/ui/purchase_themes_sheet.dart';
import 'widget_test.dart' show session;

class FakeBilling implements PackBilling {
  Set<String> owned = {};
  Object? error;
  int buys = 0;
  Completer<Set<String>>? pending;
  late void Function(Set<String>) updated;
  @override
  Future<void> configure(void Function(Set<String>) cb) async {
    updated = cb;
  }

  @override
  Future<Set<String>> access() async {
    if (error != null) throw error!;
    return owned;
  }

  @override
  Future<Map<String, String>> prices() async => {
    'animals': '€1.99',
    'vehicles': '€1.99',
    'landscapes': '€1.99',
    'all': '€4.99',
  };
  @override
  Future<Set<String>> buy(String pack) async {
    buys++;
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    return owned = {...owned, pack};
  }

  @override
  Future<Set<String>> restore() => access();
  @override
  void dispose() {}
}

void main() {
  test(
    'purchase after level ten unlocks eleven on purchase and relaunch',
    () async {
      final free = session(freePlayLimited: true)..unlocked = 10;
      free.completed.add(free.levels[9].key);
      final snapshot = free.encode();
      free.updatePaidAccess({'animals'});
      expect(free.unlocked, 11);
      final restored = session(freePlayLimited: true)
        ..updatePaidAccess({'animals'})
        ..restore(snapshot);
      expect(restored.unlocked, 11);
    },
  );
  test(
    'individual packs grant only their pictures, all grant future packs',
    () async {
      final game = session(freePlayLimited: true);
      final billing = FakeBilling();
      final store = PackPurchases(game, billing);
      await store.refresh();
      await store.buy('animals');
      expect(game.freePlayLimited, isFalse);
      expect(game.selectPictureTheme('tiger'), isTrue);
      expect(game.selectPictureTheme('vintage-train'), isFalse);
      expect(game.unlockPicturePack('vehicles'), isFalse);
      await store.buy('vehicles');
      expect(game.selectPictureTheme('vintage-train'), isTrue);
      await store.buy('landscapes');
      expect(game.hasPaidPack('all'), isFalse);
      expect(game.hasPaidPack('future-pack'), isFalse);
      await store.buy('all');
      expect(game.hasPaidPack('future-pack'), isTrue);
      final count = billing.buys;
      await store.buy('animals');
      expect(billing.buys, count);
      expect(game.coins, 60);
    },
  );
  test(
    'restore, revocation, offline failure and local saves do not fabricate access',
    () async {
      final game = session(freePlayLimited: true);
      final billing = FakeBilling()..owned = {'vehicles'};
      final store = PackPurchases(game, billing);
      await store.refresh();
      game.unlocked = 40;
      game.load(game.levels[39]);
      game.selectPictureTheme('vintage-train');
      final restored = session(freePlayLimited: true)
        ..updatePaidAccess({'vehicles'})
        ..restore(game.encode());
      expect(restored.puzzle.number, 40);
      expect(restored.activePictureTheme, 'vintage-train');
      final localOnly = session(freePlayLimited: true)..restore(game.encode());
      expect(localOnly.freePlayLimited, isTrue);
      billing.error = Exception('offline');
      await store.refresh();
      expect(game.hasPaidPack('vehicles'), isTrue);
      billing.error = null;
      billing.owned = {};
      await store.restore();
      expect(game.freePlayLimited, isTrue);
      expect(game.puzzle.number, 10);
      expect(game.activePictureTheme, isNull);
    },
  );
  test(
    'cancelled and pending payments grant nothing; duplicates are blocked',
    () async {
      final game = session(freePlayLimited: true);
      final billing = FakeBilling();
      final store = PackPurchases(game, billing);
      await store.refresh();
      for (final code in [
        PurchasesErrorCode.purchaseCancelledError,
        PurchasesErrorCode.paymentPendingError,
      ]) {
        billing.error = PlatformException(code: '${code.index}');
        await store.buy('animals');
        expect(game.freePlayLimited, isTrue);
        expect(game.rewardBusy, isFalse);
        expect(store.busy, isFalse);
      }
      billing.error = null;
      billing.pending = Completer<Set<String>>();
      final action = store.buy('animals');
      final count = billing.buys;
      await store.buy('animals');
      expect(billing.buys, count);
      billing.pending!.complete({'animals'});
      await action;
      expect(game.hasPaidPack('animals'), isTrue);
    },
  );
  test(
    'an active bundle entitlement grants future packs, grouped legacy entitlement grants none',
    () {
      EntitlementInfo ent(String id) => EntitlementInfo(
        id,
        true,
        false,
        '2026-09-29',
        '2026-09-29',
        'com.fillthejar.packs.all',
        false,
      );
      CustomerInfo info(
        Map<String, EntitlementInfo> active, {
        VerificationResult verified = VerificationResult.verified,
      }) => CustomerInfo(
        EntitlementInfos(active, active, verification: verified),
        {},
        [],
        [],
        [],
        '2026-09-29',
        'anonymous',
        {},
        '2026-09-29',
      );
      expect(
        RevenueCatBilling.accessFrom(
          info({'animals': ent('animals'), 'vehicles': ent('vehicles')}),
        ),
        {'animals', 'vehicles'},
      );
      expect(
        RevenueCatBilling.accessFrom(
          info({
            PackProducts.bundleEntitlement: ent(PackProducts.bundleEntitlement),
          }),
        ),
        {'all'},
      );
      expect(
        RevenueCatBilling.accessFrom(
          info({
            'Fill the Jar - Individual Packs': ent(
              'Fill the Jar - Individual Packs',
            ),
          }),
        ),
        isEmpty,
      );
      expect(
        () => RevenueCatBilling.accessFrom(
          info({}, verified: VerificationResult.failed),
        ),
        throwsStateError,
      );
    },
  );
  testWidgets('store back button clears Android navigation and dismisses', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(864, 1928);
    tester.view.devicePixelRatio = 2.25;
    tester.view.padding = FakeViewPadding(bottom: 110);
    addTearDown(tester.view.reset);
    final game = session(freePlayLimited: true);
    final store = PackPurchases(game, FakeBilling()..owned = {'all'});
    await store.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .88,
                  ),
                  child: PurchaseThemesSheet(game: game, purchases: store),
                ),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open store'));
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: find.byType(PurchaseThemesSheet),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    final button = find.widgetWithText(TextButton, 'Back to puzzle');
    final safeBottom = (1928 - 110) / 2.25;
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(safeBottom));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseThemesSheet), findsNothing);
    expect(tester.takeException(), isNull);
    store.dispose();
    game.dispose();
  });
  testWidgets(
    'store uses localized prices and switches to owned after purchase',
    (tester) async {
      final game = session(freePlayLimited: true);
      final store = PackPurchases(game, FakeBilling());
      await store.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurchaseThemesSheet(game: game, purchases: store),
          ),
        ),
      );
      expect(find.text('Buy All Packs · €4.99'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('buy-all')));
      await tester.pumpAndSettle();
      expect(game.hasPaidPack('all'), isTrue);
      expect(find.text('Buy All Packs · €4.99'), findsNothing);
      expect(find.text('✓ Purchased'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
