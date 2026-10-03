import '../web_bridge.dart';
import '../services/purchases/revenuecat_gateway.dart';
import 'dart:async';
import 'hunt_setup.dart';
import '../domain/hunt_options.dart';
import 'dart:math';
import 'package:flutter/material.dart';

import '../data/player_store.dart';
import '../domain/hunt.dart';
import '../domain/maze_level.dart';
import '../services/game_services.dart';
import 'home_screen.dart';
import 'maze_board.dart';
import 'style.dart';
import 'vault_sheet.dart';
import 'success_celebration.dart';

class HuntScreen extends StatefulWidget {
  const HuntScreen({
    super.key,
    required this.store,
    required this.services,
    required this.level,
    this.relaxed = false,
    this.daily,
    this.prepared,
  });
  final PlayerStore store;
  final GameServices services;
  final MazeLevel level;
  final bool relaxed;
  final int? daily;
  final PreparedHunt? prepared;
  @override
  State<HuntScreen> createState() => _HuntScreenState();
}

class _HuntScreenState extends State<HuntScreen> with WidgetsBindingObserver {
  Hunt? _hunt;
  late final String _language =
      widget.prepared?.language ?? widget.store.language;
  Timer? _ticker;
  Timer? _hintTimer;
  Timer? _demoTimer;
  DateTime? _deadline;
  int _remaining = 0;
  int? _hint;
  String _message = '';
  bool _positive = true;
  FindResult? _lastResult;
  bool _tapMode = false;
  bool _paused = false;
  bool _recorded = false;
  bool _hintBusy = false;
  int? _earned;
  String? _error;
  String? _demoWord;
  List<int> _demo = [];

  @override
  void initState() {
    super.initState();
    _tapMode = widget.store.tapLetters;
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      var pack =
          widget.prepared?.pack ??
          await widget.services.packs.load(_language, widget.level);
      if (RevenueCatGateway.enabled) {
        pack = widget.services.purchases.playablePack(_language, pack);
      }
      if (!mounted) return;
      final index = widget.daily == null
          ? Random().nextInt(pack.mazes.length)
          : widget.daily! % pack.mazes.length;
      _remaining = (widget.prepared?.options ?? const HuntOptions()).seconds(
        widget.level,
      );
      _deadline = DateTime.now().add(Duration(seconds: _remaining));
      setState(
        () => _hunt = Hunt(
          maze: pack.mazes[index],
          level: widget.level,
          relaxed: widget.relaxed,
          options: widget.prepared?.options ?? const HuntOptions(),
        ),
      );
      if (!widget.relaxed) {
        _ticker = Timer.periodic(
          const Duration(milliseconds: 250),
          (_) => _tick(),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'This trail couldn’t load. Please try again.');
      }
    }
  }

  bool _leaving = false;
  Future<void> _nextTrail() async {
    if (_leaving) return;
    _leaving = true;
    await widget.services.afterRound();
    if (!mounted) return;
    final prepared = await prepareHunt(
      context,
      widget.store,
      widget.level,
      relaxed: widget.relaxed,
      packs: widget.services.packs,
      purchases: RevenueCatGateway.enabled ? widget.services.purchases : null,
    );
    if (prepared == null || !mounted) {
      _leaving = false;
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HuntScreen(
          store: widget.store,
          services: widget.services,
          level: widget.level,
          relaxed: widget.relaxed,
          daily: widget.daily,
          prepared: prepared,
        ),
      ),
    );
  }

  Future<void> _openVault() async {
    final wasPaused = _paused;
    if (_hunt != null && !_hunt!.finished && !wasPaused) _pause();
    await showCoinVault(context, widget.store, widget.services);
    if (mounted && _hunt != null && !_hunt!.finished && !wasPaused) _resume();
  }

  void _tick() {
    if (!mounted ||
        _hunt == null ||
        _hunt!.finished ||
        _paused ||
        widget.relaxed) {
      return;
    }
    final left = max(
      0,
      (_deadline!.difference(DateTime.now()).inMilliseconds / 1000).ceil(),
    );
    if (_remaining != left) setState(() => _remaining = left);
    if (left == 0) _finish();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
      unawaited(widget.services.recoverVault());
    }
    // Timed rounds use a real deadline, so backgrounding never extends them.
    if (state != AppLifecycleState.resumed && _hunt != null) {
      _hunt!.path.clear();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _hintTimer?.cancel();
    _demoTimer?.cancel();
    super.dispose();
  }

  Future<void> _finish() async {
    final hunt = _hunt;
    if (hunt == null || _recorded) return;
    _recorded = true;
    _ticker?.cancel();
    _hintTimer?.cancel();
    setState(() {
      hunt.finish();
      _hint = null;
      _paused = false;
    });
    if (hunt.cleared) reportGameAction(true);
    final earned = await widget.store.record(
      level: widget.level,
      relaxed: widget.relaxed,
      score: hunt.finalScore,
      found: hunt.found.length,
      daily: widget.daily,
      cleared: hunt.cleared,
      language: _language,
    );
    if (mounted) setState(() => _earned = earned);
  }

  void _submit() {
    final hunt = _hunt;
    if (hunt == null || _paused || hunt.finished) return;
    _tick();
    if (hunt.finished) return;
    reportGameAction(false);
    final word = hunt.word;
    final before = hunt.score;
    final result = hunt.submit();
    setState(() {
      _lastResult = result;
      _positive = result != FindResult.invalid;
      _message = switch (result) {
        FindResult.common =>
          '$word · +${hunt.score - before} points. Lovely find!',
        FindResult.rare =>
          'Bonus word discovered! $word · +${hunt.score - before} points',
        FindResult.duplicate => '$word is already in your collection.',
        FindResult.invalid => 'That word is not in the maze: $word',
        FindResult.ignored =>
          'Find a word of ${hunt.maze.script.minimumTiles} or more tiles.',
      };
    });
    if (result == FindResult.common ||
        result == FindResult.rare ||
        result == FindResult.invalid) {
      unawaited(widget.services.feedback(good: _positive));
    }
    if (hunt.finished) _finish();
  }

  Future<void> _hintWord() async {
    final hunt = _hunt;
    if (hunt == null || hunt.finished || _hintBusy || _paused) return;
    final remaining = hunt.maze.commonWords
        .where(
          (w) =>
              !hunt.found.contains(w) &&
              (hunt.maze.commonPaths[w]?.isNotEmpty ?? false),
        )
        .toList();
    if (remaining.isEmpty) return;
    _hintBusy = true;
    final paid = await widget.store.spend(5);
    _hintBusy = false;
    if (!mounted || hunt.finished) {
      if (paid) await widget.store.reward(5);
      return;
    }
    if (!paid) {
      setState(
        () => _message = 'A hint costs 5 coins. Finish trails to earn more.',
      );
      return;
    }
    final word = remaining[Random().nextInt(remaining.length)];
    final indices = hunt.maze.commonPaths[word]!;
    final cell = indices.firstWhere(
      (i) =>
          hunt.maze.letterAt(i % hunt.maze.width, i ~/ hunt.maze.width) != null,
      orElse: () => indices.first,
    );
    setState(() {
      _hint = cell;
      _positive = true;
      _message =
          'Start at the glowing letter. Look for ${hunt.maze.commonPaths[word]!.where((i) => hunt.maze.letterAt(i % hunt.maze.width, i ~/ hunt.maze.width) != null).length} tiles.';
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  void _showPath(String word) {
    final path = _hunt!.maze.commonPaths[word] ?? [];
    _demoTimer?.cancel();
    setState(() {
      _demoWord = word;
      _demo = [];
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _demo = path);
      return;
    }
    var count = 0;
    _demoTimer = Timer.periodic(const Duration(milliseconds: 110), (timer) {
      if (!mounted || count >= path.length) {
        timer.cancel();
        return;
      }
      setState(() => _demo = path.take(++count).toList());
    });
  }

  Future<void> _confirmEnd() async {
    if (_hunt == null || _hunt!.finished) return;
    final end = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this hunt?'),
        content: const Text(
          'Keep the words you found and explore the paths you missed. The timer keeps running while you decide.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep wandering'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End hunt'),
          ),
        ],
      ),
    );
    if (end == true && mounted) _finish();
  }

  @override
  Widget build(BuildContext context) {
    final hunt = _hunt;
    return PopScope(
      canPop: hunt == null || hunt.finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmEnd();
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) {
              if (hunt == null) {
                return Center(
                  child: _error == null
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!),
                            TextButton(
                              onPressed: () {
                                setState(() => _error = null);
                                _load();
                              },
                              child: const Text('Try again'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Back'),
                            ),
                          ],
                        ),
                );
              }
              if (hunt.finished) return _reviewPage(hunt, bounds.maxWidth);
              final landscape =
                  bounds.maxWidth > bounds.maxHeight && bounds.maxWidth >= 600;
              if (landscape) {
                final side = min(bounds.maxHeight - 8, bounds.maxWidth - 300);
                return Row(
                  children: [
                    SizedBox(
                      width: side + 8,
                      child: Center(child: _board(hunt, side)),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _header(hunt),
                            _statusBar(hunt),
                            _modeBar(hunt),
                            _guidance(),
                            _composer(hunt),
                            _tools(hunt),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              // Preserve full-width cells on phones. Very short screens and large
              // accessibility text can scroll, rather than shrinking touch targets.
              final side = min(bounds.maxWidth - 8, 640.0);
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 648),
                    child: Column(
                      children: [
                        _header(hunt),
                        _statusBar(hunt),
                        _modeBar(hunt),
                        _guidance(),
                        _board(hunt, side),
                        const SizedBox(height: 8),
                        _composer(hunt),
                        _tools(hunt),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(Hunt hunt) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        if (hunt.finished)
          IconButton(
            tooltip: 'Back home',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
        Expanded(
          child: Text(
            '${widget.daily != null ? "Daily maze" : "${widget.level.label} trail"}${_language != "en" ? " · ${_language.toUpperCase()}" : ""}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        AnimatedBuilder(
          animation: widget.store,
          builder: (_, _) => coinBadge(widget.store.coins, onTap: _openVault),
        ),
        if (!hunt.finished) _playPreferences(),
        if (!hunt.finished)
          IconButton(
            tooltip: _paused ? 'Resume' : 'Pause',
            onPressed: _paused ? _resume : _pause,
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 22,
            ),
          ),
      ],
    ),
  );

  Widget _playPreferences() => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => PopupMenuButton<String>(
      tooltip: 'Sound and haptics',
      icon: const Icon(Icons.tune_rounded, size: 22),
      onSelected: (setting) => widget.store.set(
        setting,
        setting == 'sound' ? !widget.store.sound : !widget.store.haptics,
      ),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: 'sound',
          checked: widget.store.sound,
          child: Text('Sound ${widget.store.sound ? "on" : "off"}'),
        ),
        CheckedPopupMenuItem(
          value: 'haptics',
          checked: widget.store.haptics,
          child: Text('Haptics ${widget.store.haptics ? "on" : "off"}'),
        ),
      ],
    ),
  );

  Widget _statusBar(Hunt hunt) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFECEFE3),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(child: _inlineStat('${hunt.score}', 'pts')),
        Expanded(flex: 2, child: _foundCounts(hunt)),
        Expanded(
          child: _inlineStat(
            widget.relaxed
                ? '∞'
                : '${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}',
            widget.relaxed ? 'no rush' : 'left',
            warning: !widget.relaxed && _remaining < 20,
          ),
        ),
      ],
    ),
  );

  Widget _inlineStat(String value, String label, {bool warning = false}) =>
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: warning ? const Color(0xFFA34832) : ink,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: muted)),
        ],
      );

  Widget _modeBar(Hunt hunt) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),
    child: Row(
      children: [
        Flexible(
          flex: 3,
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Drag'),
                icon: Icon(Icons.gesture, size: 16),
              ),
              ButtonSegment(
                value: true,
                label: Text('Tap letters'),
                icon: Icon(Icons.touch_app_outlined, size: 16),
              ),
            ],
            selected: {_tapMode},
            showSelectedIcon: false,
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(48, 40)),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 10),
              ),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            onSelectionChanged: _paused
                ? null
                : (values) {
                    setState(() {
                      _tapMode = values.single;
                      hunt.path.clear();
                      _positive = true;
                      _message = '';
                    });
                    unawaited(widget.store.set('tapLetters', _tapMode));
                  },
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            widget.relaxed ? 'No limits' : '${hunt.attemptsLeft} mistakes left',
            style: const TextStyle(fontSize: 11, color: muted),
          ),
        ),
      ],
    ),
  );

  Widget _guidance() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 5),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _tapMode
            ? 'Tap letters in order. Follow the green outlines.'
            : 'Drag through letters. Lift your finger to submit.',
        style: const TextStyle(fontSize: 11, color: muted, height: 1.3),
      ),
    ),
  );

  Widget _board(Hunt hunt, double side) => SizedBox(
    width: side,
    height: side,
    child: _paused
        ? Padding(
            padding: const EdgeInsets.all(8),
            child: Surface(
              color: mint,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.spa_outlined, size: 42, color: teal),
                  const SizedBox(height: 12),
                  const Text(
                    'Paused',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _resume, child: const Text('Resume')),
                ],
              ),
            ),
          )
        : GestureDetector(
            onVerticalDragStart: _tapMode || hunt.finished ? null : (_) {},
            child: MazeBoard(
              maze: hunt.maze,
              theme: widget.store.mazeTheme,
              path: hunt.finished ? _demo : hunt.path,
              hint: _hint,
              interactive: !hunt.finished,
              tapToSelect: _tapMode && !hunt.finished,
              tapTargets: _tapMode && !hunt.finished
                  ? hunt.tapTargets
                  : const {},
              onStart: (cell) {
                _tick();
                if (hunt.finished) return;
                reportGameAction(false);
                setState(() {
                  _lastResult = null;
                  if (_tapMode) {
                    final result = hunt.tapLetter(cell);
                    _positive = result != TapResult.blocked;
                    _message = switch (result) {
                      TapResult.blocked =>
                        'No clear route. Choose an outlined letter, or undo.',
                      TapResult.notLetter =>
                        'Tap a letter tile. Empty corridors connect automatically.',
                      TapResult.selected =>
                        hunt.wordTileCount >= hunt.maze.script.minimumTiles
                            ? 'Keep adding letters, or submit your word.'
                            : 'Choose the next outlined letter.',
                      TapResult.undone => 'Undone. Choose your next letter.',
                      TapResult.ignored => _message,
                    };
                  } else {
                    hunt.start(cell);
                    _message = '';
                    _lastResult = null;
                    _positive = true;
                  }
                });
              },
              onStep: (cell) {
                if (!_tapMode && hunt.step(cell)) setState(() {});
              },
              onEnd: () {
                if (!_tapMode) _submit();
              },
              onCancel: () {
                if (!_tapMode) setState(hunt.path.clear);
              },
            ),
          ),
  );

  Widget _composer(Hunt hunt) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEDC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    hunt.word.isEmpty
                        ? (_tapMode
                              ? 'Tap your first letter'
                              : 'Find your next word')
                        : hunt.word,
                    style: TextStyle(
                      fontSize: hunt.word.isEmpty ? 14 : 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing:
                          hunt.word.isEmpty || hunt.maze.script.complexTiles
                          ? 0
                          : 2,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _confirmEnd,
                child: const Text('End hunt', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (_tapMode)
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Undo last letter',
                  onPressed: hunt.path.isEmpty || _paused
                      ? null
                      : () => setState(() {
                          hunt.undoLetter();
                          _message = '';
                          _positive = true;
                        }),
                  icon: const Icon(Icons.undo_rounded, size: 20),
                ),
                FilledButton(
                  onPressed:
                      hunt.wordTileCount < hunt.maze.script.minimumTiles ||
                          _paused
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(76, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Submit', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),

          Semantics(
            liveRegion: true,
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              padding: EdgeInsets.all(_message.isNotEmpty ? 10 : 2),
              decoration: BoxDecoration(
                color: _message.isEmpty
                    ? Colors.transparent
                    : !_positive
                    ? const Color(0xFFF8DAD2)
                    : _lastResult == FindResult.rare
                    ? const Color(0xFFF7E6AE)
                    : mint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (_message.isNotEmpty) ...[
                    Icon(
                      !_positive
                          ? Icons.error_outline_rounded
                          : _lastResult == FindResult.rare
                          ? Icons.auto_awesome
                          : Icons.check_circle_outline,
                      size: 24,
                      color: !_positive
                          ? const Color(0xFF9A3424)
                          : _lastResult == FindResult.rare
                          ? const Color(0xFF795500)
                          : teal,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _paused
                          ? 'Resume to continue.'
                          : _message.isNotEmpty
                          ? _message
                          : _tapMode
                          ? '${hunt.maze.script.minimumTiles}+ tiles · tap a selected letter to go back.'
                          : '${hunt.maze.script.minimumTiles}+ tiles · retrace a step to undo.',
                      style: TextStyle(
                        fontSize: _message.isEmpty ? 11 : 16,
                        fontWeight: _message.isEmpty
                            ? FontWeight.w600
                            : FontWeight.w800,
                        height: 1.3,
                        color: !_positive
                            ? const Color(0xFF9A3424)
                            : _lastResult == FindResult.rare
                            ? const Color(0xFF795500)
                            : ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tools(Hunt hunt) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        TextButton.icon(
          onPressed: _paused || _hintBusy ? null : _hintWord,
          icon: const Icon(Icons.lightbulb_outline, size: 18),
          label: const Text('Hint · 5', style: TextStyle(fontSize: 12)),
        ),
        TextButton.icon(
          key: const ValueKey('found-words'),
          onPressed: () => _collection(hunt),
          icon: const Icon(Icons.bookmark_border_rounded, size: 18),
          label: _foundCounts(hunt),
        ),
        if (_tapMode)
          TextButton(
            onPressed: hunt.path.isEmpty || _paused
                ? null
                : () => setState(() {
                    hunt.path.clear();
                    _message = '';
                    _lastResult = null;
                    _positive = true;
                  }),
            child: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
      ],
    ),
  );

  Widget _foundCounts(Hunt hunt) => Wrap(
    spacing: 5,
    runSpacing: 3,
    alignment: WrapAlignment.center,
    children: [
      for (final item in [
        (
          'Maze ${hunt.commonFound}/${hunt.maze.commonWords.length}',
          mint,
          teal,
        ),
        (
          'Bonus ${hunt.rareFound}',
          const Color(0xFFF2E2B5),
          const Color(0xFF795500),
        ),
      ])
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: item.$2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.$1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: item.$3,
            ),
          ),
        ),
    ],
  );

  void _collection(Hunt hunt) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: paper,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .55,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your word collection',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _foundCounts(hunt),
                const SizedBox(height: 14),
                if (hunt.found.isEmpty)
                  const Text(
                    'Your discoveries will appear here.',
                    style: TextStyle(color: muted),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final word in hunt.found)
                        Chip(
                          label: Text(
                            word,
                            style: TextStyle(
                              color: hunt.maze.isCommon(word)
                                  ? teal
                                  : const Color(0xFF795500),
                            ),
                          ),
                          side: BorderSide.none,
                          backgroundColor: hunt.maze.isCommon(word)
                              ? mint
                              : const Color(0xFFF2E2B5),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _reviewPage(Hunt hunt, double width) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 648),
        child: Column(
          children: [
            _header(hunt),
            if (hunt.cleared) const SuccessCelebration(),
            if (_lastResult == FindResult.invalid)
              Semantics(
                liveRegion: true,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8DAD2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _message,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9A3424),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hunt.cleared
                        ? 'Every word. What a wander.'
                        : 'A trail well travelled.',
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${hunt.finalScore} points · ${_earned == null ? 'Saving…' : '+$_earned coins'}${hunt.cleared ? ' · Perfect clear +100' : ''}',
                    style: const TextStyle(
                      color: teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _board(hunt, min(width - 8, 640)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              child: _review(hunt),
            ),
          ],
        ),
      ),
    ),
  );

  void _pause() {
    _tick();
    if (_hunt == null || _hunt!.finished) return;
    setState(() {
      _paused = true;
      _hunt!.path.clear();
    });
  }

  void _resume() {
    _deadline = DateTime.now().add(Duration(seconds: _remaining));
    setState(() => _paused = false);
  }

  Widget _review(Hunt hunt) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_demoWord != null)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'The path to $_demoWord',
              style: const TextStyle(fontWeight: FontWeight.w800, color: teal),
            ),
          ),
        ),
      const Eyebrow('WORDS ALONG THE WAY'),
      const SizedBox(height: 9),
      const Text(
        'Tap a word to see its trail through the maze.',
        style: TextStyle(fontSize: 12, color: muted),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final word in hunt.maze.commonWords)
            ActionChip(
              onPressed: () => _showPath(word),
              avatar: hunt.found.contains(word)
                  ? const Icon(Icons.check, size: 14)
                  : null,
              backgroundColor: word == _demoWord
                  ? gold
                  : hunt.found.contains(word)
                  ? mint
                  : Colors.white,
              side: BorderSide.none,
              label: Text(
                word,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      if (hunt.found.any((w) => !hunt.maze.isCommon(w))) ...[
        const SizedBox(height: 20),
        const Eyebrow('BONUS WORDS'),
        const SizedBox(height: 8),
        Text(hunt.found.where((w) => !hunt.maze.isCommon(w)).join(' · ')),
      ],
      const SizedBox(height: 25),
      FilledButton(
        onPressed: _earned == null ? null : _nextTrail,
        child: Text(
          '${widget.daily == null ? "Another little adventure" : "Revisit today’s maze"}${!widget.relaxed && widget.store.huntOptions(widget.level).cost > 0 ? " · ${widget.store.huntOptions(widget.level).cost} coins" : ""}',
        ),
      ),
      const SizedBox(height: 9),
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Back home'),
      ),
      if (widget.store.saveError != null)
        Text(
          widget.store.saveError!,
          style: const TextStyle(color: Colors.red),
        ),
    ],
  );
}
