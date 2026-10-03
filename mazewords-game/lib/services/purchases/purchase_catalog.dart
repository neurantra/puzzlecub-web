enum PurchaseTier {
  first(
    'com.mazewords.app.1st_language',
    'mazewords-1st-language',
    'First language',
  ),
  second(
    'com.mazewords.app.2nd_language',
    'mazewords-2nd-language',
    'Second language',
  ),
  all(
    'com.mazewords.app.all_languages',
    'mazewords-all-languages',
    'All languages',
  );

  const PurchaseTier(this.productId, this.entitlementId, this.title);
  final String productId;
  final String entitlementId;
  final String title;
}

class PurchaseAccess {
  PurchaseAccess(Iterable<String> active) : active = Set.unmodifiable(active);
  final Set<String> active;
  bool owns(PurchaseTier tier) => active.contains(tier.entitlementId);
  bool get adFree => PurchaseTier.values.any(owns);

  /// Both add-ons require First Language; All Languages does not require Second.
  bool canBuy(PurchaseTier tier) {
    if (owns(tier) || owns(PurchaseTier.all)) return false;
    return tier == PurchaseTier.first || owns(PurchaseTier.first);
  }
}

class PurchaseListing {
  const PurchaseListing(this.id, this.price);
  final String id;
  final String price;
}

abstract interface class PurchaseGateway {
  Future<void> initialize(void Function(PurchaseAccess) onUpdate);
  Future<PurchaseAccess> refresh();
  Future<List<PurchaseListing>> products();
  Future<PurchaseAccess> buy(String productId);
  Future<PurchaseAccess> restore();
  void dispose();
}
