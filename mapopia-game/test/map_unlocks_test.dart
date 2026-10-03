import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapopia/services/map_unlocks.dart';
import 'package:mapopia/services/atlas_commerce.dart';
import 'package:mapopia/geo/domain/geo_region.dart';
import 'support/fake_billing.dart';

class MemoryRecovery implements RecoveryStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String v) async {
    value = v;
  }
}

class FakeRemote implements UnlockRemote {
  @override
  bool configured = true;
  bool offline = false, loseResponse = false;
  int credits = 0, purchases = 0;
  final maps = <String>{};
  final requests = <String>{};
  Map<String, dynamic> state() => {
    'customerId': 'mp_test',
    'maps': maps.toList(),
    'credits': credits,
    'qualifyingPurchase': purchases > 0,
  };
  @override
  Future<Map<String, dynamic>> call(
    String path, {
    String? code,
    Map<String, dynamic>? body,
  }) async {
    if (offline) throw StateError('offline');
    if (path == 'create') return {...state(), 'code': 'TEST-CODE'};
    if (code != 'TEST-CODE') {
      throw const UnlockFailure('Recovery code not found.');
    }
    if (path == 'redeem') {
      final id = body!['requestId'] as String;
      if (!requests.contains(id)) {
        if (credits < 2) throw const UnlockFailure('No credits');
        credits -= 2;
        maps.addAll((body['maps'] as List).cast<String>());
        requests.add(id);
      }
      if (loseResponse) {
        loseResponse = false;
        throw StateError('response lost');
      }
    }
    return state();
  }
}

class FakeUnlockBilling implements UnlockBilling {
  FakeUnlockBilling(this.remote);
  final FakeRemote remote;
  String? identity;
  int pairCalls = 0, upgradeCalls = 0;
  bool cancel = false;
  String? errorCode;
  @override
  Future<void> identify(String id) async {
    identity = id;
  }

  @override
  Future<Map<String, String>> prices() async => {
    twoMapProduct: '€0.99',
    upgradeProduct: '€2.99',
  };
  @override
  Future<void> purchasePair() async {
    pairCalls++;
    if (errorCode != null) throw PlatformException(code: errorCode!);
    if (cancel) throw PlatformException(code: '1');
    remote.credits += 2;
    remote.purchases++;
  }

  @override
  Future<bool> purchaseUpgrade() async {
    upgradeCalls++;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeRemote remote;
  late MemoryRecovery storage;
  late FakeUnlockBilling billing;
  late MapUnlocks u;
  test(
    'unavailable product allows retry; uncertain payment retains selection',
    () async {
      await u.create();
      await u.confirmSavedCode();
      await u.refreshPrices();
      billing.errorCode = '5';
      await u.buyPair([GeoRegion.usa, GeoRegion.india]);
      expect(u.pending, isFalse);
      billing.errorCode = '10';
      await u.buyPair([GeoRegion.usa, GeoRegion.india]);
      expect(u.pending, isTrue);
      expect(remote.credits, 0);
      final calls = billing.pairCalls;
      await u.buyPair([GeoRegion.uk, GeoRegion.japan]);
      expect(billing.pairCalls, calls);
    },
  );
  setUp(() {
    remote = FakeRemote();
    storage = MemoryRecovery();
    billing = FakeUnlockBilling(remote);
    u = MapUnlocks(remote: remote, storage: storage, billing: billing);
  });
  tearDown(() => u.dispose());
  Future<void> ready() async {
    await u.create();
    await u.confirmSavedCode();
    await u.refreshPrices();
  }

  test(
    'no purchase before recovery code is saved; code is not store identity',
    () async {
      await u.create();
      await u.buyPair([GeoRegion.india, GeoRegion.usa]);
      expect(billing.pairCalls, 0);
      expect(billing.identity, 'mp_test');
      expect(u.code, isNot(billing.identity));
    },
  );
  test('repeat pair purchases and flat loyalty upgrade', () async {
    await ready();
    await u.buyPair([GeoRegion.india, GeoRegion.usa]);
    await u.buyPair([GeoRegion.uk, GeoRegion.europe]);
    expect(u.maps.length, 4);
    expect(billing.pairCalls, 2);
    expect(u.upgradePrice, '€2.99');
    expect(u.loyalty, true);
    expect(await u.buyUpgrade(), true);
  });
  test(
    'lost redemption response resumes without second payment after restart',
    () async {
      await ready();
      remote.loseResponse = true;
      await u.buyPair([GeoRegion.india, GeoRegion.usa]);
      expect(u.pending, true);
      final restarted = MapUnlocks(
        remote: remote,
        storage: storage,
        billing: billing,
      );
      await restarted.initialize();
      expect(restarted.maps, {GeoRegion.india, GeoRegion.usa});
      expect(restarted.pending, false);
      expect(billing.pairCalls, 1);
      restarted.dispose();
    },
  );
  test(
    'recovery on clean device restores chosen maps and eligibility',
    () async {
      await ready();
      await u.buyPair([GeoRegion.india, GeoRegion.usa]);
      final other = MapUnlocks(
        remote: remote,
        storage: MemoryRecovery(),
        billing: FakeUnlockBilling(remote),
      );
      await other.recover('TEST-CODE');
      expect(other.maps, u.maps);
      expect(other.loyalty, true);
      other.dispose();
    },
  );
  test(
    'offline reload retains maps; invalid code never replaces collection',
    () async {
      await ready();
      await u.buyPair([GeoRegion.india, GeoRegion.usa]);
      await u.recover('wrong');
      expect(u.code, 'TEST-CODE');
      remote.offline = true;
      final other = MapUnlocks(
        remote: remote,
        storage: storage,
        billing: billing,
      );
      await other.initialize();
      expect(other.maps.length, 2);
      other.dispose();
    },
  );
  test('cancel never unlocks or leaves pending checkout', () async {
    await ready();
    billing.cancel = true;
    await u.buyPair([GeoRegion.india, GeoRegion.usa]);
    expect(u.maps, isEmpty);
    expect(u.pending, false);
    expect(u.loyalty, false);
  });
  test('invalid selections and upgrade before purchase never charge', () async {
    await ready();
    for (final pair in [
      [GeoRegion.india, GeoRegion.india],
      [GeoRegion.australia, GeoRegion.usa],
    ]) {
      await u.buyPair(pair);
    }
    expect(billing.pairCalls, 0);
    expect(await u.buyUpgrade(), false);
    expect(billing.upgradeCalls, 0);
  });
  test(
    'paid credits from interrupted checkout can be assigned without a new charge',
    () async {
      await ready();
      remote.credits = 2;
      remote.purchases = 1;
      await u.buyPair([GeoRegion.india, GeoRegion.usa]);
      expect(billing.pairCalls, 0);
      expect(u.maps.length, 2);
    },
  );
  test(
    'refund sync removes maps and loyalty; normal trial remains consumed',
    () async {
      SharedPreferences.setMockInitialValues({});
      final c = AtlasCommerce(
        await SharedPreferences.getInstance(),
        billing: FakeBilling(),
        unlocks: u,
      );
      await c.recordTrialProgress(GeoRegion.uk, {'a', 'b'}, 4);
      await ready();
      await u.buyPair([GeoRegion.india, GeoRegion.usa]);
      expect(c.allows(GeoRegion.india), true);
      expect(c.adFree(GeoRegion.india), true);
      expect(c.adFree(GeoRegion.australia), false);
      expect(c.canOpen(GeoRegion.europe), false);
      remote.maps.clear();
      remote.purchases = 0;
      await u.sync();
      expect(c.allows(GeoRegion.india), false);
      expect(u.loyalty, false);
      expect(c.trialExhausted, true);
      // Ownership is stored as verified snapshot, not derived from a consumable entitlement.
      expect(jsonDecode(storage.value!)['record']['maps'], isEmpty);
    },
  );
}
