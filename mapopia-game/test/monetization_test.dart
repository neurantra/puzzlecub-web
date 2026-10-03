import 'dart:async';
import 'support/fake_billing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapopia/services/atlas_commerce.dart';
import 'package:mapopia/services/atlas_ads.dart';
import 'package:mapopia/services/family_games.dart';
import 'package:mapopia/geo/domain/geo_region.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeBilling billing;
  late AtlasCommerce commerce;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    billing = FakeBilling();
    commerce = AtlasCommerce(
      await SharedPreferences.getInstance(),
      billing: billing,
    );
  });
  tearDown(() => commerce.dispose());

  test(
    'any map can be chosen initially; Australia and paid maps are unlimited',
    () async {
      expect(commerce.trialLimit(50), 17);
      expect(commerce.trialLimit(30), 10);
      expect(commerce.trialLimit(4), 2);
      for (final region in GeoRegion.values) {
        expect(commerce.canPlace(region, 0, 50), true);
        expect(commerce.canPlace(region, 16, 50), true);
        expect(
          commerce.canPlace(region, 17, 50),
          region == GeoRegion.australia,
        );
      }
      await commerce.initialize();
      await commerce.buy();
      for (final region in GeoRegion.values) {
        expect(commerce.canPlace(region, 49, 50), true);
      }
    },
  );

  test(
    'one selected trial persists across reopening and blocks other paid maps',
    () async {
      await commerce.recordTrialProgress(GeoRegion.india, {'a'}, 6);
      expect(commerce.canOpen(GeoRegion.india), true);
      expect(commerce.canOpen(GeoRegion.usa), false);
      final reopened = AtlasCommerce(commerce.prefs, billing: FakeBilling());
      expect(reopened.trialRegion, GeoRegion.india);
      expect(reopened.canOpen(GeoRegion.usa), false);
      await reopened.recordTrialProgress(GeoRegion.india, {'b'}, 6);
      final exhausted = AtlasCommerce(commerce.prefs, billing: FakeBilling());
      expect(exhausted.trialExhausted, true);
      for (final region in GeoRegion.values) {
        expect(
          exhausted.canPlace(region, 0, 50),
          region == GeoRegion.australia,
        );
      }
      reopened.dispose();
      exhausted.dispose();
    },
  );

  test('replaying pieces and changing rounds never refill the trial', () async {
    await commerce.recordTrialProgress(GeoRegion.usa, {'a'}, 9);
    await commerce.recordTrialProgress(GeoRegion.usa, {'a'}, 9);
    expect(commerce.trialExhausted, false);
    await commerce.recordTrialProgress(GeoRegion.usa, {'b'}, 9);
    expect(commerce.trialExhausted, false);
    await commerce.recordTrialProgress(GeoRegion.usa, {'c'}, 9);
    expect(commerce.trialExhausted, true);
    await commerce.recordTrialProgress(GeoRegion.usa, {}, 9);
    expect(commerce.canPlace(GeoRegion.usa, 0, 9), false);
  });

  test(
    'Australia does not consume the trial and buying still unlocks everything',
    () async {
      await commerce.recordTrialProgress(GeoRegion.australia, {
        'a',
        'b',
        'c',
      }, 3);
      expect(commerce.trialRegion, isNull);
      await commerce.recordTrialProgress(GeoRegion.uk, {'a', 'b'}, 4);
      expect(commerce.trialExhausted, true);
      await commerce.initialize();
      await commerce.buy();
      for (final region in GeoRegion.values) {
        expect(commerce.canPlace(region, 0, 50), true);
      }
      expect(commerce.trialExhausted, true);
    },
  );
  test('Australia is the only free map; store price is localized', () async {
    await commerce.initialize();
    expect(GeoRegion.values.where(commerce.allows), [GeoRegion.australia]);
    expect(commerce.price, '€4.99');
  });
  test(
    'pending purchase never unlocks; verified purchase persists and restores offline',
    () async {
      await commerce.initialize();
      billing.pending = Completer();
      final purchase = commerce.buy();
      expect(commerce.busy, true);
      expect(commerce.fullAtlas, false);
      billing.pending!.complete(true);
      await purchase;
      expect(commerce.fullAtlas, true);
      final offline = AtlasCommerce(
        commerce.prefs,
        billing: FakeBilling()..error = StateError('offline'),
      );
      await offline.initialize();
      expect(offline.fullAtlas, true);
      offline.dispose();
    },
  );
  test(
    'restore grants only confirmed ownership and handles no purchase',
    () async {
      await commerce.initialize();
      billing.result = false;
      await commerce.restore();
      expect(commerce.fullAtlas, false);
      expect(commerce.message, contains('No Full Atlas'));
      billing.result = true;
      await commerce.restore();
      expect(commerce.fullAtlas, true);
    },
  );
  test('cancellation and network failure never grant access', () async {
    await commerce.initialize();
    billing.error = PlatformException(code: '1');
    await commerce.buy();
    expect(commerce.fullAtlas, false);
    expect(commerce.message, isNull);
    billing.error = PlatformException(code: 'network');
    await commerce.buy();
    expect(commerce.fullAtlas, false);
    expect(commerce.message, isNotNull);
  });
  test(
    'ownership updates revoke access and purchases suppress ads immediately',
    () async {
      final ads = AtlasAds(commerce)..ready = true;
      await commerce.initialize();
      await commerce.buy();
      expect(ads.eligible, false);
      expect(ads.rewardReady, false);
      billing.changed!(false);
      await Future<void>.delayed(Duration.zero);
      expect(commerce.fullAtlas, false);
      expect(commerce.allows(GeoRegion.india), false);
      ads.dispose();
    },
  );
  test('unconfigured store cannot sell or fake an unlock', () async {
    billing.available = false;
    await commerce.refreshPrice();
    await commerce.buy();
    expect(commerce.ready, false);
    expect(commerce.fullAtlas, false);
    expect(commerce.price, isNull);
  });
  test(
    'interstitials skip first completion and respect recent rewarded ads',
    () {
      final policy = AdBreakPolicy();
      final now = DateTime(2026);
      expect(policy.takeBreak(now), false);
      expect(policy.takeBreak(now), true);
      policy.lastFullscreen = now;
      expect(policy.takeBreak(now.add(const Duration(seconds: 5))), false);
      expect(policy.takeBreak(now.add(const Duration(seconds: 10))), false);
      expect(policy.takeBreak(now.add(const Duration(minutes: 4))), false);
      expect(policy.takeBreak(now.add(const Duration(minutes: 5))), true);
    },
  );
  test('family links target each platform store and all four games', () {
    expect(FamilyGame.values.length, 4);
    for (final game in FamilyGame.values) {
      expect(
        game.link(TargetPlatform.android).queryParameters['id'],
        game.package,
      );
      expect(game.link(TargetPlatform.iOS).path, '/app/id${game.appleId}');
    }
  });
}
