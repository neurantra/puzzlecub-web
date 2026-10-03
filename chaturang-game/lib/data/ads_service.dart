import 'package:flutter/foundation.dart';

// H5 between-game ads are handled by the web bridge, never the native AdMob SDK.
class AdsService extends ChangeNotifier {
  static final instance = AdsService();
  bool get available => false;
  bool get coinAdsAvailable => false;
  bool get privacyOptionsRequired => false;
  Future<bool> initialize() async => false;
  Future<bool> requestRewarded({int coins = 0}) async => false;
  Future<void> showPrivacyOptions() async {}
}

const coinsForRewardedAd = 0;
