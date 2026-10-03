import '../web_bridge.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';
import 'preferences.dart';

/// Home banners and optional breaks after every third finished round.
/// Protected/unknown players never initialize the advertising SDK.
class GameAds extends ChangeNotifier {
  GameAds(this.preferences) {
    _protected = preferences.protected;
    setWebAdsAllowed(!preferences.protected);
    preferences.addListener(refresh);
  }
  late bool _protected;
  final Preferences preferences;
  static const enabled = bool.fromEnvironment('ENABLE_ADS', defaultValue: true);
  InterstitialAd? _ad;
  bool _busy = false, _loading = false, _disposed = false;
  bool privacyRequired = false, _ready = false;
  int _generation = 0, _rounds = 0;
  int get generation => _generation;
  bool get eligible =>
      !_disposed &&
      enabled &&
      !preferences.protected &&
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform) &&
      (!kReleaseMode || AdIds.configured(defaultTargetPlatform));
  bool get ready => eligible && _ready;
  String get bannerUnit => AdIds.banner(defaultTargetPlatform);

  void _clear() {
    _generation++;
    _ready = false;
    _loading = false;
    _ad?.dispose();
    _ad = null;
  }

  void refresh() {
    if (_protected == preferences.protected) return;
    _protected = preferences.protected;
    setWebAdsAllowed(!preferences.protected);
    _clear();
    privacyRequired = false;
    if (!_disposed) notifyListeners();
    if (eligible) unawaited(prepare());
  }

  Future<void> prepare() async {
    if (!eligible || _busy) return;
    if (ready) {
      await _preload();
      return;
    }
    _busy = true;
    final generation = _generation;
    bool current() => eligible && generation == _generation;
    try {
      final done = Completer<void>();
      void finish() {
        if (!done.isCompleted) done.complete();
      }

      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!current()) {
            finish();
            return;
          }
          ConsentForm.loadAndShowConsentFormIfRequired((_) => finish());
        },
        (_) => finish(),
      );
      await done.future.timeout(const Duration(seconds: 20));
      if (!current()) return;
      final requirement = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      if (!current()) return;
      privacyRequired = requirement == PrivacyOptionsRequirementStatus.required;
      if (!await ConsentInformation.instance.canRequestAds() || !current()) {
        return;
      }
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
      );
      if (!current()) return;
      await MobileAds.instance.initialize();
      if (!current()) return;
      _ready = true;
      notifyListeners();
      await _preload();
    } catch (_) {
      // Consent/network failures never prevent playing.
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
      // A corrected profile may have changed while consent was in flight.
      if (eligible && generation != _generation) unawaited(prepare());
    }
  }

  Future<void> _preload() async {
    if (!ready || _loading || _ad != null) return;
    _loading = true;
    final generation = _generation;
    try {
      await InterstitialAd.load(
        adUnitId: AdIds.interstitial(defaultTargetPlatform),
        request: const AdRequest(nonPersonalizedAds: true),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (!ready || generation != _generation) {
              ad.dispose();
              return;
            }
            _loading = false;
            _ad = ad;
          },
          onAdFailedToLoad: (_) {
            if (generation == _generation) _loading = false;
          },
        ),
      );
    } catch (_) {
      if (generation == _generation) _loading = false;
    }
  }

  Future<void> afterRound() async {
    if (kIsWeb) {
      await betweenGames();
      return;
    }
    _rounds++;
    if (!ready || _rounds % 3 != 0 || _ad == null) {
      unawaited(prepare());
      return;
    }
    final ad = _ad!;
    _ad = null;
    final done = Completer<void>();
    void finish() {
      ad.dispose();
      if (!done.isCompleted) done.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    try {
      await ad.show();
      await done.future;
    } catch (_) {
      finish();
    }
    unawaited(_preload());
  }

  Future<void> privacy() async {
    if (!eligible) return;
    _clear();
    notifyListeners(); // Remove cached banners before privacy choices change.
    try {
      final done = Completer<void>();
      ConsentForm.showPrivacyOptionsForm((_) {
        if (!done.isCompleted) done.complete();
      });
      await done.future.timeout(const Duration(seconds: 20));
    } catch (_) {
      /* Consent is rechecked below. */
    }
    await prepare();
  }

  @override
  void dispose() {
    _disposed = true;
    preferences.removeListener(refresh);
    _clear();
    super.dispose();
  }
}
