import 'package:flutter/material.dart';

import '../game/difficulty.dart';
import '../game/session.dart';
import '../services/session_store.dart';
import 'onboarding.dart';
import 'game_control.dart';
import '../services/puzzle_factory.dart';
import 'play.dart';
import 'rules.dart';
import 'settings.dart';
import 'style.dart';
import 'techniques.dart';
import 'upgrades.dart';
import '../services/access_store.dart';
import '../game/puzzle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Difficulty selected = Difficulty.medium;
  bool building = false, loading = true, needsTutorial = true;
  Session? saved;
  String? loadError;
  final store = SessionStore.instance;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    saved?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final restored = await store.load();
      final completed = await store.tutorialCompleted();
      if (!mounted) {
        restored?.dispose();
        return;
      }
      saved?.dispose();
      setState(() {
        saved = restored;
        needsTutorial = !completed;
        loading = false;
        loadError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          loadError =
              'Saved progress could not be loaded. Retry before starting a new puzzle.';
        });
      }
    }
  }

  Future<void> _tutorial() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OnboardingScreen(store: store)),
    );
    if (mounted) await _reload();
  }

  Future<void> _resume() async {
    final session = saved;
    if (session == null || building) return;
    setState(() {
      saved = null;
      building = true;
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayScreen(
          puzzle: session.puzzle,
          initialSession: session,
          store: store,
        ),
      ),
    );
    if (mounted) {
      setState(() => building = false);
      await _reload();
    }
  }

  Future<void> _play() async {
    if (building || loading) return;
    if (saved != null || loadError != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start a new puzzle?'),
          content: const Text(
            'There is one saved-game slot. Starting a new puzzle replaces the previous saved game.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep saved game'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start new puzzle'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    setState(() => building = true);
    Session? next;
    try {
      if (!await ensureAccess(context, AccessKind.puzzle, selected) ||
          !mounted) {
        return;
      }
      late final Puzzle puzzle;
      await useAccess(AccessKind.puzzle, selected, () async {
        puzzle = await buildPuzzle(selected);
        next = Session(puzzle)..pause();
        await store.save(next!);
      });
      if (!mounted) {
        next?.dispose();
        return;
      }
      saved?.dispose();
      setState(() {
        saved = null;
        loadError = null;
      });
      final launched = next;
      next = null;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlayScreen(
            puzzle: puzzle,
            initialSession: launched,
            store: store,
          ),
        ),
      );
      if (mounted) await _reload();
    } catch (_) {
      next?.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not create and save a puzzle. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => building = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const AlphadokuMark(size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alphadoku',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Text(
                            'Nine letters. One hidden line.',
                            style: TextStyle(fontSize: 13, color: muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => showRulesSheet(context),
                      icon: const Icon(Icons.help_outline_rounded),
                      color: muted,
                      tooltip: 'How to play',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (loading) const LinearProgressIndicator(),
                if (loadError != null) ...[
                  Text(loadError!, style: const TextStyle(color: coral)),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Retry loading'),
                  ),
                ],
                if (saved != null) ...[
                  FilledButton.icon(
                    onPressed: building ? null : _resume,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Continue ${saved!.puzzle.difficulty.label}'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${saved!.puzzle.phrase.text} · ${saved!.board.filledCount}/81 filled',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted),
                  ),
                  const SizedBox(height: 16),
                ],
                if (needsTutorial && !loading) ...[
                  Surface(
                    color: axisGlow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Your first hidden line',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Learn by placing a letter, ruling out a line and making your first reveal.',
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: building ? null : _tutorial,
                          child: const Text('Learn by playing'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Surface(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Choose a tier'),
                      const SizedBox(height: 12),
                      for (final d in Difficulty.values.where((d) => Uri.base.queryParameters['day'] == null || d == Difficulty.medium)) ...[
                        _TierTile(
                          difficulty: d,
                          selected: d == selected,
                          onTap: building
                              ? null
                              : () => setState(() => selected = d),
                        ),
                        if (d != Difficulty.values.last)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: building || loading ? null : _play,
                  child: building
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text('Play ${selected.label}'),
                ),
                const SizedBox(height: 18),
                const _RuleCard(),
                TextButton.icon(
                  onPressed: () => showTechniques(context),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Solving techniques'),
                ),
                TextButton.icon(
                  onPressed: () => openSettings(context),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Settings'),
                ),
                TextButton.icon(
                  onPressed: building ? null : _tutorial,
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Practice tutorial'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TierTile extends StatelessWidget {
  const _TierTile({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GameControl(
    label: '${difficulty.label}. ${difficulty.blurb}',
    selected: selected,
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? mint : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? teal : ink.withValues(alpha: .10),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                difficulty.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              Pill('${difficulty.minGivens}-${difficulty.maxGivens} given'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            difficulty.blurb,
            style: const TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    ),
  );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard();

  @override
  Widget build(BuildContext context) => Surface(
    color: axisGlow,
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.auto_awesome_rounded, size: 16, color: gold),
            SizedBox(width: 8),
            Eyebrow('The twist', color: Color(0xFF8A6412)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Every puzzle is a Sudoku made of nine letters instead of nine '
          'digits. Exactly one row or one column spells the target phrase in '
          'order. Medium fills the line when you find it. Hard and Pro '
          'ask you to fill every letter yourself.',
          style: TextStyle(fontSize: 13, height: 1.45, color: ink),
        ),
      ],
    ),
  );
}
