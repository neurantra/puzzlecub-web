import 'dart:async';
import 'package:flutter/material.dart';
import '../services/atlas_commerce.dart';
import '../geo/domain/geo_region.dart';
import 'theme.dart';
import 'map_unlocks_sheet.dart';

Future<bool> showFullAtlas(
  BuildContext context,
  AtlasCommerce commerce, {
  String? trialMap,
  GeoRegion? region,
}) async {
  unawaited(commerce.refreshPrice());
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: paper,
    builder: (context) => ListenableBuilder(
      listenable: commerce,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.public, size: 64, color: teal),
              const SizedBox(height: 18),
              const Eyebrow('YOUR FULL ATLAS'),
              const SizedBox(height: 8),
              Text(
                commerce.fullAtlas
                    ? 'The world is yours.'
                    : 'So much more to discover.',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 14),
              if (!commerce.fullAtlas &&
                  (trialMap != null ||
                      commerce.trialRegion != null ||
                      commerce.trialExhausted)) ...[
                Text(
                  commerce.trialExhausted
                      ? 'Your free map trial on this device is complete. Unlock Full Atlas to continue on any map. Australia remains completely free.'
                      : commerce.trialRegion != null
                      ? 'Your one-map trial is on ${geoRegionLabel(commerce.trialRegion!)}. Unlock Full Atlas to explore the other maps. Australia remains completely free.'
                      : 'Unlock Full Atlas to finish $trialMap. Your progress is saved.',
                  style: const TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 14),
              ],
              const Text(
                'All 18 maps. Every play mode.\nNo ads. Hints without watching ads.',
                style: TextStyle(fontSize: 16, height: 1.7, color: ink),
              ),
              const SizedBox(height: 12),
              const Text(
                'One purchase. No subscription. Your unlocked maps work offline.',
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              if (!commerce.fullAtlas)
                FilledButton(
                  onPressed:
                      commerce.busy ||
                          commerce.unlocks.busy ||
                          (commerce.unlocks.loyalty
                                  ? commerce.unlocks.upgradePrice
                                  : commerce.price) ==
                              null
                      ? null
                      : commerce.unlocks.loyalty
                      ? commerce.buyUpgrade
                      : commerce.buy,
                  child: Text(
                    commerce.busy
                        ? 'Connecting to the store…'
                        : (commerce.unlocks.loyalty
                                  ? commerce.unlocks.upgradePrice
                                  : commerce.price) ==
                              null
                        ? 'Purchase unavailable'
                        : commerce.unlocks.loyalty
                        ? 'Upgrade to Full Atlas · ${commerce.unlocks.upgradePrice}'
                        : 'Unlock Full Atlas · ${commerce.price}',
                  ),
                ),
              if (!commerce.fullAtlas && commerce.unlocks.configured) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: commerce.busy || commerce.unlocks.busy
                      ? null
                      : () => showMapPairs(context, commerce, initial: region),
                  child: Text(
                    commerce.unlocks.credits >= 2
                        ? 'Use my map unlocks'
                        : 'Choose any two maps · ${commerce.unlocks.pairPrice ?? 'Check availability'}',
                  ),
                ),
                if (commerce.unlocks.loyalty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Your loyalty upgrade price stays the same after each pair.',
                      style: TextStyle(color: muted),
                    ),
                  ),
              ],
              if (commerce.unlocks.configured)
                TextButton(
                  onPressed: commerce.busy || commerce.unlocks.busy
                      ? null
                      : () => showRecovery(context, commerce.unlocks),
                  child: const Text('Recover map pairs / View recovery code'),
                ),
              if (commerce.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    commerce.message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted, height: 1.5),
                  ),
                ),
              if (!commerce.fullAtlas)
                TextButton(
                  onPressed:
                      commerce.busy || commerce.unlocks.busy || !commerce.ready
                      ? null
                      : commerce.restore,
                  child: const Text('Restore purchases'),
                ),
              if (!commerce.fullAtlas && commerce.price == null)
                TextButton(
                  onPressed: commerce.busy ? null : commerce.refreshPrice,
                  child: const Text('Try the store again'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  commerce.fullAtlas
                      ? 'Keep exploring'
                      : trialMap != null
                      ? 'Not now'
                      : 'Back to atlas',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return region == null ? commerce.fullAtlas : commerce.allows(region);
}
