import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'purchase_catalog.dart';

class RevenueCatGateway implements PurchaseGateway {
  static const enabled = bool.fromEnvironment('ENABLE_PURCHASES');
  static const _appleKey = String.fromEnvironment('REVENUECAT_APPLE_API_KEY');
  static const _googleKey = String.fromEnvironment('REVENUECAT_GOOGLE_API_KEY');
  final Map<String, StoreProduct> _products = {};
  void Function(CustomerInfo)? _listener;

  static PurchaseAccess _access(CustomerInfo info) =>
      PurchaseAccess(info.entitlements.active.keys);

  @override
  Future<void> initialize(void Function(PurchaseAccess) onUpdate) async {
    if (!enabled ||
        kIsWeb ||
        ![
          TargetPlatform.iOS,
          TargetPlatform.android,
        ].contains(defaultTargetPlatform)) {
      throw StateError('Purchases are unavailable on this device.');
    }
    final key = defaultTargetPlatform == TargetPlatform.iOS
        ? _appleKey
        : _googleKey;
    if (key.isEmpty) throw StateError('Store configuration is unavailable.');
    if (!await Purchases.isConfigured) {
      await Purchases.configure(PurchasesConfiguration(key));
    }
    if (_listener != null) {
      Purchases.removeCustomerInfoUpdateListener(_listener!);
    }
    _listener = (info) => onUpdate(_access(info));
    Purchases.addCustomerInfoUpdateListener(_listener!);
    onUpdate(_access(await Purchases.getCustomerInfo()));
  }

  @override
  Future<PurchaseAccess> refresh() async {
    await Purchases.invalidateCustomerInfoCache();
    return _access(await Purchases.getCustomerInfo());
  }

  @override
  Future<List<PurchaseListing>> products() async {
    final products = await Purchases.getProducts(
      PurchaseTier.values.map((p) => p.productId).toList(),
      productCategory: ProductCategory.nonSubscription,
    );
    _products.clear();
    for (final product in products) {
      _products[product.identifier] = product;
    }
    return products
        .map((p) => PurchaseListing(p.identifier, p.priceString))
        .toList();
  }

  @override
  Future<PurchaseAccess> buy(String productId) async {
    final product = _products[productId];
    if (product == null) throw StateError('This product is unavailable.');
    return _access(
      (await Purchases.purchase(
        PurchaseParams.storeProduct(product),
      )).customerInfo,
    );
  }

  @override
  Future<PurchaseAccess> restore() async =>
      _access(await Purchases.restorePurchases());

  @override
  void dispose() {
    if (_listener != null) {
      Purchases.removeCustomerInfoUpdateListener(_listener!);
    }
    _listener = null;
  }
}
