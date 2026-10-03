import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/appearance.dart';
import 'stats_service.dart';

/// Result of attempting to buy a [StoreItem].
enum PurchaseOutcome { purchased, alreadyOwned, notEnoughCoins }

/// Owns which appearance items the player has unlocked and which are
/// equipped, persisted to shared_preferences.
///
/// Deliberately separate from [StatsService]: ownership is not a game
/// statistic, and keeping the shipped stats schema untouched means an
/// appearance bug can't corrupt a player's lifetime record. The two meet
/// only in [purchase], which spends coins through [StatsService].
///
/// Both getters fall back to the free default when the stored id is
/// unknown, so removing an item from the catalog (or downgrading the app)
/// degrades to the Classic look rather than crashing.
class AppearanceService extends ChangeNotifier {
  AppearanceService._();
  static final AppearanceService instance = AppearanceService._();

  static const _kOwned = 'chaturang.appearance.owned';
  static const _kPieceSet = 'chaturang.appearance.pieceSet';
  static const _kSurface = 'chaturang.appearance.surface';

  Set<String> _owned = <String>{};
  String _pieceSetId = kClassicPieces.id;
  String _surfaceId = kParchmentSurface.id;
  bool _loaded = false;

  PieceSet get pieceSet => kPieceSets.firstWhere(
    (s) => s.id == _pieceSetId,
    orElse: () => kClassicPieces,
  );

  BoardSurface get surface => kBoardSurfaces.firstWhere(
    (s) => s.id == _surfaceId,
    orElse: () => kParchmentSurface,
  );

  /// Free items are owned by everyone, always.
  bool owns(StoreItem item) => item.price == 0 || _owned.contains(item.id);

  bool isEquipped(StoreItem item) =>
      item.id == _pieceSetId || item.id == _surfaceId;

  /// Pulls ownership and selection from disk. Idempotent.
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _owned = (prefs.getStringList(_kOwned) ?? const <String>[]).toSet();
    _pieceSetId = prefs.getString(_kPieceSet) ?? kClassicPieces.id;
    _surfaceId = prefs.getString(_kSurface) ?? kParchmentSurface.id;
    final migrated = prefs.getBool('chaturang.appearance.3dStandard') ?? false;
    if (!migrated) {
      // Existing flat/classic installs get the same standard 3D experience.
      if (_pieceSetId == 'pieces.classic') _pieceSetId = kSculptedPieces.id;
      // Honor the former 600-coin purchase with a premium finish.
      if (_owned.contains('pieces.sculpted')) _owned.add(kBronzePieces.id);
      await _persist();
      await prefs.setBool('chaturang.appearance.3dStandard', true);
    }
    // Retire the old camera preference without changing owned/equipped items.
    await prefs.remove('chaturang.appearance.tiltDegrees');
    await prefs.remove('chaturang.appearance.focusBoard');
    _loaded = true;
    notifyListeners();
  }

  /// Spends coins and unlocks [item]. The coin debit goes through
  /// [StatsService.spendCoins], so an insufficient balance fails there and
  /// nothing is unlocked.
  Future<PurchaseOutcome> purchase(StoreItem item) async {
    await load();
    if (owns(item)) return PurchaseOutcome.alreadyOwned;
    final paid = await StatsService.instance.spendCoins(item.price);
    if (!paid) return PurchaseOutcome.notEnoughCoins;
    _owned = {..._owned, item.id};
    notifyListeners();
    await _persist();
    return PurchaseOutcome.purchased;
  }

  /// Equips an owned [item]. No-op for items the player doesn't own, so a
  /// stale UI tap can't unlock anything.
  Future<void> equip(StoreItem item) async {
    await load();
    if (!owns(item)) return;
    switch (item) {
      case PieceSet():
        if (_pieceSetId == item.id) return;
        _pieceSetId = item.id;
      case BoardSurface():
        if (_surfaceId == item.id) return;
        _surfaceId = item.id;
      default:
        return;
    }
    notifyListeners();
    await _persist();
  }

  /// Drops in-memory state and re-arms [load], so a test can exercise the
  /// disk path more than once against this singleton.
  @visibleForTesting
  void debugReset() {
    _owned = <String>{};
    _pieceSetId = kClassicPieces.id;
    _surfaceId = kParchmentSurface.id;
    _loaded = false;
  }

  /// Wipes unlocks and returns to the free defaults. Companion to
  /// [StatsService.resetAll] for debug tooling.
  Future<void> resetAll() async {
    _loaded = true;
    _owned = <String>{};
    _pieceSetId = kClassicPieces.id;
    _surfaceId = kParchmentSurface.id;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kOwned, _owned.toList()..sort());
    await prefs.setString(_kPieceSet, _pieceSetId);
    await prefs.setString(_kSurface, _surfaceId);
  }
}
