import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// The SDK's test bridge lets us deliver real SDK callbacks without a network ad.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapopia/services/atlas_ads.dart';
import 'package:mapopia/services/atlas_commerce.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AtlasCommerce commerce;
  late AtlasAds ads;
  final calls = <MethodCall>[];
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    commerce = AtlasCommerce(await SharedPreferences.getInstance());
    ads = AtlasAds(commerce)..ready = true;
    instanceManager = AdInstanceManager('plugins.flutter.io/google_mobile_ads');
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(() {
    ads.dispose();
    commerce.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, null);
  });

  Future<RewardedInterstitialAd> loadReward() async {
    ads.preload();
    await Future<void>.delayed(Duration.zero);
    final load = calls.firstWhere(
      (c) => c.method == 'loadRewardedInterstitialAd',
    );
    final ad =
        instanceManager.adFor((load.arguments as Map)['adId'] as int)
            as RewardedInterstitialAd;
    ad.rewardedInterstitialAdLoadCallback.onAdLoaded(ad);
    return ad;
  }

  test('dismissal without earned callback never grants a hint', () async {
    final ad = await loadReward();
    final result = ads.hintReward();
    await Future<void>.delayed(Duration.zero);
    expect(ads.showing, true);
    expect(await ads.hintReward(), false); // No duplicate ad from a second tap.
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    expect(await result, false);
    expect(ads.showing, false);
  });

  test('earned hint is delivered once after ad closes', () async {
    final ad = await loadReward();
    final result = ads.hintReward();
    await Future<void>.delayed(Duration.zero);
    ad.fullScreenContentCallback!.onAdShowedFullScreenContent!(ad);
    ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'hint'));
    ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'hint'));
    expect(ads.showing, true);
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    expect(await result, true);
    expect(ads.breaks.lastFullscreen, isNotNull);
    expect(ads.showing, false);
  });

  test('failed fullscreen presentation never grants a hint', () async {
    final ad = await loadReward();
    final result = ads.hintReward();
    await Future<void>.delayed(Duration.zero);
    ad.fullScreenContentCallback!.onAdFailedToShowFullScreenContent!(
      ad,
      AdError(1, 'test', 'Unable to show'),
    );
    expect(await result, false);
    expect(ads.showing, false);
  });
}
