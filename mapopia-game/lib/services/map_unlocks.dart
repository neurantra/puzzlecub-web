import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';
import '../geo/domain/geo_region.dart';

const twoMapProduct = 'com.mapopia.app.two_map_unlocks';
const upgradeProduct = 'com.mapopia.app.full_atlas_upgrade';

class UnlockRecord {
  const UnlockRecord({
    required this.customerId,
    this.maps = const {},
    this.credits = 0,
    this.qualifyingPurchase = false,
  });
  final String customerId;
  final Set<GeoRegion> maps;
  final int credits;
  final bool qualifyingPurchase;
  factory UnlockRecord.fromJson(Map<String, dynamic> json) => UnlockRecord(
    customerId: json['customerId'] as String,
    maps: (json['maps'] as List)
        .map((v) => GeoRegion.values.byName(v as String))
        .toSet(),
    credits: json['credits'] as int,
    qualifyingPurchase: json['qualifyingPurchase'] == true,
  );
  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'maps': maps.map((v) => v.name).toList(),
    'credits': credits,
    'qualifyingPurchase': qualifyingPurchase,
  };
}

abstract interface class UnlockRemote {
  bool get configured;
  Future<Map<String, dynamic>> call(
    String path, {
    String? code,
    Map<String, dynamic>? body,
  });
}

class HttpUnlockRemote implements UnlockRemote {
  static const url = String.fromEnvironment('MAPOPIA_PURCHASES_URL');
  @override
  bool get configured => Uri.tryParse(url)?.scheme == 'https';
  @override
  Future<Map<String, dynamic>> call(
    String path, {
    String? code,
    Map<String, dynamic>? body,
  }) async {
    if (!configured) throw StateError('Map recovery is not available yet.');
    final response = await http
        .post(
          Uri.parse('${url.replaceAll(RegExp(r'/$'), '')}/$path'),
          headers: {
            'Content-Type': 'application/json',
            if (code != null) 'Authorization': 'Bearer $code',
          },
          body: jsonEncode(body ?? {}),
        )
        .timeout(const Duration(seconds: 20));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw UnlockFailure(data['error'] as String? ?? 'Please try again.');
    }
    return data;
  }
}

class UnlockFailure implements Exception {
  const UnlockFailure(this.message);
  final String message;
}

abstract interface class RecoveryStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureRecoveryStorage implements RecoveryStorage {
  static const storage = FlutterSecureStorage();
  static const key = 'mapopia.recovery.v1';
  @override
  Future<String?> read() => storage.read(key: key);
  @override
  Future<void> write(String value) => storage.write(key: key, value: value);
}

abstract interface class UnlockBilling {
  Future<void> identify(String customerId);
  Future<Map<String, String>> prices();
  Future<void> purchasePair();
  Future<bool> purchaseUpgrade();
}

class RevenueCatUnlockBilling implements UnlockBilling {
  final Map<String, StoreProduct> _products = {};
  @override
  Future<void> identify(String customerId) async {
    await Purchases.logIn(customerId);
  }

  @override
  Future<Map<String, String>> prices() async {
    final products = await Purchases.getProducts([
      twoMapProduct,
      upgradeProduct,
    ], productCategory: ProductCategory.nonSubscription);
    _products.clear();
    for (final p in products) {
      _products[p.identifier] = p;
    }
    return _products.map((id, p) => MapEntry(id, p.priceString));
  }

  StoreProduct _product(String id) =>
      _products[id] ??
      (throw const UnlockFailure(
        'This purchase is not available. Please refresh the store.',
      ));
  @override
  Future<void> purchasePair() async {
    await Purchases.purchase(
      PurchaseParams.storeProduct(_product(twoMapProduct)),
    );
  }

  @override
  Future<bool> purchaseUpgrade() async => (await Purchases.purchase(
    PurchaseParams.storeProduct(_product(upgradeProduct)),
  )).customerInfo.entitlements.active.containsKey('full_atlas');
}

/// A recovery code is a secret, not the public RevenueCat customer identifier.
/// Only the backend webhook grants map credits; SDK success alone never does.
class MapUnlocks extends ChangeNotifier {
  MapUnlocks({
    UnlockRemote? remote,
    RecoveryStorage? storage,
    UnlockBilling? billing,
  }) : remote = remote ?? HttpUnlockRemote(),
       storage = storage ?? SecureRecoveryStorage(),
       billing = billing ?? RevenueCatUnlockBilling();
  final UnlockRemote remote;
  final RecoveryStorage storage;
  final UnlockBilling billing;
  UnlockRecord? record;
  String? code, message, pairPrice, upgradePrice;
  bool busy = false, savedCode = false, _disposed = false;
  bool get configured => remote.configured;
  bool get hasRecovery => code != null;
  bool get loyalty => record?.qualifyingPurchase ?? false;
  int get credits => record?.credits ?? 0;
  Set<GeoRegion> get maps => record?.maps ?? {};
  List<GeoRegion>? pendingMaps;
  String? _requestId;
  bool get pending => pendingMaps != null;
  bool get canBuyPair =>
      configured && savedCode && pairPrice != null && !busy && !pending;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist() => storage.write(
    jsonEncode({
      'code': code,
      'savedCode': savedCode,
      'record': record?.toJson(),
      'pendingMaps': pendingMaps?.map((r) => r.name).toList(),
      'requestId': _requestId,
    }),
  );
  Future<void> initialize() async {
    if (!configured) return;
    try {
      final raw = await storage.read();
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        code = data['code'] as String?;
        savedCode = data['savedCode'] == true;
        if (data['record'] != null) {
          record = UnlockRecord.fromJson(
            Map<String, dynamic>.from(data['record'] as Map),
          );
        }
        pendingMaps = (data['pendingMaps'] as List?)
            ?.map((r) => GeoRegion.values.byName(r as String))
            .toList();
        _requestId = data['requestId'] as String?;
      }
      if (record != null) await billing.identify(record!.customerId);
      if (hasRecovery && configured) await _sync();
    } catch (_) {
      message = 'Recovery is offline. Your saved maps remain available.';
    }
    _notify();
  }

  Future<void> refreshPrices() async {
    if (!configured) return;
    try {
      final prices = await billing.prices();
      pairPrice = prices[twoMapProduct];
      upgradePrice = prices[upgradeProduct];
    } catch (_) {
      pairPrice = null;
      upgradePrice = null;
    }
    _notify();
  }

  Future<void> _accept(Map<String, dynamic> data) async {
    record = UnlockRecord.fromJson(data);
    await _persist();
    _notify();
  }

  Future<void> _sync() async {
    if (code == null) return;
    await _accept(await remote.call('sync', code: code));
    if (pending && (credits >= 2 || pendingMaps!.every(maps.contains))) {
      await _redeem();
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    try {
      await action();
    } on UnlockFailure catch (e) {
      message = e.message;
    } on PlatformException catch (e) {
      if (int.tryParse(e.code) !=
          PurchasesErrorCode.purchaseCancelledError.index) {
        message =
            'The store could not finish. Your recovery code keeps completed purchases safe.';
      }
    } catch (_) {
      message =
          'Unable to connect. Please retry; completed purchases are kept safe.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> create() => _guard(() async {
    if (hasRecovery) return;
    final data = await remote.call('create');
    code = data['code'] as String;
    record = UnlockRecord.fromJson(data);
    // Persist before changing store identity, so interruptions cannot orphan it.
    await _persist();
    await billing.identify(record!.customerId);
  });
  Future<void> confirmSavedCode() => _guard(() async {
    savedCode = true;
    await _persist();
  });
  Future<void> recover(String value) => _guard(() async {
    final candidate = value.trim().toUpperCase();
    final data = await remote.call('recover', code: candidate);
    final next = UnlockRecord.fromJson(data);
    // Avoid silently replacing an existing collection; users can recover it
    // on a fresh install/device using its own code.
    if (record != null &&
        record!.customerId != next.customerId &&
        (loyalty || credits > 0 || maps.isNotEmpty || pending)) {
      throw const UnlockFailure(
        'This device already has a recovery code. Keep it safe; use the other code on a fresh installation or another device.',
      );
    }
    code = candidate;
    record = next;
    savedCode = true;
    await _persist();
    await billing.identify(next.customerId);
    await _sync();
    message = 'Your purchased maps are restored.';
  });
  Future<void> sync() => _guard(() async {
    await _sync();
    message = pending
        ? 'Still waiting for store confirmation. Please check again shortly; do not buy again.'
        : 'Your map collection is up to date.';
  });
  Future<void> _redeem() async {
    if (pendingMaps == null || _requestId == null) return;
    final data = await remote.call(
      'redeem',
      code: code,
      body: {
        'maps': pendingMaps!.map((r) => r.name).toList(),
        'requestId': _requestId,
      },
    );
    record = UnlockRecord.fromJson(data);
    pendingMaps = null;
    _requestId = null;
    await _persist();
    _notify();
  }

  Future<void> buyPair(List<GeoRegion> selected) => _guard(() async {
    if (!configured || !savedCode || code == null || record == null) {
      throw const UnlockFailure('Save your recovery code before purchasing.');
    }
    if (pending) {
      await _sync();
      return;
    }
    await _sync();
    if (selected.length != 2 ||
        selected.toSet().length != 2 ||
        selected.any((r) => r == GeoRegion.australia || maps.contains(r))) {
      throw const UnlockFailure('Choose two different maps you do not own.');
    }
    await billing.identify(record!.customerId);
    pendingMaps = List.of(selected);
    _requestId = List.generate(
      24,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _persist();
    if (credits < 2) {
      try {
        await billing.purchasePair();
      } on PlatformException catch (e) {
        final rejectedBeforePayment = {
          PurchasesErrorCode.purchaseCancelledError.index,
          PurchasesErrorCode.purchaseNotAllowedError.index,
          PurchasesErrorCode.purchaseInvalidError.index,
          PurchasesErrorCode.productNotAvailableForPurchaseError.index,
          PurchasesErrorCode.ineligibleError.index,
          PurchasesErrorCode.insufficientPermissionsError.index,
        };
        if (rejectedBeforePayment.contains(int.tryParse(e.code))) {
          pendingMaps = null;
          _requestId = null;
          await _persist();
        }
        // Network/pending/receipt errors can follow a successful charge. Keep
        // the selection in those cases and reconcile instead of charging again.
        rethrow;
      } on UnlockFailure {
        // The local product lookup failed before invoking the store SDK.
        pendingMaps = null;
        _requestId = null;
        await _persist();
        rethrow;
      }
    }
    for (var i = 0; i < 5; i++) {
      await _sync();
      if (!pending) {
        message = 'Your two maps are ready. Enjoy exploring without ads!';
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    message =
        'Payment is awaiting confirmation. Check again shortly; you do not need to buy again.';
  });
  Future<void> changeSelection() => _guard(() async {
    await _accept(await remote.call('sync', code: code));
    if (credits < 2) {
      throw const UnlockFailure(
        'Wait for purchase confirmation before changing maps.',
      );
    }
    pendingMaps = null;
    _requestId = null;
    await _persist();
  });

  Future<bool> buyUpgrade() async {
    var owned = false;
    await _guard(() async {
      await _sync();
      if (!loyalty || upgradePrice == null) {
        throw const UnlockFailure(
          'The loyalty upgrade is not available for this collection.',
        );
      }
      await billing.identify(record!.customerId);
      owned = await billing.purchaseUpgrade();
    });
    return owned;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
