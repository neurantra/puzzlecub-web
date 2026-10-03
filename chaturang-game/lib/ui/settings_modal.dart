import 'package:flutter/material.dart';

import '../audio/audio_service.dart';
import '../data/ads_service.dart';
import '../data/stats_service.dart';
import '../engine/difficulty.dart';
import '../engine/move_limit.dart';
import 'difficulty_pills.dart';
import 'theme.dart';

/// Opens a bottom-sheet modal with the Settings UI: difficulty, sound
/// on/off, timed/untimed game-mode toggle.
///
/// Difficulty and sound persist across launches; game options are session-only.
Future<void> showSettingsSheet(
  BuildContext context, {
  required ValueNotifier<Difficulty> difficulty,
  required ValueNotifier<bool> soundEnabled,
  required ValueNotifier<bool> timedMode,
  required ValueNotifier<MoveLimit> moveLimit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ChaturangTheme.deepMaroon,
    // Allow the sheet to grow past the default half-screen when needed
    // — with difficulty + sound + timed + move-limit rows the content
    // exceeds the default cap on smaller iPhones.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DragHandle(),
              ListenableBuilder(
                listenable: AdsService.instance,
                builder: (context, _) =>
                    AdsService.instance.privacyOptionsRequired
                    ? TextButton(
                        onPressed: AdsService.instance.showPrivacyOptions,
                        child: const Text('Ad privacy choices'),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Text(
                'Settings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'RoyalSans',
                  color: ChaturangTheme.saffronLight,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _DifficultyRow(listenable: difficulty),
              const SizedBox(height: 8),
              _ToggleRow(
                icon: Icons.volume_up,
                label: 'Sound effects',
                listenable: soundEnabled,
                value: () => soundEnabled.value,
                onChanged: (value) {
                  soundEnabled.value = value;
                  AudioService.instance.enabled = value;
                },
              ),
              const SizedBox(height: 8),
              _ToggleRow(
                icon: Icons.hourglass_bottom,
                label: 'Timed game',
                subtitle:
                    '5-minute blitz per side; toggling on resets the clocks',
                listenable: timedMode,
                value: () => timedMode.value,
                onChanged: (value) => timedMode.value = value,
              ),
              const SizedBox(height: 8),
              _MoveLimitRow(listenable: moveLimit),
            ],
          ),
        ),
      );
    },
  );
}

/// Same scrollable / size-friendly fix used for the matching Stats and
/// About sheets when their content grows.

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

/// Three-pill segmented row for Easy / Medium / Hard with unlock-by-win
/// progression. Easy is always unlocked; Medium opens after 3 Easy wins,
/// Hard after 5 Medium wins. Locked pills are dimmed, render a small lock
/// icon, and tapping shows the wins-remaining hint instead of selecting.
class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.listenable});

  final ValueNotifier<Difficulty> listenable;

  @override
  Widget build(BuildContext context) {
    // Stats drive the locked state — re-render when win counts change.
    return AnimatedBuilder(
      animation: StatsService.instance,
      builder: (context, _) {
        final stats = StatsService.instance.stats;
        return Builder(
          builder: (context) {
            return Container(
              decoration: BoxDecoration(
                color: ChaturangTheme.charcoal.withValues(alpha: 0.30),
                border: Border.all(
                  color: ChaturangTheme.saffron.withValues(alpha: 0.40),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology_alt,
                        color: ChaturangTheme.saffronLight,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Difficulty',
                        style: TextStyle(
                          fontFamily: 'RoyalSans',
                          color: ChaturangTheme.parchment,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DifficultyPills(listenable: listenable),
                  // Render the most-relevant unlock hint below the pills.
                  ..._lockHints(stats),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _lockHints(PlayerStats stats) {
    final hints = <Widget>[];
    for (final level in [Difficulty.medium, Difficulty.hard]) {
      final remaining = level.winsRemainingToUnlock(
        easyWins: stats.easyWins,
        mediumWins: stats.mediumWins,
      );
      if (remaining == 0) continue;
      final gate = level.gatedBy!.label;
      hints.add(
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${level.label}: win $remaining more $gate '
            '${remaining == 1 ? "game" : "games"} to unlock',
            style: TextStyle(color: ChaturangTheme.secondaryText, fontSize: 11),
          ),
        ),
      );
    }
    return hints;
  }
}

/// Move-count cap row. Reuses the same pill style as Difficulty so the
/// Settings sheet has a consistent visual rhythm. Selecting a pill writes
/// to [listenable]; "Off" is the default and means no cap.
class _MoveLimitRow extends StatelessWidget {
  const _MoveLimitRow({required this.listenable});

  final ValueNotifier<MoveLimit> listenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MoveLimit>(
      valueListenable: listenable,
      builder: (context, current, _) {
        return Container(
          decoration: BoxDecoration(
            color: ChaturangTheme.charcoal.withValues(alpha: 0.30),
            border: Border.all(
              color: ChaturangTheme.saffron.withValues(alpha: 0.40),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.format_list_numbered,
                    color: ChaturangTheme.saffronLight,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Move limit',
                    style: TextStyle(
                      fontFamily: 'RoyalSans',
                      color: ChaturangTheme.parchment,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'full moves; draw if reached',
                      style: TextStyle(
                        color: ChaturangTheme.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final limit in MoveLimit.values) ...[
                    Expanded(
                      child: SelectionPill(
                        label: limit.label,
                        selected: limit == current,
                        onTap: () => listenable.value = limit,
                      ),
                    ),
                    if (limit != MoveLimit.values.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.listenable,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Listenable listenable;

  /// Read lazily rather than passed by value so the row reflects whatever
  /// the listenable currently holds — [ValueNotifier] or service alike.
  final bool Function() value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final value = this.value();
        return Container(
          decoration: BoxDecoration(
            color: ChaturangTheme.charcoal.withValues(alpha: 0.30),
            border: Border.all(
              color: ChaturangTheme.saffron.withValues(alpha: 0.40),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: ChaturangTheme.saffronLight, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'RoyalSans',
                        color: ChaturangTheme.parchment,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: ChaturangTheme.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: ChaturangTheme.saffronLight,
                activeTrackColor: ChaturangTheme.saffron.withValues(
                  alpha: 0.55,
                ),
                inactiveThumbColor: ChaturangTheme.parchment.withValues(
                  alpha: 0.6,
                ),
                inactiveTrackColor: ChaturangTheme.charcoal.withValues(
                  alpha: 0.7,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
