import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/axis.dart';
import '../game/difficulty.dart';
import '../game/puzzle.dart';
import '../game/session.dart';
import '../services/puzzle_factory.dart';
import '../services/session_store.dart';
import 'banner.dart';
import 'board.dart';
import 'celebration.dart';
import 'rules.dart';
import 'style.dart';
import 'tray.dart';
import 'techniques.dart';
import 'upgrades.dart';
import '../services/access_store.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.puzzle,
    this.initialSession,
    this.debugSession,
    this.persist = true,
    this.store,
    this.puzzleBuilder = buildPuzzle,
  });
  final Puzzle puzzle;
  final Session? initialSession;
  @visibleForTesting
  final Session? debugSession;
  final bool persist;
  final SessionStore? store;
  final Future<Puzzle> Function(Difficulty) puzzleBuilder;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with WidgetsBindingObserver {
  late final Session session =
      widget.initialSession ?? widget.debugSession ?? Session(widget.puzzle);
  late final SessionStore store = widget.store ?? SessionStore.instance;
  Timer? _checkpoint;
  bool celebrated = false,
      _allowPop = false,
      _exiting = false,
      _building = false;
  String _saveStatus = 'Saving…';
  bool _saveFailed = false;
  int _saveRevision = 0;
  bool _foreground = true;
  bool _helpOpen = false;
  bool _accessBusy = false;

  @override
  void initState() {
    super.initState();
    session.resume();
    session.addListener(_onChange);
    WidgetsBinding.instance.addObserver(this);
    if (widget.persist) {
      _checkpoint = Timer.periodic(const Duration(seconds: 15), (_) {
        if (_foreground && !session.isSolved) unawaited(_persist());
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_persist());
      });
    }
  }

  @override
  void dispose() {
    _checkpoint?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    session.removeListener(_onChange);
    session.pause();
    session.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && !_helpOpen && !_exiting) {
      session.resume();
    } else {
      session.pause();
      unawaited(_persist());
    }
  }

  Future<bool> _persist() async {
    if (!widget.persist) return true;
    final revision = ++_saveRevision;
    if (mounted) {
      setState(() {
        _saveStatus = 'Saving…';
        _saveFailed = false;
      });
    }
    try {
      await store.save(session);
      if (mounted && revision == _saveRevision) {
        setState(
          () => _saveStatus = session.isSolved
              ? 'Puzzle complete'
              : 'Saved on this device',
        );
      }
      return true;
    } catch (_) {
      if (mounted && revision == _saveRevision) {
        setState(() {
          _saveStatus = 'Could not save. Please retry.';
          _saveFailed = true;
        });
      }
      return false;
    }
  }

  void _onChange() {
    unawaited(_persist());
    if (!celebrated && session.isSolved) {
      celebrated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
    }
  }

  Future<void> _exit() async {
    if (_exiting || _accessBusy || _building) return;
    setState(() => _exiting = true);
    session.pause();
    final saved = await _persist();
    if (!mounted) return;
    if (!saved) {
      setState(() => _exiting = false);
      if (_foreground && !_helpOpen) session.resume();
      return;
    }
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _celebrate() async {
    if (!mounted) return;
    final action = await showSolvedSheet(context, session);
    if (!mounted) return;
    if (action == SolvedAction.again) {
      await _playAgain();
    } else if (action == SolvedAction.home) {
      await _exit();
    }
  }

  Future<void> _playAgain() async {
    if (_building) return;
    setState(() => _building = true);
    Session? next;
    try {
      final tier = session.puzzle.difficulty;
      _helpOpen = true;
      if (!await ensureAccess(context, AccessKind.puzzle, tier) || !mounted) {
        if (mounted) setState(() => _building = false);
        return;
      }
      late final Puzzle puzzle;
      await useAccess(AccessKind.puzzle, tier, () async {
        puzzle = await widget.puzzleBuilder(tier);
        next = Session(puzzle)..pause();
        if (widget.persist) await store.save(next!);
      });
      if (!mounted) {
        next?.dispose();
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PlayScreen(
            puzzle: puzzle,
            initialSession: next,
            persist: widget.persist,
            store: store,
            puzzleBuilder: widget.puzzleBuilder,
          ),
        ),
      );
    } catch (_) {
      next?.dispose();
      if (mounted) {
        setState(() => _building = false);
        _message(
          'Could not start another puzzle. Your result is still here.',
          false,
        );
      }
    } finally {
      _helpOpen = false;
    }
  }

  Future<void> _help() async {
    _helpOpen = true;
    session.pause();
    unawaited(_persist());
    await showRulesSheet(context);
    _helpOpen = false;
    if (mounted && _foreground) session.resume();
  }

  Future<void> _hint() async {
    if (_accessBusy ||
        _building ||
        _exiting ||
        !session.hintsAllowed ||
        session.isSolved) {
      return;
    }
    final cell = session.selected;
    if (cell == null || session.board.cells[cell] >= 0) {
      _message('Select an empty cell for a hint.', false);
      return;
    }
    setState(() => _accessBusy = true);
    _helpOpen = true;
    session.pause();
    try {
      if (!await ensureAccess(
            context,
            AccessKind.hint,
            session.puzzle.difficulty,
          ) ||
          !mounted) {
        return;
      }
      await useAccess(AccessKind.hint, session.puzzle.difficulty, () async {
        if (!mounted || session.selected != cell || !session.hint()) {
          throw StateError(
            'Choose an empty cell for the hint. Your credit was kept.',
          );
        }
      });
    } catch (_) {
      if (mounted) {
        _message('Could not unlock this hint. Please try again.', false);
      }
    } finally {
      _helpOpen = false;
      if (mounted) {
        setState(() => _accessBusy = false);
        if (_foreground) session.resume();
      }
    }
  }

  Future<void> _techniques() async {
    _helpOpen = true;
    session.pause();
    unawaited(_persist());
    await showTechniques(context);
    _helpOpen = false;
    if (mounted && _foreground) session.resume();
  }

  void _message(String message, bool success) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(message), backgroundColor: success ? teal : coral),
    );

  void _commit(AxisTrack axis) {
    final right = session.commitAxis(axis);
    _message(
      right
          ? session.puzzle.difficulty.autoFillAxis
                ? '${axis.label} is the hidden line. Phrase placed.'
                : '${axis.label} confirmed. Fill the letters yourself.'
          : '${axis.label} is not the hidden line. Try another deduction.',
      right,
    );
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        _building ||
        _accessBusy ||
        _exiting ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final modifiers = HardwareKeyboard.instance;
    if ((modifiers.isControlPressed || modifiers.isMetaPressed) &&
        key == LogicalKeyboardKey.keyZ) {
      session.undo();
    } else if (modifiers.isControlPressed ||
        modifiers.isMetaPressed ||
        modifiers.isAltPressed) {
      return KeyEventResult.ignored;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final old = session.selected ?? 0;
      final delta = key == LogicalKeyboardKey.arrowLeft
          ? -1
          : key == LogicalKeyboardKey.arrowRight
          ? 1
          : key == LogicalKeyboardKey.arrowUp
          ? -9
          : 9;
      final index = (old + delta).clamp(0, 80);
      session.select(index ~/ 9, index % 9);
    } else if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      session.clear();
    } else {
      final digit = int.tryParse(key.keyLabel);
      final letter = session.puzzle.phrase.letters.indexOf(
        key.keyLabel.toUpperCase(),
      );
      if (digit != null && digit >= 1 && digit <= 9) {
        session.place(digit - 1);
      } else if (letter >= 0) {
        session.place(letter);
      } else {
        return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.handled;
  }

  bool get _pinTray =>
      (!kIsWeb || MediaQuery.sizeOf(context).width >= 600) &&
      MediaQuery.sizeOf(context).height >= 750 &&
      MediaQuery.textScalerOf(context).scale(14) <= 15.4;

  Widget _gamePanel(double? height) {
    final board = LayoutBuilder(
      builder: (context, constraints) {
        final width =
            height == null || constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        return Center(
          child: SizedBox(
            width: width,
            child: Board(session: session, onHeaderTap: session.toggleAxis),
          ),
        );
      },
    );
    return SizedBox(
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TargetBanner(session: session, compact: true),
          const SizedBox(height: 10),
          _AxisStatus(session: session, onCommit: _commit),
          const SizedBox(height: 12),
          if (height != null) Expanded(child: board) else board,
        ],
      ),
    );
  }

  Widget _tray() => LetterTray(
    session: session,
    onLetter: (letter) {
      if (session.selected == null) {
        _message('Select a cell first.', false);
        return;
      }
      if (!session.place(letter)) {
        _message('Choose an editable cell. Notes need an empty cell.', false);
      }
    },
    onClear: session.clear,
    onUndo: session.undo,
    onNotes: session.toggleNoteMode,
    onHint: _hint,
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(_exit());
    },
    child: Focus(
      autofocus: true,
      onKeyEvent: _key,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _exiting || _building || _accessBusy ? null : _exit,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Save and return home',
          ),
          title: Row(
            children: [
              const AlphadokuMark(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  session.puzzle.phrase.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _techniques,
              tooltip: 'Solving techniques',
              icon: const Icon(Icons.menu_book_outlined),
            ),
            IconButton(
              onPressed: _help,
              tooltip: 'How to play',
              icon: const Icon(Icons.help_outline_rounded),
            ),
          ],
        ),
        bottomNavigationBar: _pinTray
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ListenableBuilder(
                    listenable: session,
                    builder: (context, _) => Center(
                      heightFactor: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 528),
                        child: AbsorbPointer(
                          absorbing: _building || _exiting || _accessBusy,
                          child: _tray(),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: session,
            builder: (context, _) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: AbsorbPointer(
                  absorbing: _building || _exiting || _accessBusy,
                  child: LayoutBuilder(
                    builder: (context, viewport) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _gamePanel(_pinTray ? viewport.maxHeight - 8 : null),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Pill(session.puzzle.difficulty.label),
                              Pill(session.puzzle.difficulty.challengeLabel),
                            ],
                          ),
                          if (widget.persist)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _saveStatus,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _saveFailed ? coral : muted,
                                    ),
                                  ),
                                ),
                                if (_saveFailed)
                                  TextButton(
                                    onPressed: _persist,
                                    child: const Text('Retry save'),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          _CellNavigator(session: session),
                          const SizedBox(height: 12),
                          if (!_pinTray) _tray(),
                          if (session.isSolved) ...[
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _building ? null : _playAgain,
                              child: Text(
                                _building ? 'Building puzzle…' : 'Play again',
                              ),
                            ),
                            TextButton(
                              onPressed: _celebrate,
                              child: const Text('View result'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CellNavigator extends StatelessWidget {
  const _CellNavigator({required this.session});
  final Session session;

  Future<void> _choose(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Choose a cell'),
      content: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final selected = session.selected;
          return SizedBox(
            width: 320,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: _AxisPicker(
                    label: 'Row',
                    selected: selected == null ? null : selected ~/ 9,
                    onPick: (r) =>
                        session.select(r, (session.selected ?? 0) % 9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AxisPicker(
                    label: 'Column',
                    selected: selected == null ? null : selected % 9,
                    onPick: (c) =>
                        session.select((session.selected ?? 0) ~/ 9, c),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final selected = session.selected;
    final value = selected == null ? -1 : session.board.cells[selected];
    final label = selected == null
        ? 'Choose a cell'
        : 'Row ${selected ~/ 9 + 1}, column ${selected % 9 + 1}: ${value < 0 ? "empty" : session.puzzle.phrase.letters[value]}'
              '${session.isFixed(selected ~/ 9, selected % 9) ? " (fixed)" : ""}'
              '${session.conflicts.contains(selected) ? " — conflict" : ""}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Semantics(
        liveRegion: true,
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
      subtitle: const Text(
        'Tap to choose row and column',
        style: TextStyle(fontSize: 11),
      ),
      trailing: const Icon(Icons.grid_on_rounded),
      onTap: () => _choose(context),
    );
  }
}

class _AxisPicker extends StatelessWidget {
  const _AxisPicker({
    required this.label,
    required this.selected,
    required this.onPick,
  });
  final String label;
  final int? selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: 9,
        itemBuilder: (context, i) => Semantics(
          label: '$label ${i + 1}',
          selected: selected == i,
          child: OutlinedButton(
            onPressed: () => onPick(i),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: selected == i ? teal : null,
              foregroundColor: selected == i ? Colors.white : ink,
            ),
            child: Text('${i + 1}'),
          ),
        ),
      ),
    ],
  );
}

class _AxisStatus extends StatelessWidget {
  const _AxisStatus({required this.session, required this.onCommit});
  final Session session;
  final void Function(AxisTrack) onCommit;

  Future<void> _choose(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder: (context, controller) => ListenableBuilder(
        listenable: session,
        builder: (context, _) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Find the hidden line',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Cross off impossible lines, or confirm your deduction. Undo does not restore manual cross-offs.',
            ),
            for (final axis in AxisTrack.all)
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${axis.kind.label} ${axis.index + 1}'),
                      subtitle: Text(
                        session.ruledOut.contains(axis)
                            ? 'Crossed off'
                            : 'Possible',
                      ),
                      value: session.ruledOut.contains(axis),
                      onChanged: (_) => session.toggleAxis(axis),
                    ),
                  ),
                  TextButton(
                    onPressed: session.ruledOut.contains(axis)
                        ? null
                        : () {
                            Navigator.pop(context);
                            onCommit(axis);
                          },
                    child: Text('Confirm ${axis.label}'),
                  ),
                ],
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final locked = session.lockedAxis;
    if (locked != null) {
      return Surface(
        color: axisGlow,
        padding: const EdgeInsets.all(14),
        child: Text(
          session.puzzle.difficulty.autoFillAxis
              ? 'Axis found: ${locked.label} spells the phrase.'
              : 'Line confirmed: ${locked.label}. Fill each letter yourself.',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    }
    return Surface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Hidden line · ${session.shortlist.length} left',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () => _choose(context),
                child: const Text('Choose a line'),
              ),
            ],
          ),
          if (!session.puzzle.difficulty.autoFillAxis)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Confirm the line. Fill each letter yourself.',
                style: TextStyle(fontSize: 12, color: teal),
              ),
            ),
          if (session.shortlist.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'All lines crossed off. Restore one in the picker.',
                style: TextStyle(color: coral),
              ),
            ),
        ],
      ),
    );
  }
}
