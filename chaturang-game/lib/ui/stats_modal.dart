import 'package:flutter/material.dart';

import '../data/ads_service.dart';
import '../data/stats_service.dart';
import '../data/vault_availability.dart';
import 'store_modal.dart';
import 'vault_modal.dart';
import 'theme.dart';

/// Opens a bottom-sheet modal showing the player's lifetime statistics.
/// Values come from [StatsService] and rebuild live whenever the service
/// notifies listeners (e.g., after a game finishes).
Future<void> showStatsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ChaturangTheme.deepMaroon,
    // Same fix as Settings — with the Watch-ad + Store buttons added,
    // the modal exceeds the default half-screen cap on smaller iPhones.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: StatsService.instance,
          builder: (context, _) {
            final stats = StatsService.instance.stats;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _DragHandle(),
                  const SizedBox(height: 12),
                  Text(
                    'Statistics',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'RoyalSans',
                      color: ChaturangTheme.saffronLight,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // The balance is the way into the shared vault, matching
                  // PuzzleCub's coin pill. Only wired up while the feature
                  // is live — off means absent, never a dead tap.
                  _StatRow(
                    icon: Icons.monetization_on,
                    label: 'Coins',
                    value: StatsService.instance.coins.toString(),
                    onTap: VaultAvailability.instance.isLive
                        ? () => showVaultSheet(context)
                        : null,
                  ),
                  _StatRow(
                    icon: Icons.sports_esports,
                    label: 'Games played',
                    value: stats.gamesPlayed.toString(),
                  ),
                  _StatRow(
                    icon: Icons.emoji_events,
                    label: 'Games won',
                    value: stats.gamesWon.toString(),
                  ),
                  _StatRow(
                    icon: Icons.cancel,
                    label: 'Games lost',
                    value: stats.gamesLost.toString(),
                  ),
                  _StatRow(
                    icon: Icons.handshake,
                    label: 'Games drawn',
                    value: stats.gamesDrawn.toString(),
                  ),
                  _StatRow(
                    icon: Icons.local_fire_department,
                    label: 'Current streak',
                    value:
                        '${stats.currentStreak} '
                        '${stats.currentStreak == 1 ? "day" : "days"}',
                  ),
                  _StatRow(
                    icon: Icons.star,
                    label: 'Longest streak',
                    value:
                        '${stats.longestStreak} '
                        '${stats.longestStreak == 1 ? "day" : "days"}',
                  ),
                  // Online (human-vs-human) section. Only renders once
                  // the player has actually played at least one online
                  // game — keeps the modal uncluttered for offline-only
                  // users while still giving online players visibility
                  // into their record.
                  if (stats.onlineGamesPlayed > 0) ...[
                    const SizedBox(height: 14),
                    const _SectionHeader(label: 'Online'),
                    const SizedBox(height: 6),
                    _StatRow(
                      icon: Icons.public,
                      label: 'Online games',
                      value: stats.onlineGamesPlayed.toString(),
                    ),
                    _StatRow(
                      icon: Icons.emoji_events,
                      label: 'Online wins',
                      value: stats.onlineWon.toString(),
                    ),
                    _StatRow(
                      icon: Icons.cancel,
                      label: 'Online losses',
                      value: stats.onlineLost.toString(),
                    ),
                    _StatRow(
                      icon: Icons.handshake,
                      label: 'Online draws',
                      value: stats.onlineDrawn.toString(),
                    ),
                  ],
                  // "Watch ad → +coins" CTA, only rendered when AdMob
                  // is actually available. Listens to AdsService so it
                  // appears/disappears live as init succeeds or fails.
                  ListenableBuilder(
                    listenable: AdsService.instance,
                    builder: (context, _) {
                      if (!AdsService.instance.coinAdsAvailable) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _RewardedAdButton(),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _StoreButton(),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

/// Opens the Store sheet. Always visible in Stats — even if the player has
/// zero coins, seeing the entry point hints at where the balance is heading.
class _StoreButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => showStoreSheet(context),
        icon: const Icon(
          Icons.storefront_outlined,
          color: ChaturangTheme.saffronLight,
        ),
        label: Text(
          'Visit the store',
          style: TextStyle(
            fontFamily: 'RoyalSans',
            color: ChaturangTheme.parchment,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: ChaturangTheme.saffronLight.withValues(alpha: 0.55),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _RewardedAdButton extends StatefulWidget {
  @override
  State<_RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<_RewardedAdButton> {
  bool _busy = false;

  Future<void> _onTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AdsService.instance.requestRewarded();
      // Success/failure feedback already shows up via the live coin
      // counter in the modal above. No toast needed.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const reward = coinsForRewardedAd;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _onTap,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ChaturangTheme.saffronLight,
                ),
              )
            : const Icon(
                Icons.play_circle_outline,
                color: ChaturangTheme.saffronLight,
              ),
        label: Text(
          _busy ? 'Loading…' : 'Watch ad   +$reward coins',
          style: TextStyle(
            fontFamily: 'RoyalSans',
            color: ChaturangTheme.parchment,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(
            color: ChaturangTheme.saffronLight,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: ChaturangTheme.parchment.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Small left-aligned label with a thin underline that visually
/// separates groups of [_StatRow]s in the modal. Used to break out the
/// Online section so its W-L-D doesn't get visually conflated with the
/// AI-mode counters above.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'RoyalSans',
              color: ChaturangTheme.saffronLight.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: ChaturangTheme.saffronLight.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;

  /// When set, the whole row is tappable and shows a chevron so the player
  /// can tell it leads somewhere.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: ChaturangTheme.saffronLight, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'RoyalSans',
                color: ChaturangTheme.parchment,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'RoyalSans',
              color: ChaturangTheme.saffronLight,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: ChaturangTheme.parchment.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: row,
    );
  }
}
