import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../geo/domain/geo_region.dart';
import '../services/atlas_commerce.dart';
import '../services/map_unlocks.dart';
import 'theme.dart';

Future<void> showRecovery(BuildContext context, MapUnlocks unlocks) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (_) => RecoverySheet(unlocks: unlocks),
    );

class RecoverySheet extends StatefulWidget {
  const RecoverySheet({super.key, required this.unlocks});
  final MapUnlocks unlocks;
  @override
  State<RecoverySheet> createState() => _RecoverySheetState();
}

class _RecoverySheetState extends State<RecoverySheet> {
  final _input = TextEditingController();
  bool _saved = false;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.unlocks,
    builder: (context, _) {
      final u = widget.unlocks;
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.key_rounded, color: teal, size: 40),
              const SizedBox(height: 12),
              Text(
                u.hasRecovery
                    ? 'Your map recovery code'
                    : 'Keep your maps, wherever you go',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No email or password. Save your private recovery code to restore purchased map pairs on another device. It restores map ownership, not game progress.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 14),
              if (u.hasRecovery) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SelectableText(
                    u.code!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .6,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: u.code!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Recovery code copied. Store it somewhere safe.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy recovery code'),
                ),
                const Text(
                  'Keep this code private. Anyone with it can access your map collection. If you lose it and your device data, we cannot recover the code for you.',
                  style: TextStyle(color: muted, height: 1.5),
                ),
                if (!u.savedCode) ...[
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _saved,
                    onChanged: u.busy
                        ? null
                        : (v) => setState(() => _saved = v ?? false),
                    title: const Text('I saved my code outside this app'),
                  ),
                  FilledButton(
                    onPressed: !_saved || u.busy
                        ? null
                        : () async {
                            await u.confirmSavedCode();
                            if (context.mounted && u.savedCode) {
                              Navigator.pop(context);
                            }
                          },
                    child: const Text('Continue'),
                  ),
                ] else
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
              ] else ...[
                FilledButton.icon(
                  onPressed: u.busy || !u.configured ? null : u.create,
                  icon: const Icon(Icons.key),
                  label: const Text('Create my recovery code'),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Already have a code?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _input,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Paste your recovery code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: u.busy || !u.configured
                      ? null
                      : () async {
                          await u.recover(_input.text);
                          if (context.mounted &&
                              u.hasRecovery &&
                              u.message ==
                                  'Your purchased maps are restored.') {
                            Navigator.pop(context);
                          }
                        },
                  child: const Text('Recover my maps'),
                ),
              ],
              if (u.busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (u.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(u.message!, style: const TextStyle(color: muted)),
                ),
              if (!u.configured)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Map-pair recovery is not available in this build yet.',
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showMapPairs(
  BuildContext context,
  AtlasCommerce commerce, {
  GeoRegion? initial,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: paper,
  builder: (_) => MapPairsSheet(commerce: commerce, initial: initial),
);

class MapPairsSheet extends StatefulWidget {
  const MapPairsSheet({super.key, required this.commerce, this.initial});
  final AtlasCommerce commerce;
  final GeoRegion? initial;
  @override
  State<MapPairsSheet> createState() => _MapPairsSheetState();
}

class _MapPairsSheetState extends State<MapPairsSheet> {
  final Set<GeoRegion> selected = {};
  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    if (r != null && r != GeoRegion.australia && !widget.commerce.allows(r)) {
      selected.add(r);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.commerce,
    builder: (context, _) {
      final c = widget.commerce, u = c.unlocks;
      final remaining = GeoRegion.values
          .where((r) => r != GeoRegion.australia && !c.allows(r))
          .toList();
      selected.removeWhere((r) => !remaining.contains(r));
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .85,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Eyebrow('YOUR NEXT TWO DESTINATIONS'),
                const SizedBox(height: 8),
                const Text(
                  'Choose your own adventure.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Keep two maps forever. Every play mode, no ads, and hints without watching ads on those maps.',
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 12),
                if (u.credits >= 2)
                  Text(
                    '${u.credits} map unlocks ready to use. No new payment needed.',
                    style: const TextStyle(
                      color: teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (c.fullAtlas || remaining.length < 2)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'You already own these destinations. Full Atlas unlocks any remaining maps.',
                    ),
                  ),
                if (u.pending) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Your last selection is saved. Check its confirmation before buying again.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(u.pendingMaps!.map(geoRegionLabel).join(' + ')),
                  OutlinedButton(
                    onPressed: u.busy ? null : u.sync,
                    child: const Text('Check purchase confirmation'),
                  ),
                  if (u.credits >= 2)
                    TextButton(
                      onPressed: u.busy ? null : u.changeSelection,
                      child: const Text(
                        'Choose different maps with my paid unlocks',
                      ),
                    ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    '${selected.where(remaining.contains).length} of 2 selected',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final r in remaining)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: CheckboxListTile(
                        tileColor: selected.contains(r)
                            ? const Color(0xFFE4EEE6)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          geoRegionLabel(r),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        value: selected.contains(r),
                        onChanged:
                            u.busy ||
                                (!selected.contains(r) && selected.length >= 2)
                            ? null
                            : (v) => setState(() {
                                if (v == true) {
                                  selected.add(r);
                                } else {
                                  selected.remove(r);
                                }
                              }),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed:
                        c.fullAtlas ||
                            u.busy ||
                            !u.configured ||
                            selected.where(remaining.contains).length != 2 ||
                            (u.credits < 2 && u.pairPrice == null)
                        ? null
                        : () async {
                            if (!u.savedCode) {
                              await showRecovery(context, u);
                              if (!context.mounted || !u.savedCode) return;
                            }
                            final maps = selected.toList();
                            await u.buyPair(maps);
                            if (context.mounted &&
                                maps.every(u.maps.contains)) {
                              Navigator.pop(context);
                            }
                          },
                    child: Text(
                      u.busy
                          ? 'Confirming your maps…'
                          : u.credits >= 2
                          ? 'Unlock my two maps'
                          : 'Unlock two maps · ${u.pairPrice ?? 'Unavailable'}',
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const Text(
                  'Want everything later? After your first pair, a fixed loyalty price is available for Full Atlas. Buying more pairs does not reduce that price further.',
                  style: TextStyle(color: muted, height: 1.5),
                ),
                if (u.message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      u.message!,
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
