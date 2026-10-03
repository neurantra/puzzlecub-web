import 'package:flutter/foundation.dart';
import 'purchase_catalog.dart';
import '../../data/player_store.dart';
import '../../domain/puzzle_language.dart';
import '../../domain/maze.dart';

/// Entitlements always come from RevenueCat, never player preferences.
class PurchaseService extends ChangeNotifier {
  PurchaseService(this.gateway, {this.store});
  final PlayerStore? store;
  final PurchaseGateway gateway;
  PurchaseAccess access = PurchaseAccess(const []);
  List<PurchaseListing> listings = const [];
  bool ready = false, busy = false, _disposed = false;
  Future<void>? _initializing;

  void _update(PurchaseAccess value) {
    if (_disposed) return;
    access = value;
    notifyListeners();
  }

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    try {
      await gateway.initialize(_update);
      ready = true;
      listings = await gateway.products();
      if (!_disposed) notifyListeners();
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  String? get freeLanguage => store?.prefs.getString('purchases.freeLanguage');
  String? languageFor(PurchaseTier tier) =>
      store?.prefs.getString('purchases.language.${tier.name}');

  Future<void> chooseFreeLanguage(String language) async {
    if (!PuzzleLanguage.supports(language) || store == null) {
      throw StateError('Unsupported language');
    }
    if (freeLanguage != null && freeLanguage != language) {
      throw StateError('Your free language is already selected.');
    }
    if (!await store!.prefs.setString('purchases.freeLanguage', language)) {
      throw StateError('Could not save your language.');
    }
    notifyListeners();
  }

  int mazeLimit(String language) {
    if (access.owns(PurchaseTier.all)) return 150;
    for (final tier in [PurchaseTier.first, PurchaseTier.second]) {
      if (access.owns(tier) && languageFor(tier) == language) return 150;
    }
    return freeLanguage == language ? 10 : 0;
  }

  MazePack playablePack(String language, MazePack pack) {
    final limit = mazeLimit(language);
    if (limit == 0) throw StateError('Unlock this language before playing.');
    return MazePack(
      version: pack.version,
      level: pack.level,
      width: pack.width,
      height: pack.height,
      letterCount: pack.letterCount,
      targetMin: pack.targetMin,
      targetMax: pack.targetMax,
      mazes: pack.mazes.take(limit).toList(growable: false),
    );
  }

  /// Restored slots without local selections can be assigned without charging again.
  Future<void> selectRestoredLanguage(
    PurchaseTier tier,
    String language,
  ) async {
    if (busy ||
        tier == PurchaseTier.all ||
        !access.owns(tier) ||
        languageFor(tier) != null) {
      throw StateError('This language slot is unavailable.');
    }
    await _saveLanguage(tier, language);
    notifyListeners();
  }

  Future<void> _saveLanguage(PurchaseTier tier, String language) async {
    if (store == null || !PuzzleLanguage.supports(language)) {
      throw StateError('Unsupported language');
    }
    final other = tier == PurchaseTier.first
        ? PurchaseTier.second
        : PurchaseTier.first;
    if (access.owns(other) && languageFor(other) == language) {
      throw StateError('This language is already unlocked.');
    }
    if (!await store!.prefs.setString(
      'purchases.language.${tier.name}',
      language,
    )) {
      throw StateError(
        'Could not save your language. No purchase was started.',
      );
    }
  }

  bool canBuy(PurchaseTier tier) =>
      ready &&
      !busy &&
      access.canBuy(tier) &&
      listings.any((p) => p.id == tier.productId);

  Future<void> buy(PurchaseTier tier, {String? language}) async {
    if (busy) throw StateError('A purchase is already in progress.');
    busy = true;
    notifyListeners();
    try {
      await initialize();
      // Recheck after a fresh entitlement lookup, not only when rendering a button.
      _update(await gateway.refresh());
      if (!access.canBuy(tier)) {
        throw StateError(
          'Buy First Language before an additional language pack.',
        );
      }
      if (!listings.any((p) => p.id == tier.productId)) {
        throw StateError('This product is unavailable.');
      }
      // Persist the selected slot before checkout so a killed app can recover it.
      if (store != null && tier != PurchaseTier.all) {
        if (language == null) throw StateError('Choose a language first.');
        await _saveLanguage(tier, language);
      }
      _update(await gateway.buy(tier.productId));
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> restore() async {
    if (busy) throw StateError('A purchase is already in progress.');
    busy = true;
    notifyListeners();
    try {
      await initialize();
      _update(await gateway.restore());
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    gateway.dispose();
    super.dispose();
  }
}
