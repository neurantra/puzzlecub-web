import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/atlas_ads.dart';
import 'theme.dart';

class MapBanner extends StatefulWidget {
  const MapBanner({super.key, required this.ads});
  final AtlasAds ads;
  @override
  State<MapBanner> createState() => _MapBannerState();
}

class _MapBannerState extends State<MapBanner> {
  BannerAd? _ad;
  int? _width;
  bool _loaded = false;
  int _generation = 0;

  Future<void> _load(int width) async {
    final generation = ++_generation;
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    try {
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted ||
          generation != _generation ||
          size == null ||
          !widget.ads.eligible) {
        return;
      }
      final ad = BannerAd(
        adUnitId: widget.ads.bannerUnit,
        size: size,
        request: const AdRequest(nonPersonalizedAds: true),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted || generation != _generation) {
              ad.dispose();
              return;
            }
            setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            if (mounted && generation == _generation) {
              setState(() {
                _ad = null;
                _loaded = false;
              });
            }
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (_) {
      /* No fill never blocks the map. */
    }
  }

  @override
  void dispose() {
    _generation++;
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.floor();
      if (_width != width) {
        _width = width;
        _loaded = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_load(width));
          }
        });
      }
      if (!_loaded || _ad == null) return const SizedBox.shrink();
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text(
              'ADVERTISEMENT',
              style: TextStyle(fontSize: 8, letterSpacing: 1.2, color: muted),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: _ad!.size.width.toDouble(),
              height: _ad!.size.height.toDouble(),
              child: AdWidget(ad: _ad!),
            ),
          ],
        ),
      );
    },
  );
}
