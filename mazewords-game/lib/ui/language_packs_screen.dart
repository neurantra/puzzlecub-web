import 'package:flutter/material.dart';
import '../data/player_store.dart';
import '../domain/maze_level.dart';
import '../domain/puzzle_language.dart';
import '../services/packs/language_packs.dart';
import 'age_information.dart';
import 'language_flag.dart';
import 'language_store_screen.dart';
import '../services/purchases/purchase_service.dart';

class LanguagePacksScreen extends StatefulWidget {
  const LanguagePacksScreen({
    super.key,
    required this.store,
    required this.packs,
    this.updateOnOpen = false,
    this.purchases,
  });
  final PurchaseService? purchases;
  final bool updateOnOpen;
  final PlayerStore store;
  final LanguagePacks packs;
  @override
  State<LanguagePacksScreen> createState() => _LanguagePacksScreenState();
}

class _LanguagePacksScreenState extends State<LanguagePacksScreen> {
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await widget.packs.initialize();
    } catch (_) {
      error = 'The pack list could not load. English is still available.';
    }
    if (mounted) {
      setState(() => loading = false);
      if (widget.updateOnOpen) await _update();
    }
  }

  Future<bool> _allowDownload() async {
    if (widget.store.adult) return true;
    return ageParentGate(
      context,
      explanation:
          'Ask a parent or grown-up to check or download puzzle packs. Solve this to continue.',
    );
  }

  Future<void> _update() async {
    if (await _allowDownload() && mounted) {
      setState(() => error = null);
      await widget.packs.updateWords();
    }
  }

  Future<void> _use(PackEntry entry) async {
    try {
      await widget.packs.load(entry.id, MazeLevel.easy);
      await widget.store.selectLanguage(entry.id);
      if (mounted) setState(() => error = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Could not select this language. Try downloading its pack again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.store, widget.packs]),
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Download languages')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Choose your puzzle language',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Downloaded packs work offline. English is always included. Your coins stay with you; best scores are kept separately for each language.',
            ),
            const SizedBox(height: 8),
            const Text(
              'The daily coin reward can be earned once per day across all languages. Updating a pack never resets it.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Found an error or discrepancy in any language? Please contact us through Settings → Contact with the language, word, difficulty, and a screenshot of the maze.',
            ),
            if (widget.purchases != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock languages / Restore purchases'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => LanguageStoreScreen(
                      store: widget.store,
                      purchases: widget.purchases!,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: loading || widget.packs.busy ? null : _update,
              icon: const Icon(Icons.refresh),
              label: const Text('Update / refresh words'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 12),
              child: Text(
                'Checks for new words and updates your installed packs. New languages download only when you choose them.',
              ),
            ),
            if (widget.packs.updateSummary != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  widget.packs.updateSummary!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (loading || widget.packs.busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              ),
            if (error != null || widget.packs.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  error ?? widget.packs.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            for (final entry in widget.packs.entries)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (entry.supported)
                            LanguageFlag(entry.id)
                          else
                            const Icon(Icons.language),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.purchases != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            widget.purchases!.mazeLimit(entry.id) == 150
                                ? 'Full language unlocked'
                                : widget.purchases!.mazeLimit(entry.id) == 10
                                ? 'Free language · 10 mazes per level'
                                : 'Full access available in Unlock languages',
                          ),
                        ),
                      if (entry.difficultyCounts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Easy: ${entry.difficultyCounts['easy']} · Medium: ${entry.difficultyCounts['medium']} · Hard: ${entry.difficultyCounts['hard']}',
                          ),
                        ),
                      if (PuzzleLanguage.of(entry.id).indic)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Vowel signs and letter clusters stay together on one tile. Find words of two or more tiles. Menus stay in English.',
                          ),
                        ),
                      if (entry.preview)
                        const Text(
                          'Starter preview · a smaller collection to explore',
                        ),
                      Text(
                        widget.packs.installed(entry.id)
                            ? 'Installed v${widget.packs.installedRevision(entry.id)}${entry.revision > widget.packs.installedRevision(entry.id) ? " · v${entry.revision} available" : ""}'
                            : '${(entry.bytes / 1024).ceil()} KB download',
                      ),
                      if (entry.id == 'ja')
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Hiragana words. Combinations such as きゃ stay on one tile; small っ is its own tile. No kanji or katakana. Menus stay in English.',
                          ),
                        ),
                      if (entry.id == 'de')
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'German spelling is preserved: Ä, Ö, Ü and capital ẞ have their own tiles.',
                          ),
                        ),
                      if (entry.id == 'fr' || entry.id == 'pt-BR')
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Accents are preserved on letter tiles. Menus stay in English.',
                          ),
                        ),
                      if (entry.id == 'es')
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Spanish spelling is preserved: Ñ, Á, É, Í, Ó, Ú and Ü are distinct letter tiles. Menus stay in English.',
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (!entry.supported)
                        const Text(
                          'This pack needs a newer version of Maze Words.',
                        )
                      else if (entry.access != 'free')
                        const Text(
                          'Paid pack · purchases are not available in this version.',
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            if (entry.revision >
                                widget.packs.installedRevision(entry.id))
                              FilledButton.icon(
                                onPressed: widget.packs.busy
                                    ? null
                                    : () async {
                                        if (await _allowDownload() && mounted) {
                                          await widget.packs.install(entry);
                                        }
                                      },
                                icon: const Icon(Icons.download),
                                label: Text(
                                  '${widget.packs.installed(entry.id) ? "Update" : "Download"} · ${(entry.bytes / 1024).ceil()} KB',
                                ),
                              ),
                            if (widget.packs.installed(entry.id))
                              OutlinedButton.icon(
                                onPressed:
                                    widget.packs.busy ||
                                        widget.store.language == entry.id
                                    ? null
                                    : () => _use(entry),
                                icon: Icon(
                                  widget.store.language == entry.id
                                      ? Icons.check_circle
                                      : Icons.language,
                                ),
                                label: Text(
                                  widget.store.language == entry.id
                                      ? 'Selected'
                                      : 'Use ${PuzzleLanguage.of(entry.id).name}',
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
