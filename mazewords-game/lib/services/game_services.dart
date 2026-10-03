import '../web_bridge.dart';
import 'dart:async';
import 'packs/language_packs.dart';
import 'purchases/purchase_service.dart';
import 'purchases/revenuecat_gateway.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../firebase_options.dart';
import '../data/player_store.dart';
import 'vault/firebase_vault.dart';
import 'vault/vault_service.dart';

/// Firebase uses this app's own project. Gameplay remains available offline.
/// Ads stay disabled until Maze Words has production AdMob configuration.
class GameServices {
  GameServices(this.store, {PurchaseService? purchaseService}) {
    purchases =
        purchaseService ?? PurchaseService(RevenueCatGateway(), store: store);
    purchases.addListener(_purchaseChanged);
  }
  late final PurchaseService purchases;
  bool get _paid => purchases.access.adFree;
  bool get _adsAllowed =>
      !_paid && (!RevenueCatGateway.enabled || purchases.ready);
  void _purchaseChanged() {
    if (_disposed) return;
    if (_paid) {
      _interstitial?.dispose();
      _interstitial = null;
    }
    store.walletChanged();
  }

  final PlayerStore store;
  late final packs = LanguagePacks();
  VaultService? _vault;
  static const vaultEnabled = bool.fromEnvironment(
    'ENABLE_VAULT',
    defaultValue: true,
  );
  VaultService? get vault {
    if (!firebaseEnabled ||
        !vaultEnabled ||
        !mobile ||
        !store.onboarded ||
        !store.adult) {
      return null;
    }
    return _vault ??= VaultService(
      store,
      FirebaseVault(store.prefs, allowed: () => store.onboarded && store.adult),
    );
  }

  Future<void> recoverVault() async {
    final current = vault;
    if (current != null && current.pending && !current.busy) {
      await current.refresh();
    }
  }

  AudioPlayer? _audio;
  bool adsReady = false;
  bool privacyRequired = false;
  bool _configured = false;
  bool? _configuredAudience;
  Future<void>? _configuration;
  int _audienceGeneration = 0;
  FlutterExceptionHandler? _previousFlutterError;
  bool Function(Object, StackTrace)? _previousPlatformError;
  bool _ownsErrorHandlers = false;

  bool get audienceChangeBusy =>
      _rewardLoading || _showingInterstitial || (_vault?.busy ?? false);

  Future<void> refreshAudience() async {
    await _configuration;
    if (_disposed || _configuredAudience == store.adult) return;
    adsReady = false;
    privacyRequired = false;
    _audienceGeneration++;
    if (_vault != null && !_vault!.busy) {
      _vault!.dispose();
      _vault = null;
    }
    _interstitial?.dispose();
    _interstitial = null;
    _interstitialLoading = false;
    if (_ownsErrorHandlers) {
      FlutterError.onError = _previousFlutterError;
      PlatformDispatcher.instance.onError = _previousPlatformError;
      _ownsErrorHandlers = false;
    }
    _configured = false;
    _configuration = null;
    await configure();
  }

  bool _rewardLoading = false;
  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;
  bool _showingInterstitial = false;
  bool _disposed = false;
  bool get mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  static const adsEnabled = bool.fromEnvironment('ENABLE_ADS');
  static const bannersEnabled = bool.fromEnvironment('ENABLE_BANNER_ADS');
  static const rewardsEnabled = bool.fromEnvironment('ENABLE_REWARDED_ADS');
  bool get bannerReady => adsReady && bannersEnabled && _adsAllowed;
  bool get rewardedReady => adsReady && rewardsEnabled && _adsAllowed;
  static const firebaseEnabled = bool.fromEnvironment(
    'ENABLE_FIREBASE',
    defaultValue: true,
  );
  static const rewardedId = String.fromEnvironment('ADMOB_REWARDED_ID');
  static const bannerId = String.fromEnvironment('ADMOB_BANNER_ID');
  static const interstitialId = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');

  String get homeBannerId => kReleaseMode && bannerId.isNotEmpty
      ? bannerId
      : defaultTargetPlatform == TargetPlatform.iOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  Future<void> configure() => _configuration ??= _configure();

  Future<void> _configure() async {
    setWebAdsAllowed(store.onboarded && store.adult);
    if (_configured || !mobile || !store.onboarded) return;
    _configured = true;
    _configuredAudience = store.adult;
    if (RevenueCatGateway.enabled && store.adult) {
      try {
        await purchases.initialize();
      } catch (_) {
        /* Retry from the store screen. */
      }
    }
    if (firebaseEnabled) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          store.adult && kReleaseMode,
        );
        if (store.adult && kReleaseMode) {
          _previousFlutterError = FlutterError.onError;
          _previousPlatformError = PlatformDispatcher.instance.onError;
          _ownsErrorHandlers = true;
          FlutterError.onError =
              FirebaseCrashlytics.instance.recordFlutterFatalError;
          PlatformDispatcher.instance.onError = (error, stack) {
            unawaited(
              FirebaseCrashlytics.instance.recordError(
                error,
                stack,
                fatal: true,
              ),
            );
            return true;
          };
        }
      } catch (e) {
        debugPrint('Maze Words Firebase unavailable: $e');
      }
    }
    unawaited(recoverVault());
    // Keep the first standalone release ad-free for child profiles. The
    // existing suite's child-directed ad policy can be introduced separately.
    if (!_adsAllowed ||
        !adsEnabled ||
        !store.adult ||
        (kReleaseMode &&
            (interstitialId.isEmpty ||
                (bannersEnabled && bannerId.isEmpty) ||
                (rewardsEnabled && rewardedId.isEmpty)))) {
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
      await consent.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {},
      );
      privacyRequired =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
      );
      await MobileAds.instance.initialize();
      adsReady = true;
      _loadInterstitial();
    } catch (e) {
      debugPrint('Maze Words ads unavailable: $e');
    }
  }

  Future<void> privacy() async {
    if (!mobile || !adsEnabled) return;
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) {
      if (!done.isCompleted) done.complete();
    });
    await done.future;
    adsReady = await ConsentInformation.instance.canRequestAds();
    _interstitial?.dispose();
    _interstitial = null;
    if (adsReady) _loadInterstitial();
  }

  void _loadInterstitial() {
    if (!_adsAllowed ||
        !adsReady ||
        _disposed ||
        _interstitialLoading ||
        _interstitial != null) {
      return;
    }
    _interstitialLoading = true;
    final generation = _audienceGeneration;
    final id = kReleaseMode
        ? interstitialId
        : defaultTargetPlatform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/4411468910'
        : 'ca-app-pub-3940256099942544/1033173712';
    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(nonPersonalizedAds: true),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (generation != _audienceGeneration) {
            ad.dispose();
            return;
          }
          _interstitialLoading = false;
          if (_disposed || !adsReady || !_adsAllowed) {
            ad.dispose();
            return;
          }
          _interstitial = ad;
        },
        onAdFailedToLoad: (_) {
          if (generation != _audienceGeneration) return;
          _interstitialLoading = false;
        },
      ),
    );
  }

  /// Every three cleared mazes, only when leaving results. Unfilled ad breaks
  /// are skipped, never queued to surprise the player during the next maze.
  Future<void> afterRound() async {
    if (kIsWeb) {
      await betweenGames();
      return;
    }
    if (!_adsAllowed ||
        _disposed ||
        _showingInterstitial ||
        !store.interstitialDue) {
      return;
    }
    _showingInterstitial = true;
    await store.consumeInterstitialBreak();
    final ad = adsReady && store.adult ? _interstitial : null;
    if (ad == null || _disposed) {
      _showingInterstitial = false;
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    final done = Completer<void>();
    void finish(InterstitialAd ad) {
      ad.dispose();
      _showingInterstitial = false;
      if (!done.isCompleted) done.complete();
      _loadInterstitial();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, _) => finish(ad),
    );
    try {
      await ad.show();
    } catch (_) {
      finish(ad);
    }
    await done.future;
  }

  Future<bool> bonusAd() async {
    if (!rewardedReady || _rewardLoading) return false;
    _rewardLoading = true;
    final done = Completer<bool>();
    var earned = false;
    final id = kReleaseMode && rewardedId.isNotEmpty
        ? rewardedId
        : defaultTargetPlatform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/1712485313'
        : 'ca-app-pub-3940256099942544/5224354917';
    try {
      await RewardedAd.load(
        adUnitId: id,
        request: const AdRequest(nonPersonalizedAds: true),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdFailedToLoad: (_) {
            if (!done.isCompleted) done.complete(false);
          },
          onAdLoaded: (ad) {
            if (done.isCompleted || _disposed || !_adsAllowed) {
              if (!done.isCompleted) done.complete(false);
              ad.dispose();
              return;
            }
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!done.isCompleted) done.complete(earned);
              },
              onAdFailedToShowFullScreenContent: (ad, _) {
                ad.dispose();
                if (!done.isCompleted) done.complete(false);
              },
            );
            ad.show(
              onUserEarnedReward: (_, _) {
                earned = true;
                unawaited(store.reward(25));
              },
            );
          },
        ),
      );
      return await done.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          if (!done.isCompleted) done.complete(false);
          return false;
        },
      );
    } catch (_) {
      return false;
    } finally {
      _rewardLoading = false;
    }
  }

  Future<void> feedback({bool good = true}) async {
    if (store.haptics && mobile) unawaited(HapticFeedback.selectionClick());
    if (store.sound) {
      try {
        await (_audio ??= AudioPlayer()).play(
          AssetSource('sounds/${good ? 'correct' : 'wrong'}.mp3'),
          volume: .45,
        );
      } catch (_) {
        /* Audio is an enhancement, never a gameplay dependency. */
      }
    }
  }

  void dispose() {
    _disposed = true;
    purchases.removeListener(_purchaseChanged);
    purchases.dispose();
    packs.dispose();
    _vault?.dispose();
    _interstitial?.dispose();
    if (_audio != null) unawaited(_audio!.dispose());
  }
}
