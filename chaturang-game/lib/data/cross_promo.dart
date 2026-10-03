import 'dart:io' show Platform;

/// Cross-promotion for PuzzleCub, the sibling app.
///
/// The bundle id is `com.sumquest.app` — an earlier name — while the store
/// listing and everything a player sees say PuzzleCub. Only the identifier
/// kept the old name, so nothing user-facing should ever show "sumquest".
class CrossPromo {
  CrossPromo._();

  /// What players call it. Not the bundle id.
  static const String appName = 'PuzzleCub';

  static const String _appStoreUrl =
      'https://apps.apple.com/us/app/puzzlecub/id6768766852';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.sumquest.app';

  /// The listing for the platform in hand. Falls back to the App Store on
  /// anything else, which only affects desktop debug runs.
  static String get storeUrl =>
      Platform.isAndroid ? _playStoreUrl : _appStoreUrl;

  /// One line on what the other game is, for a player who has never seen it.
  ///
  /// Kept short on purpose. This sits in the *secondary* choice on the
  /// out-of-coins sheet, and a paragraph there makes the de-emphasised
  /// option the visually dominant one — the layout says "do this" while the
  /// styling says "or maybe this".
  static const String blurb = 'Number and geography puzzles, same studio.';

  // There is deliberately no sharedWalletLive constant here any more.
  //
  // It used to gate the promo copy while the vault was unshipped, and once
  // the remote kill switch landed the two overlapped — a local constant and
  // a remote flag controlling one feature, which is how a feature ends up
  // half on. Everything now reads VaultAvailability.instance.isLive, which
  // is the switch that actually decides whether the vault UI exists.
}
