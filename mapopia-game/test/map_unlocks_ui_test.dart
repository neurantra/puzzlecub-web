import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapopia/services/atlas_commerce.dart';
import 'package:mapopia/services/map_unlocks.dart';
import 'package:mapopia/ui/map_unlocks_sheet.dart';
import 'package:mapopia/ui/theme.dart';
import 'package:mapopia/geo/domain/geo_region.dart';
import 'map_unlocks_test.dart'
    show FakeRemote, FakeUnlockBilling, MemoryRecovery;
import 'support/fake_billing.dart';
import 'experience_test.dart' show fonts;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(fonts);
  testWidgets(
    'pair chooser requires two maps and grants only the selected pair',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final remote = FakeRemote(), storage = MemoryRecovery();
      final billing = FakeUnlockBilling(remote);
      final unlocks = MapUnlocks(
        remote: remote,
        storage: storage,
        billing: billing,
      );
      final commerce = AtlasCommerce(
        await SharedPreferences.getInstance(),
        billing: FakeBilling(),
        unlocks: unlocks,
      );
      await unlocks.create();
      await unlocks.confirmSavedCode();
      await unlocks.refreshPrices();
      await tester.pumpWidget(
        MaterialApp(
          theme: atlasTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showMapPairs(context, commerce),
                child: const Text('Choose maps'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choose maps'));
      await tester.pumpAndSettle();
      expect(find.text('Australia'), findsNothing);
      await tester.tap(find.byType(CheckboxListTile).at(0));
      await tester.pump();
      expect(find.text('1 of 2 selected'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile).at(1));
      await tester.pump();
      final third = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).at(2),
      );
      expect(third.onChanged, isNull);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../docs/screenshots/map-pairs.png'),
      );
      await tester.ensureVisible(find.text('Unlock two maps · €0.99'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock two maps · €0.99'));
      await tester.pumpAndSettle();
      expect(billing.pairCalls, 1);
      expect(unlocks.maps.length, 2);
      expect(unlocks.loyalty, isTrue);
      expect(commerce.fullAtlas, isFalse);
      for (final r in unlocks.maps) {
        expect(commerce.adFree(r), isTrue);
      }
      expect(commerce.adFree(GeoRegion.australia), isFalse);
      await tester.pumpWidget(const SizedBox());
      commerce.dispose();
    },
  );

  testWidgets(
    'recovery code must be acknowledged before checkout can continue',
    (tester) async {
      final remote = FakeRemote();
      final unlocks = MapUnlocks(
        remote: remote,
        storage: MemoryRecovery(),
        billing: FakeUnlockBilling(remote),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: atlasTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showRecovery(context, unlocks),
                child: const Text('Recovery'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Recovery'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create my recovery code'));
      await tester.pumpAndSettle();
      expect(find.text('TEST-CODE'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('I saved my code outside this app'));
      await tester.tap(find.text('I saved my code outside this app'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(unlocks.savedCode, isTrue);
      await tester.pumpWidget(const SizedBox());
      unlocks.dispose();
    },
  );
}
