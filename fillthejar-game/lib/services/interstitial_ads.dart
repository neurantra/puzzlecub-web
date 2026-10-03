import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_units.dart';
import 'services.dart';

/// Preload only. A missed opportunity never holds up the next puzzle.
class InterstitialAds {
  final RewardAds consent;
  InterstitialAds(this.consent);
  InterstitialAd? _ad;
  DateTime? _loadedAt;
  bool _loading = false, _disposed = false;
  Future<void> preload() async {
    if (_disposed || _loading || _ad != null || !consent.supported) return;
    _loading = true;
    try {
      if (!await consent.prepare() || _disposed || !consent.supported) {
        _loading = false;
        return;
      }
      await InterstitialAd.load(
        adUnitId: AdUnits.interstitial(
          defaultTargetPlatform,
          release: kReleaseMode,
        ),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            if (_disposed || !consent.supported) {
              ad.dispose();
              return;
            }
            _ad = ad;
            _loadedAt = DateTime.now();
          },
          onAdFailedToLoad: (_) {
            _loading = false;
          },
        ),
      );
    } catch (_) {
      _loading = false;
    }
  }

  Future<void> showIfReady() async {
    final ad = _ad;
    _ad = null;
    if (ad == null) return;
    if (_disposed ||
        !consent.supported ||
        DateTime.now().difference(_loadedAt!) >= const Duration(minutes: 55)) {
      ad.dispose();
      return;
    }
    try {
      if (!await ConsentInformation.instance.canRequestAds() ||
          _disposed ||
          !consent.supported) {
        ad.dispose();
        return;
      }
      final done = Completer<void>();
      void finish() {
        ad.dispose();
        if (!done.isCompleted) done.complete();
      }

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (_) => finish(),
        onAdFailedToShowFullScreenContent: (_, _) => finish(),
      );
      await ad.show();
      await done.future;
    } catch (_) {
      ad.dispose();
    }
  }

  void clear() {
    _ad?.dispose();
    _ad = null;
  }

  void dispose() {
    _disposed = true;
    clear();
  }
}
