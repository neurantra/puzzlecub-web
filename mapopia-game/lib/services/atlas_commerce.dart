import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../geo/domain/geo_region.dart';
import 'map_unlocks.dart';

abstract interface class AtlasBilling {
  Future<bool> initialize();
  Future<bool> ownership();
  Future<String?> price();
  Future<bool> purchase();
  Future<bool> restore();
  void listen(void Function(bool) changed);
  void dispose();
}

/// RevenueCat validates receipts with the stores; a purchase button never
/// grants access itself. Both stores attach their non-consumable to full_atlas.
class RevenueCatBilling implements AtlasBilling {
  static const entitlement = 'full_atlas';
  static const productId = 'com.mapopia.app.full_atlas';
  Package? _package;
  CustomerInfoUpdateListener? _listener;
  bool _owns(CustomerInfo info) =>
      info.entitlements.active.containsKey(entitlement);

  @override
  Future<bool> initialize() async {
    if (kIsWeb) return false;
    final key = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => const String.fromEnvironment('REVENUECAT_IOS_KEY'),
      TargetPlatform.android => const String.fromEnvironment(
        'REVENUECAT_ANDROID_KEY',
      ),
      _ => '',
    };
    if (key.isEmpty) return false;
    await Purchases.configure(PurchasesConfiguration(key));
    return true;
  }

  @override
  Future<bool> ownership() async => _owns(await Purchases.getCustomerInfo());
  @override
  Future<String?> price() async {
    final packages =
        (await Purchases.getOfferings()).current?.availablePackages ??
        <Package>[];
    _package = null;
    for (final package in packages) {
      if (package.storeProduct.identifier == productId &&
          package.packageType == PackageType.lifetime) {
        _package = package;
        break;
      }
    }
    return _package?.storeProduct.priceString;
  }

  @override
  Future<bool> purchase() async {
    final package = _package;
    if (package == null) return false;
    return _owns(
      (await Purchases.purchase(PurchaseParams.package(package))).customerInfo,
    );
  }

  @override
  Future<bool> restore() async => _owns(await Purchases.restorePurchases());
  @override
  void listen(void Function(bool) changed) {
    _listener = (info) => changed(_owns(info));
    Purchases.addCustomerInfoUpdateListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) {
      Purchases.removeCustomerInfoUpdateListener(_listener!);
    }
  }
}

class AtlasCommerce extends ChangeNotifier {
  AtlasCommerce(this.prefs, {AtlasBilling? billing, MapUnlocks? unlocks})
    : billing = billing ?? RevenueCatBilling(),
      unlocks = unlocks ?? MapUnlocks(),
      _fullAtlas = prefs.getBool('fullAtlas') ?? false {
    this.unlocks.addListener(_notify);
    final raw = prefs.getString('mapTrial');
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map;
        _trialRegion = GeoRegion.values.byName(data['region'] as String);
        _trialPieces.addAll((data['pieces'] as List).cast<String>());
        _trialPieceLimit = data['limit'] as int;
      } catch (_) {
        // A damaged record must not create another free allowance.
        _trialInvalid = true;
      }
    }
  }
  final SharedPreferences prefs;
  final AtlasBilling billing;
  final MapUnlocks unlocks;
  bool adFree(GeoRegion region) => fullAtlas || unlocks.maps.contains(region);
  static const freeMap = GeoRegion.australia;
  bool _fullAtlas;
  static const testUnlock =
      kDebugMode && bool.fromEnvironment('MAPOPIA_TEST_UNLOCK');
  bool get fullAtlas => kIsWeb || _fullAtlas || testUnlock;
  bool allows(GeoRegion region) => adFree(region) || region == freeMap;
  // Whole pieces: round up so players receive at least one third of a map.
  int trialLimit(int total) => (total + 2) ~/ 3;
  GeoRegion? _trialRegion;
  final Set<String> _trialPieces = {};
  int _trialPieceLimit = 0;
  bool _trialInvalid = false;
  Future<void> _trialWrites = Future.value();
  GeoRegion? get trialRegion => _trialRegion;
  bool get trialExhausted =>
      _trialInvalid ||
      (_trialRegion != null && _trialPieces.length >= _trialPieceLimit);
  bool canOpen(GeoRegion region) =>
      allows(region) ||
      (!trialExhausted && (_trialRegion == null || _trialRegion == region));
  bool canPlace(GeoRegion region, int placed, int total) =>
      allows(region) || (canOpen(region) && placed < trialLimit(total));

  /// The first successful placement chooses the single trial map. Unique
  /// pieces accumulate across normal/daily games and restarts on this device.
  Future<void> recordTrialProgress(
    GeoRegion region,
    Set<String> pieces,
    int total,
  ) {
    if (allows(region) ||
        pieces.isEmpty ||
        (_trialRegion != null && _trialRegion != region) ||
        _trialInvalid) {
      return Future.value();
    }
    final before = _trialPieces.length;
    _trialRegion ??= region;
    if (_trialPieceLimit == 0) _trialPieceLimit = trialLimit(total);
    _trialPieces.addAll(pieces);
    if (before != _trialPieces.length) _notify();
    final raw = jsonEncode({
      'region': _trialRegion!.name,
      'pieces': _trialPieces.toList(),
      'limit': _trialPieceLimit,
    });
    final write = _trialWrites.then((_) async {
      if (!await prefs.setString('mapTrial', raw)) {
        throw StateError('Trial progress could not be saved');
      }
    });
    _trialWrites = write.catchError((Object _) {});
    return write;
  }

  bool ready = false, busy = false;
  String? price, message;
  bool _disposed = false;
  Future<void>? _initializing;
  Future<void> _ownershipQueue = Future.value();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _saveOwnership(bool owned) {
    final next = _ownershipQueue.then((_) async {
      if (!await prefs.setBool('fullAtlas', owned)) {
        throw StateError('Ownership could not be saved');
      }
      _fullAtlas = owned;
      _notify();
    });
    _ownershipQueue = next.catchError((Object _) {});
    return next;
  }

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    if (kIsWeb) return;
    try {
      ready = await billing.initialize();
      if (!ready) return;
      await unlocks.initialize();
      billing.listen((owned) {
        unawaited(
          _saveOwnership(owned).catchError((Object _) {
            message =
                'Your purchase could not be saved. Please restore purchases.';
            _notify();
          }),
        );
      });
      await _saveOwnership(await billing.ownership());
      price = await billing.price();
      await unlocks.refreshPrices();
    } catch (_) {
      message = 'The store is unavailable. Please try again later.';
    } finally {
      _notify();
    }
  }

  Future<void> refreshPrice() async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    try {
      await initialize();
      if (ready) {
        price = await billing.price();
        await unlocks.refreshPrices();
      }
      if (price == null) {
        message =
            'Purchases are not available yet. Australia remains free to explore.';
      }
    } catch (_) {
      message = 'The store is unavailable. Please try again later.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> buyUpgrade() async {
    if (busy || fullAtlas || !ready) return;
    busy = true;
    _notify();
    try {
      if (await unlocks.buyUpgrade()) await _saveOwnership(true);
      message = unlocks.message;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> buy() => _transaction(restore: false);
  Future<void> restore() => _transaction(restore: true);
  Future<void> _transaction({required bool restore}) async {
    if (busy || !ready || (!restore && (price == null || fullAtlas))) return;
    busy = true;
    message = null;
    _notify();
    try {
      final owned = restore
          ? await billing.restore()
          : await billing.purchase();
      await _saveOwnership(owned);
      message = owned
          ? 'Your Full Atlas is ready. Happy exploring!'
          : restore
          ? 'No Full Atlas purchase was found for this store account.'
          : 'Your purchase is awaiting confirmation.';
    } on PlatformException catch (e) {
      if (int.tryParse(e.code) !=
          PurchasesErrorCode.purchaseCancelledError.index) {
        message = 'The purchase could not be completed. Please try again.';
      }
    } catch (_) {
      message = 'The store is unavailable. Your existing maps are safe.';
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unlocks.removeListener(_notify);
    unlocks.dispose();
    billing.dispose();
    super.dispose();
  }
}
