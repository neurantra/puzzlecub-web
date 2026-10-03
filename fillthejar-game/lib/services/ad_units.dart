import 'package:flutter/foundation.dart';

/// Publisher units are format-specific; development always uses test ads.
class AdUnits {
  static const androidRewarded = 'ca-app-pub-5992130091579926/1090772654';
  static const iosRewarded = 'ca-app-pub-5992130091579926/6893246753';
  static const androidInterstitial = 'ca-app-pub-5992130091579926/6157240386';
  static const iosInterstitial = 'ca-app-pub-5992130091579926/4329742727';
  static String interstitial(TargetPlatform platform, {required bool release}) {
    if (release && platform == TargetPlatform.iOS) return iosInterstitial;
    if (release && platform == TargetPlatform.android) {
      return androidInterstitial;
    }
    return platform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/4411468910'
        : 'ca-app-pub-3940256099942544/1033173712';
  }

  static bool usesTestRewarded(
    TargetPlatform platform, {
    required bool release,
  }) =>
      !release ||
      (platform != TargetPlatform.iOS && platform != TargetPlatform.android);
  static String rewarded(TargetPlatform platform, {required bool release}) {
    if (!usesTestRewarded(platform, release: release)) {
      return platform == TargetPlatform.iOS ? iosRewarded : androidRewarded;
    }
    return platform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/1712485313'
        : 'ca-app-pub-3940256099942544/5224354917';
  }
}
