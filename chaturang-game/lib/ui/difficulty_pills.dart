import 'package:flutter/material.dart';

import '../data/stats_service.dart';
import '../engine/difficulty.dart';
import 'theme.dart';

/// Shared Easy / Medium / Hard selection for setup and settings.
///
/// Shared by the Settings sheet and the card-pick screen, so the level a
/// player chooses before the first card is turned looks like — and is —
/// the same control they will find in Settings mid-game. Locked pills are
/// dimmed, carry a small lock icon, and drop the tap; the hosting screen
/// decides whether to explain the lock.
class DifficultyPills extends StatelessWidget {
  const DifficultyPills({
    super.key,
    required this.listenable,
    this.enabled = true,
  });

  final ValueNotifier<Difficulty> listenable;

  /// False freezes the row — used once a card has been picked and the
  /// game is about to start.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Stats drive the locked state — re-render when win counts change.
    return AnimatedBuilder(
      animation: StatsService.instance,
      builder: (context, _) {
        final stats = StatsService.instance.stats;
        return ValueListenableBuilder<Difficulty>(
          valueListenable: listenable,
          builder: (context, current, _) {
            return Row(
              children: [
                for (final level in Difficulty.values) ...[
                  Expanded(
                    child: SelectionPill(
                      label: level.label,
                      selected: level == current,
                      locked: !level.isUnlockedBy(
                        easyWins: stats.easyWins,
                        mediumWins: stats.mediumWins,
                      ),
                      onTap: enabled ? () => listenable.value = level : null,
                    ),
                  ),
                  if (level != Difficulty.values.last) const SizedBox(width: 8),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// One selectable pill. Also used by the move-limit row, which has no
/// locking, hence the default.
class SelectionPill extends StatelessWidget {
  const SelectionPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final bool selected;
  final bool locked;

  /// Null renders the pill inert without the locked styling.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Locked pills render dim and uninteractive — tap is dropped via
    // onTap: null so the parent's unlock hint is the only feedback.
    final fill = locked
        ? Colors.transparent
        : selected
        ? ChaturangTheme.saffron.withValues(alpha: 0.85)
        : Colors.transparent;
    final border = locked
        ? ChaturangTheme.parchment.withValues(alpha: 0.18)
        : selected
        ? ChaturangTheme.saffronLight
        : ChaturangTheme.saffron.withValues(alpha: 0.55);
    final text = locked
        ? ChaturangTheme.parchment.withValues(alpha: 0.35)
        : selected
        ? ChaturangTheme.deepMaroon
        : ChaturangTheme.parchment;
    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: border, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (locked) ...[
              Icon(
                Icons.lock,
                size: 14,
                color: ChaturangTheme.parchment.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'RoyalSans',
                  color: text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
