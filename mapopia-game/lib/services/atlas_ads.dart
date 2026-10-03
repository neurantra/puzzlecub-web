import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'atlas_commerce.dart';

/// Breaks are only consumed when leaving a completed map, never on pause,
/// restart, resume, or during placement. A recent reward suppresses a break.
class AdBreakPolicy {
  int completions = 0;
  DateTime? lastFullscreen;
  bool takeBreak(DateTime now) {
    completions++;
    return completions.isEven &&
        (lastFullscreen == null ||
            now.difference(lastFullscreen!) >= const Duration(minutes: 3));
  }
}

class AtlasAds extends ChangeNotifier {
  AtlasAds(this.commerce) {
    commerce.addListener(_ownershipChanged);
  }
  final AtlasCommerce commerce;
  final breaks = AdBreakPolicy();
  static const enabled = bool.fromEnvironment('ENABLE_ADS');
  static const bannerId = String.fromEnvironment('ADMOB_BANNER_ID');
  static const interstitialId = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
  static const rewardId = String.fromEnvironment(
    'ADMOB_REWARDED_INTERSTITIAL_ID',
  );
  bool ready = false, privacyRequired = false, showing = false;
  bool _disposed = false, _loadingInterstitial = false, _loadingReward = false;
  InterstitialAd? _interstitial;
  RewardedInterstitialAd? _reward;
  Future<void>? _initializing;
  bool get eligible => ready && !commerce.fullAtlas && !_disposed;
  bool get rewardReady => eligible && _reward != null && !showing;
  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;
  String get bannerUnit => kReleaseMode
      ? bannerId
      : _ios
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';
  String get _interstitialUnit => kReleaseMode
      ? interstitialId
      : _ios
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';
  String get _rewardUnit => kReleaseMode
      ? rewardId
      : _ios
      ? 'ca-app-pub-3940256099942544/6978759866'
      : 'ca-app-pub-3940256099942544/5354046379';
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _clear() {
    _interstitial?.dispose();
    _interstitial = null;
    _reward?.dispose();
    _reward = null;
  }

  void _ownershipChanged() {
    if (commerce.fullAtlas) {
      _clear();
    } else {
      if (!ready && enabled) unawaited(initialize());
      preload();
    }
    _notify();
  }

  Future<void> initialize() {
    // An ad-free owner should not see an ad consent form.
    if (commerce.fullAtlas) return Future.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    if (!enabled ||
        kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform) ||
        (kReleaseMode &&
            [bannerId, interstitialId, rewardId].any(
              (id) =>
                  !id.startsWith('ca-app-pub-') ||
                  id.contains('3940256099942544'),
            ))) {
      return;
    }
    try {
      final consent = Completer<void>();
      void done() {
        if (!consent.isCompleted) consent.complete();
      }

      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => ConsentForm.loadAndShowConsentFormIfRequired((_) => done()),
        (_) => done(),
      );
      await consent.future.timeout(const Duration(seconds: 20));
      privacyRequired =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
      );
      await MobileAds.instance.initialize();
      if (defaultTargetPlatform == TargetPlatform.android) {
        await const MethodChannel(
          'com.mapopia.app/ads_privacy',
        ).invokeMethod<void>('disablePublisherFirstPartyId');
      }
      if (_disposed) return;
      ready = true;
      preload();
    } catch (_) {
      // Consent, offline, and SDK failures never block play.
    } finally {
      _notify();
    }
  }

  Future<void> privacy() async {
    if (!privacyRequired || showing) return;
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) {
      if (!done.isCompleted) done.complete();
    });
    await done.future;
    ready = await ConsentInformation.instance.canRequestAds();
    _clear();
    preload();
    _notify();
  }

  void preload() {
    if (!eligible) return;
    if (!_loadingInterstitial && _interstitial == null) {
      _loadingInterstitial = true;
      InterstitialAd.load(
        adUnitId: _interstitialUnit,
        request: const AdRequest(nonPersonalizedAds: true),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loadingInterstitial = false;
            if (!eligible) {
              ad.dispose();
              return;
            }
            _interstitial = ad;
          },
          onAdFailedToLoad: (_) {
            _loadingInterstitial = false;
          },
        ),
      ).catchError((Object _) {
        _loadingInterstitial = false;
      });
    }
    if (!_loadingReward && _reward == null) {
      _loadingReward = true;
      RewardedInterstitialAd.load(
        adUnitId: _rewardUnit,
        request: const AdRequest(nonPersonalizedAds: true),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loadingReward = false;
            if (!eligible) {
              ad.dispose();
              return;
            }
            _reward = ad;
            _notify();
          },
          onAdFailedToLoad: (_) {
            _loadingReward = false;
            _notify();
          },
        ),
      ).catchError((Object _) {
        _loadingReward = false;
      });
    }
  }

  Future<void> afterCompletedMap() async {
    final due = breaks.takeBreak(DateTime.now());
    if (!due || !eligible || showing || _interstitial == null) {
      preload();
      return;
    }
    final ad = _interstitial!;
    _interstitial = null;
    showing = true;
    final done = Completer<void>();
    void finish() {
      if (done.isCompleted) return;
      ad.dispose();
      showing = false;
      done.complete();
      preload();
      _notify();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        breaks.lastFullscreen = DateTime.now();
      },
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    try {
      await ad.show();
    } catch (_) {
      finish();
    }
    await done.future;
  }

  /// Called only after an explicit intro with a skip option.
  /// A dismissal alone never grants a hint.
  Future<bool> hintReward() async {
    if (!rewardReady) {
      preload();
      return false;
    }
    final ad = _reward!;
    _reward = null;
    showing = true;
    _notify();
    var earned = false;
    final done = Completer<bool>();
    void finish() {
      if (done.isCompleted) return;
      ad.dispose();
      showing = false;
      done.complete(earned);
      preload();
      _notify();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        breaks.lastFullscreen = DateTime.now();
      },
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          earned = true;
        },
      );
    } catch (_) {
      finish();
    }
    return done.future;
  }

  @override
  void dispose() {
    _disposed = true;
    commerce.removeListener(_ownershipChanged);
    _clear();
    super.dispose();
  }
}
