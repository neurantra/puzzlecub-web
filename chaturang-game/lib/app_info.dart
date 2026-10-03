import 'package:package_info_plus/package_info_plus.dart';

/// App identity, read from the installed bundle rather than hard-coded.
///
/// The version shown in About used to be a pair of constants kept in
/// lockstep with `pubspec.yaml` by hand. That could never be right on iOS:
/// `ci_post_clone.sh` replaces the build number with Xcode Cloud's
/// `CI_BUILD_NUMBER` at archive time, so a build that reads "build 9" in
/// About ships to TestFlight as build 41. A tester quoting a build number
/// would name something nobody could find.
///
/// [load] now reads the real values from the platform. The constants
/// survive only as fallbacks — for the first frames before [load] resolves,
/// and for the case where the platform lookup fails.
class AppInfo {
  AppInfo._();

  /// Used until [load] resolves, and if it fails. Worth keeping roughly in
  /// step with pubspec, but no longer load-bearing.
  static const String fallbackVersionName = '2.0.3';
  static const String fallbackBuildNumber = '23';

  static String _versionName = fallbackVersionName;
  static String _buildNumber = fallbackBuildNumber;

  /// Marketing version, e.g. "1.2.0" (CFBundleShortVersionString).
  static String get versionName => _versionName;

  /// Build number, e.g. "41" (CFBundleVersion). A string, not an int:
  /// the platform hands it over as text and nothing is gained by parsing
  /// it — a non-numeric build number should still display, not vanish.
  static String get buildNumber => _buildNumber;

  /// Composed for display: "1.2.0 (build 41)".
  static String get versionDisplay => '$versionName (build $buildNumber)';

  /// Pulls the real bundle version. Fire-and-forget at startup, like the
  /// other services: a failure leaves the fallbacks in place rather than
  /// blocking launch over a version string.
  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) _versionName = info.version;
      if (info.buildNumber.isNotEmpty) _buildNumber = info.buildNumber;
    } catch (_) {
      // Platform channel unavailable (e.g. in tests) — keep the fallbacks.
    }
  }
}

/// Compile-time feature flag for online multiplayer.
///
/// Shipped `true` in v1.1. Kept as a flag so a future hotfix can dark
/// the feature without a UI redesign — flipping to `false` hides every
/// online-play entry point and skips all `lib/data/online/` code paths
/// (the dart compiler dead-strips them on `false` builds).
const bool kOnlineMultiplayerEnabled = false;

/// Public store URLs for Chaturang. Used by the Invite-Friends share
/// sheet and the Rate-the-app store fallback. The iOS Apple ID
/// (6770267722) is from App Store Connect; the Android applicationId
/// is from `android/app/build.gradle.kts`.
class StoreLinks {
  StoreLinks._();

  /// Apple App Store ID for Chaturang (from App Store Connect). Needed
  /// by `in_app_review.openStoreListing(appStoreId: ...)` — without it,
  /// the call silently no-ops on iOS.
  static const String iosAppStoreId = '6770267722';

  static const String androidPlayStore =
      'https://play.google.com/store/apps/details?id=com.chaturang.app';
  static const String iosAppStore =
      'https://apps.apple.com/app/id$iosAppStoreId';

  /// Other apps by Neurantra — used by the cross-promotion row in About.
  static const String neurantraSite = 'https://neurantra.com';
}
