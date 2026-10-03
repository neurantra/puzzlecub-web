import 'package:flutter/material.dart';
import '../data/maze_pack.dart';
import '../services/packs/language_packs.dart';
import '../domain/maze.dart';
import '../data/player_store.dart';
import '../domain/maze_level.dart';
import '../domain/hunt_options.dart';
import '../services/purchases/purchase_service.dart';
import '../domain/puzzle_language.dart';
import 'language_store_screen.dart';

class PreparedHunt {
  const PreparedHunt(
    this.pack,
    this.options, {
    this.language = 'en',
    this.revision = 1,
  });
  final String language;
  final int revision;
  final MazePack pack;
  final HuntOptions options;
}

/// Start with saved settings, with no selection dialog. Callers show the price
/// on their start action and prevent duplicate taps until this completes.
Future<PreparedHunt?> prepareHunt(
  BuildContext context,
  PlayerStore store,
  MazeLevel level, {
  required bool relaxed,
  LanguagePacks? packs,
  PurchaseService? purchases,
}) async {
  final language = store.language;
  final chosen = relaxed ? const HuntOptions() : store.huntOptions(level);
  try {
    if (purchases != null && purchases.mazeLimit(language) == 0) {
      if (purchases.freeLanguage == null) {
        if (!context.mounted) return null;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Choose your free language'),
            content: Text(
              'Use ${PuzzleLanguage.of(language).name} for your 10 free mazes per level? To pick a different language, cancel and open Download languages.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Use this language'),
              ),
            ],
          ),
        );
        if (confirm != true) return null;
        await purchases.chooseFreeLanguage(language);
      } else {
        if (!context.mounted) return null;
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                LanguageStoreScreen(store: store, purchases: purchases),
          ),
        );
        return null;
      }
    }
    var pack = packs != null
        ? await packs.load(language, level)
        : language == 'en'
        ? await MazePackLoader.load(level)
        : throw StateError('Language not installed');
    if (purchases != null) pack = purchases.playablePack(language, pack);
    if (!context.mounted) return null;
    if (chosen.cost > 0 && !await store.purchaseHunt(chosen.cost)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Not enough coins, or a transfer is pending. Change Hunt limits in Settings to use the free defaults.',
            ),
          ),
        );
      }
      return null;
    }
    return PreparedHunt(
      pack,
      chosen,
      language: language,
      revision: packs?.installedRevision(language) ?? 1,
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not start this hunt. Your coins have not been charged. Please try again.',
          ),
        ),
      );
    }
    return null;
  }
}

class HuntSettings extends StatefulWidget {
  const HuntSettings({
    super.key,
    required this.store,
    required this.initialLevel,
  });
  final PlayerStore store;
  final MazeLevel initialLevel;
  @override
  State<HuntSettings> createState() => _HuntSettingsState();
}

class _HuntSettingsState extends State<HuntSettings> {
  late MazeLevel level = widget.initialLevel;
  bool saving = false;
  String? error;
  Future<void> save(HuntOptions value) async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.store.setHuntOptions(level, value);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Could not save hunt settings. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.store.huntOptions(level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hunt limits',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choices are remembered for each difficulty. Changing settings is free; upgrades cost coins each time you start a timed hunt. Scenic Route stays unlimited and free.',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          children: [
            for (final item in MazeLevel.values)
              ChoiceChip(
                key: ValueKey('settings-level-${item.name}'),
                label: Text(item.label),
                selected: level == item,
                onSelected: saving
                    ? null
                    : (_) => setState(() {
                        level = item;
                        error = null;
                      }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Time limit', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 6,
          children: [
            for (var tier = 0; tier <= 2; tier++)
              ChoiceChip(
                key: ValueKey('time-tier-$tier'),
                selected: options.timeTier == tier,
                label: Text(
                  '${(level.defaultSeconds + tier * 60) ~/ 60}:${((level.defaultSeconds + tier * 60) % 60).toString().padLeft(2, '0')} · ${tier == 0 ? "Free" : "${tier * 30} coins"}',
                ),
                onSelected: saving
                    ? null
                    : (_) => save(
                        HuntOptions(
                          timeTier: tier,
                          attemptTier: options.attemptTier,
                        ),
                      ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Invalid attempts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 6,
          children: [
            for (var tier = 0; tier <= 2; tier++)
              ChoiceChip(
                key: ValueKey('attempt-tier-$tier'),
                selected: options.attemptTier == tier,
                label: Text(
                  '${level.invalidAttemptBudget + tier * 2} · ${tier == 0 ? "Free" : "${tier * 30} coins"}',
                ),
                onSelected: saving
                    ? null
                    : (_) => save(
                        HuntOptions(
                          timeTier: options.timeTier,
                          attemptTier: tier,
                        ),
                      ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Total: ${options.priceLabel} per timed hunt',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (error != null) Text(error!),
      ],
    );
  }
}
