import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/game_services.dart';

class HomeAd extends StatefulWidget {
  const HomeAd({super.key, required this.services});
  final GameServices services;
  @override
  State<HomeAd> createState() => _HomeAdState();
}

class _HomeAdState extends State<HomeAd> {
  BannerAd? _ad;
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    if (!widget.services.adsReady) return;
    _ad = BannerAd(
      adUnitId: widget.services.homeBannerId,
      size: AdSize.banner,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !_loaded || _ad == null
      ? const SizedBox.shrink()
      : SafeArea(
          child: SizedBox(
            height: 50,
            child: Center(
              child: SizedBox(
                width: 320,
                height: 50,
                child: AdWidget(ad: _ad!),
              ),
            ),
          ),
        );
}
