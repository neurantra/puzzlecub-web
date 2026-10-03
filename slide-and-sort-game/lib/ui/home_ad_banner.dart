import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads.dart';
import 'toy_box.dart';

/// Only mounted on Home. Removed before navigating to a puzzle; never covers
/// gameplay or the solved-board celebration. Empty when consent or fill fails.
class HomeAdBanner extends StatefulWidget {
  const HomeAdBanner({super.key, required this.ads});
  final GameAds ads;
  @override
  State<HomeAdBanner> createState() => _HomeAdBannerState();
}

class _HomeAdBannerState extends State<HomeAdBanner> {
  BannerAd? _banner;
  bool _loaded = false;
  int _request = 0, _width = 0, _generation = -1;
  @override
  void initState() {
    super.initState();
    widget.ads.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(HomeAdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ads != widget.ads) {
      oldWidget.ads.removeListener(_changed);
      widget.ads.addListener(_changed);
      _generation = -1;
      _schedule();
    }
  }

  void _changed() {
    if (mounted) {
      setState(() {});
      _schedule();
    }
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_sync());
    });
  }

  void _discard() {
    final old = _banner;
    _banner = null;
    _loaded = false;
    // Platform views must unmount before their ad is disposed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(old?.dispose());
    });
  }

  Future<void> _sync() async {
    final width = MediaQuery.sizeOf(context).width.floor().clamp(0, 728);
    final generation = widget.ads.generation;
    if (!widget.ads.ready) {
      if (_banner != null || _width != 0) {
        _request++;
        setState(() {
          _discard();
          _width = 0;
        });
      }
      return;
    }
    if (_width == width && _generation == generation) return;
    final request = ++_request;
    _width = width;
    _generation = generation;
    setState(_discard);
    bool current() =>
        mounted &&
        request == _request &&
        widget.ads.ready &&
        generation == widget.ads.generation;
    try {
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (size == null || !current()) return;
      final ad = BannerAd(
        adUnitId: widget.ads.bannerUnit,
        size: size,
        request: const AdRequest(nonPersonalizedAds: true),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!current()) {
              ad.dispose();
              return;
            }
            setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, _) {
            if (!current()) {
              ad.dispose();
              return;
            }
            setState(_discard);
          },
        ),
      );
      _banner = ad;
      await ad.load();
    } catch (_) {
      if (current()) setState(_discard);
    }
  }

  @override
  void dispose() {
    _request++;
    widget.ads.removeListener(_changed);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.ads.ready || !_loaded || _banner == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Advertisement',
            style: TextStyle(fontSize: 10, color: teal),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: _banner!.size.width.toDouble(),
            height: _banner!.size.height.toDouble(),
            child: AdWidget(ad: _banner!),
          ),
        ],
      ),
    );
  }
}
