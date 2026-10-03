import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/cross_promo.dart';
import '../data/vault_availability.dart';
import 'theme.dart';

/// What the player chose in [showPuzzleCubSheet].
enum CoinRoute {
  /// Watch a rewarded ad here.
  watchAd,

  /// Went to the other app's store listing.
  visitedPuzzleCub,

  /// Backed out.
  dismissed,
}

/// Offered when a player wants something they cannot afford.
///
/// Two ways forward rather than one: the rewarded ad they already had, and
/// PuzzleCub. Keeping the ad first matters — it is the route that works
/// right now, in this app, with no install. Leading with the cross-promo
/// would read as a wall in front of the Store rather than a suggestion.
Future<CoinRoute> showPuzzleCubSheet(
  BuildContext context, {
  required String itemName,
  required int price,
  required int balance,
  required int adReward,
  bool allowAds = true,
}) async {
  final result = await showModalBottomSheet<CoinRoute>(
    context: context,
    backgroundColor: ChaturangTheme.deepMaroon,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => _PuzzleCubSheet(
      itemName: itemName,
      price: price,
      balance: balance,
      adReward: adReward,
      allowAds: allowAds,
    ),
  );
  return result ?? CoinRoute.dismissed;
}

class _PuzzleCubSheet extends StatelessWidget {
  const _PuzzleCubSheet({
    required this.itemName,
    required this.price,
    required this.balance,
    required this.adReward,
    required this.allowAds,
  });

  final String itemName;
  final int price;
  final int balance;
  final int adReward;
  final bool allowAds;

  @override
  Widget build(BuildContext context) {
    final short = price - balance;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ChaturangTheme.parchment.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Not enough coins',
              style: TextStyle(
                fontFamily: 'RoyalSans',
                color: ChaturangTheme.saffronLight,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$itemName costs $price. You have $balance — '
              '$short to go.',
              style: TextStyle(
                color: ChaturangTheme.secondaryText,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            if (allowAds)
              _Choice(
                icon: Icons.play_circle_outline,
                title: 'Watch an ad',
                detail: 'Earn $adReward coins now.',
                onTap: () => Navigator.of(context).pop(CoinRoute.watchAd),
                emphasised: true,
              ),
            const SizedBox(height: 10),
            _Choice(
              icon: Icons.extension,
              title: 'Try ${CrossPromo.appName}',
              detail: VaultAvailability.instance.isLive
                  // "once you link the two" is doing real work. Coins are
                  // not shared automatically — the two games have to be
                  // joined with a code first. Saying they are shared, flat,
                  // would send a player to install PuzzleCub, find an empty
                  // balance, and conclude it is broken.
                  ? '${CrossPromo.blurb} Coins are shared once you link '
                        'the two.'
                  // Future tense while the vault is not shipped on both
                  // sides. Saying they move would be a lie the player
                  // discovers by testing it.
                  : '${CrossPromo.blurb} Coins there will be shared with '
                        'Chaturang soon.',
              onTap: () async {
                final uri = Uri.parse(CrossPromo.storeUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (context.mounted) {
                  Navigator.of(context).pop(CoinRoute.visitedPuzzleCub);
                }
              },
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(CoinRoute.dismissed),
                child: Text(
                  'Not now',
                  style: TextStyle(color: ChaturangTheme.secondaryText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.emphasised = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: emphasised ? 0.28 : 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: emphasised
                ? ChaturangTheme.saffron.withValues(alpha: 0.75)
                : ChaturangTheme.parchment.withValues(alpha: 0.16),
            width: emphasised ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: ChaturangTheme.saffronLight, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'RoyalSans',
                        color: ChaturangTheme.parchment,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: TextStyle(
                        color: ChaturangTheme.secondaryText,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
