import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrange_alphabets/services/ad_ids.dart';
import 'package:arrange_alphabets/services/ads.dart';
import 'package:arrange_alphabets/services/preferences.dart';

class PendingConsent extends Fake implements ConsentInformation {
  int updates = 0;
  late OnConsentInfoUpdateSuccessListener success;
  late OnConsentInfoUpdateFailureListener failure;
  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener onSuccess,
    OnConsentInfoUpdateFailureListener onFailure,
  ) {
    updates++;
    success = onSuccess;
    failure = onFailure;
  }

  @override
  Future<bool> canRequestAds() async => false;
  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async =>
      PrivacyOptionsRequirementStatus.required;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ConsentInformation original;
  late PendingConsent consent;
  late Preferences preferences;
  late GameAds ads;
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    original = ConsentInformation.instance;
    consent = PendingConsent();
    ConsentInformation.instance = consent;
    SharedPreferences.setMockInitialValues({});
    preferences = Preferences(await SharedPreferences.getInstance());
    ads = GameAds(preferences);
  });
  tearDown(() {
    ads.dispose();
    preferences.dispose();
    ConsentInformation.instance = original;
    debugDefaultTargetPlatformOverride = null;
  });
  test('development uses test units', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      expect(AdIds.configured(platform), isTrue);
      expect(
        AdIds.banner(platform),
        startsWith('ca-app-pub-3940256099942544/'),
      );
      expect(
        AdIds.interstitial(platform),
        startsWith('ca-app-pub-3940256099942544/'),
      );
      expect(
        AdIds.banner(platform, testAds: false),
        startsWith('ca-app-pub-5992130091579926/'),
      );
      expect(
        AdIds.interstitial(platform, testAds: false),
        startsWith('ca-app-pub-5992130091579926/'),
      );
    }
  });
  test('unknown and protected players never request consent or ads', () async {
    for (final year in [null, DateTime.now().year - 5]) {
      await preferences.saveYear(year);
      await ads.prepare();
      await ads.privacy();
      for (var i = 0; i < 6; i++) {
        await ads.afterRound();
      }
      expect(ads.ready, isFalse);
      expect(ads.eligible, isFalse);
    }
    expect(consent.updates, 0);
  });
  test(
    'profile correction invalidates pending consent before showing a form',
    () async {
      // Set storage before creating the service to control the prepare future.
      ads.dispose();
      await preferences.saveYear(1980);
      ads = GameAds(preferences);
      final pending = ads.prepare();
      expect(consent.updates, 1);
      await preferences.saveYear(DateTime.now().year - 5);
      consent.success();
      await pending;
      expect(ads.ready, isFalse);
      expect(ads.privacyRequired, isFalse);
    },
  );
  test('consent failure without permission leaves ads disabled', () async {
    ads.dispose();
    await preferences.saveYear(1980);
    ads = GameAds(preferences);
    final pending = ads.prepare();
    consent.failure(FormError(errorCode: 2, message: 'Offline'));
    await pending;
    expect(ads.ready, isFalse);
    expect(ads.privacyRequired, isTrue);
  });
}
