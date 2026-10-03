import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../game/session.dart';

class PackProducts {
  static const ids = {
    'animals': 'com.fillthejar.packs.animals',
    'vehicles': 'com.fillthejar.packs.vehicles',
    'landscapes': 'com.fillthejar.packs.landscapes',
    'all': 'com.fillthejar.packs.all',
  };
  static const bundleEntitlement = 'Fill the Jar - All Packs';
  static const iosKey = 'appl_fhbiqrdCCwtKqoFFnSOCGKyTior';
  static const androidKey = 'goog_OjVQznnmoMwDlnkdYoeCYLxmtsw';
}

abstract class PackBilling {
  Future<void> configure(void Function(Set<String>) updated);
  Future<Set<String>> access();
  Future<Map<String, String>> prices();
  Future<Set<String>> buy(String pack);
  Future<Set<String>> restore();
  void dispose();
}

class RevenueCatBilling implements PackBilling {
  final Map<String, StoreProduct> _products = {};
  void Function(CustomerInfo)? _listener;

  static Set<String> accessFrom(CustomerInfo info) {
    if (info.entitlements.verification == VerificationResult.failed) {
      throw StateError('Purchase verification failed');
    }
    final active = info.entitlements.active;
    return {
      for (final pack in ['animals', 'vehicles', 'landscapes'])
        if (active.containsKey(pack)) pack,
      if (active.containsKey(PackProducts.bundleEntitlement)) 'all',
    };
  }

  @override
  Future<void> configure(void Function(Set<String>) updated) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      throw UnsupportedError('Purchases require iOS or Android');
    }
    final config =
        PurchasesConfiguration(
            defaultTargetPlatform == TargetPlatform.iOS
                ? PackProducts.iosKey
                : PackProducts.androidKey,
          )
          ..entitlementVerificationMode =
              EntitlementVerificationMode.informational
          ..automaticDeviceIdentifierCollectionEnabled = false
          ..diagnosticsEnabled = false;
    await Purchases.configure(config);
    _listener = (info) {
      if (info.entitlements.verification != VerificationResult.failed) {
        updated(accessFrom(info));
      }
    };
    Purchases.addCustomerInfoUpdateListener(_listener!);
  }

  @override
  Future<Set<String>> access() async =>
      accessFrom(await Purchases.getCustomerInfo());
  @override
  Future<Map<String, String>> prices() async {
    final products = await Purchases.getProducts(
      PackProducts.ids.values.toList(),
      productCategory: ProductCategory.nonSubscription,
    );
    _products.clear();
    for (final entry in PackProducts.ids.entries) {
      for (final product in products) {
        if (product.identifier == entry.value) _products[entry.key] = product;
      }
    }
    return _products.map((key, value) => MapEntry(key, value.priceString));
  }

  @override
  Future<Set<String>> buy(String pack) async {
    final product = _products[pack];
    if (product == null) throw StateError('Product unavailable');
    final result = await Purchases.purchase(
      PurchaseParams.storeProduct(product),
    );
    return accessFrom(result.customerInfo);
  }

  @override
  Future<Set<String>> restore() async =>
      accessFrom(await Purchases.restorePurchases());
  @override
  void dispose() {
    if (_listener != null) {
      Purchases.removeCustomerInfoUpdateListener(_listener!);
    }
  }
}

class PackPurchases extends ChangeNotifier {
  final GameSession game;
  final PackBilling billing;
  Map<String, String> prices = {};
  bool loading = false, busy = false, _configured = false, _disposed = false;
  String? message;
  PackPurchases(this.game, this.billing);

  void _update(Set<String> access) {
    if (_disposed) return;
    game.updatePaidAccess(access);
    notifyListeners();
  }

  Future<void> refresh() async {
    if (loading || busy || _disposed) return;
    loading = true;
    message = null;
    notifyListeners();
    try {
      if (!_configured) {
        await billing.configure(_update);
        _configured = true;
      }
      _update(await billing.access());
      prices = await billing.prices();
      if (prices.length < 4) {
        message =
            'Some packs are unavailable from the store. Please try again later.';
      }
    } catch (_) {
      message =
          'Could not connect to the store. Your previously verified access is unchanged. Try again or restore purchases.';
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> buy(String pack) async {
    if (busy ||
        loading ||
        !prices.containsKey(pack) ||
        game.hasPaidPack(pack) ||
        game.rewardBusy ||
        game.walletBusy ||
        game.solving) {
      return;
    }
    await _transaction(() => billing.buy(pack), pack: pack);
  }

  Future<void> restore() async {
    if (busy || loading || game.rewardBusy || game.walletBusy || game.solving) {
      return;
    }
    if (!_configured) await refresh();
    if (!_configured) return;
    await _transaction(billing.restore);
  }

  Future<void> _transaction(
    Future<Set<String>> Function() action, {
    String? pack,
  }) async {
    busy = true;
    game.rewardBusy = true;
    message = null;
    game.refresh();
    notifyListeners();
    try {
      final access = await action();
      _update(access);
      message = pack == null
          ? (access.isEmpty
                ? 'No purchases to restore on this store account.'
                : 'Purchases restored.')
          : game.hasPaidPack(pack)
          ? 'Purchase complete. Your pack and all 100 levels are unlocked.'
          : 'The store returned your purchase, but access is not available yet. Please restore purchases shortly.';
    } on PlatformException catch (error) {
      final number = int.tryParse(error.code);
      final code =
          number != null &&
              number >= 0 &&
              number < PurchasesErrorCode.values.length
          ? PurchasesErrorCode.values[number]
          : PurchasesErrorCode.unknownError;
      message = code == PurchasesErrorCode.purchaseCancelledError
          ? 'Purchase cancelled.'
          : code == PurchasesErrorCode.paymentPendingError
          ? 'Payment is pending approval. Access will unlock after the store confirms it.'
          : 'The purchase could not be completed. Please try again or restore purchases.';
    } catch (_) {
      message =
          'The store could not verify your purchase. Please try Restore Purchases.';
    } finally {
      busy = false;
      game.rewardBusy = false;
      game.refresh();
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    billing.dispose();
    super.dispose();
  }
}
