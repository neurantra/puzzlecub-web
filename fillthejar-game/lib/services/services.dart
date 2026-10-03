import 'ad_units.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaveStore {
  final SharedPreferences prefs;
  Future<void> _pending = Future.value();
  String? _last;
  String? error;
  SaveStore(this.prefs);
  String? read() => prefs.getString('jar.mobile.v1');
  void write(String snapshot) {
    if (snapshot == _last) return;
    _last = snapshot;
    _pending = _pending.then((_) async {
      try {
        if (!await prefs.setString('jar.mobile.v1', snapshot)) {
          throw StateError('Save failed');
        }
        error = null;
      } catch (_) {
        _last = null;
        error = 'Progress could not be saved on this device.';
      }
    });
  }

  Future<void> flush() => _pending;

  Future<void> persist(String snapshot) async {
    write(snapshot);
    await flush();
    if (error != null) throw StateError(error!);
  }
}

class Sounds {
  final AudioPlayer _player = AudioPlayer();
  Future<void> play(String name, bool enabled) async {
    if (!enabled) return;
    try {
      await _player.play(AssetSource('audio/$name.wav'), volume: .35);
    } catch (_) {
      /* Audio restrictions must never interrupt a puzzle. */
    }
  }

  void dispose() {
    _player.dispose();
  }
}

enum RewardOutcome { earned, closed, unavailable }

class RewardAds {
  final bool allowed;
  final bool Function()? eligible;
  RewardAds({this.allowed = false, this.eligible});
  static bool get testAds =>
      AdUnits.usesTestRewarded(defaultTargetPlatform, release: kReleaseMode);
  bool busy = false;
  Future<bool>? _preparation;
  Timer? _consentTimer;
  Completer<bool>? _pendingConsent;
  void dispose() {
    _consentTimer?.cancel();
    final pending = _pendingConsent;
    if (pending != null && !pending.isCompleted) pending.complete(false);
  }

  bool get supported =>
      allowed &&
      (eligible?.call() ?? true) &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  bool get simulatedPreview =>
      allowed &&
      (eligible?.call() ?? true) &&
      kIsWeb &&
      (!kReleaseMode || const bool.fromEnvironment('ENABLE_AD_PREVIEW'));
  Future<bool> prepare() => _preparation ??= _prepare();
  Future<bool> _prepare() async {
    if (!supported) return false;
    final consent = Completer<bool>();
    _pendingConsent = consent;
    _consentTimer = Timer(const Duration(seconds: 12), () {
      if (!consent.isCompleted) consent.complete(false);
    });
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((error) async {
            if (!consent.isCompleted) {
              consent.complete(
                await ConsentInformation.instance.canRequestAds(),
              );
            }
          });
        },
        (error) async {
          if (!consent.isCompleted) {
            consent.complete(await ConsentInformation.instance.canRequestAds());
          }
        },
      );
      final permitted = await consent.future;
      _consentTimer?.cancel();
      if (!permitted || !supported) {
        _preparation = null;
        return false;
      }
      await MobileAds.instance.initialize();
      return true;
    } catch (_) {
      _consentTimer?.cancel();
      _preparation = null;
      return false;
    }
  }

  Future<RewardOutcome> show() async {
    if (busy || !supported) return RewardOutcome.unavailable;
    busy = true;
    try {
      if (!await prepare() || !supported) return RewardOutcome.unavailable;
      final loaded = Completer<RewardedAd?>();
      bool expired = false;
      await RewardedAd.load(
        adUnitId: AdUnits.rewarded(
          defaultTargetPlatform,
          release: kReleaseMode,
        ),
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (expired) {
              ad.dispose();
            } else if (!loaded.isCompleted) {
              loaded.complete(ad);
            }
          },
          onAdFailedToLoad: (_) {
            if (!loaded.isCompleted) loaded.complete(null);
          },
        ),
      );
      final ad = await loaded.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          expired = true;
          return null;
        },
      );
      if (ad == null) return RewardOutcome.unavailable;
      if (!supported) {
        ad.dispose();
        return RewardOutcome.unavailable;
      }
      final result = Completer<RewardOutcome>();
      bool earned = false;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (!result.isCompleted) {
            result.complete(
              earned ? RewardOutcome.earned : RewardOutcome.closed,
            );
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          if (!result.isCompleted) result.complete(RewardOutcome.unavailable);
        },
      );
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
        },
      );
      return await result.future;
    } catch (_) {
      return RewardOutcome.unavailable;
    } finally {
      busy = false;
    }
  }

  Future<bool> privacyOptions() async {
    if (!supported) return false;
    try {
      if (await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() !=
          PrivacyOptionsRequirementStatus.required) {
        return false;
      }
      final done = Completer<bool>();
      ConsentForm.showPrivacyOptionsForm((e) {
        done.complete(e == null);
      });
      return await done.future;
    } catch (_) {
      return false;
    }
  }
}
