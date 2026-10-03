import 'package:flutter/foundation.dart';

/// Public identifiers supplied from the Arrange Alphabets AdMob account.
/// Debug/profile builds always use Google's sample units.
abstract final class AdIds {
  static const androidApp = 'ca-app-pub-5992130091579926~3851684827';
  static const iosApp = 'ca-app-pub-5992130091579926~6053333029';
  static bool configured(TargetPlatform platform) => switch (platform) {
    TargetPlatform.android => androidApp.isNotEmpty,
    TargetPlatform.iOS => iosApp.isNotEmpty,
    _ => false,
  };
  static String banner(
    TargetPlatform platform, {
    bool testAds = !kReleaseMode,
  }) => switch (platform) {
    TargetPlatform.android =>
      testAds
          ? 'ca-app-pub-3940256099942544/9214589741'
          : 'ca-app-pub-5992130091579926/7811111130',
    TargetPlatform.iOS =>
      testAds
          ? 'ca-app-pub-3940256099942544/2435281174'
          : 'ca-app-pub-5992130091579926/3427169687',
    _ => '',
  };
  static String interstitial(
    TargetPlatform platform, {
    bool testAds = !kReleaseMode,
  }) => switch (platform) {
    TargetPlatform.android =>
      testAds
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-5992130091579926/8333855317',
    TargetPlatform.iOS =>
      testAds
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-5992130091579926/6829201953',
    _ => '',
  };
}
