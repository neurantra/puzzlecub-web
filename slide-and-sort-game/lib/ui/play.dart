import 'dart:async';
import 'package:flutter/material.dart';
import '../game/puzzle_board.dart';
import '../game/round.dart';
import '../services/preferences.dart';
import '../services/audio.dart';
import '../services/ads.dart';
import 'toy_box.dart';
import 'celebration.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.options,
    required this.preferences,
    required this.audio,
    required this.ads,
  });
  final PlayOptions options;
  final Preferences preferences;
  final GameAudio audio;
  final GameAds ads;
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with WidgetsBindingObserver {
  late AlphabetRound round;
  bool get numbers => widget.options.kind != PuzzleKind.alphabets;
  bool get sequential => widget.options.kind == PuzzleKind.sequential;
  Timer? timer;
  bool recorded = false, leaving = false, allowPop = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _newRound();
  }

  void _newRound() {
    round = AlphabetRound(widget.options);
    round.addListener(_changed);
    timer = Timer.periodic(const Duration(seconds: 1), (_) => round.tick());
  }

  void _changed() {
    if (!round.active && !recorded) {
      recorded = true;
      if (round.outcome == RoundOutcome.solved) {
        widget.audio.tap(widget.preferences.sound, win: true);
        unawaited(
          widget.preferences.recordWin().catchError((Object _) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'You solved it! Your finish could not be saved.',
                  ),
                ),
              );
            }
          }),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && round.active) round.pause(true);
  }

  @override
  void dispose() {
    timer?.cancel();
    round.removeListener(_changed);
    round.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _adBreak() async {
    await widget.audio.music(false);
    try {
      await widget.ads.afterRound();
    } finally {
      if (mounted) await widget.audio.music(widget.preferences.music);
    }
  }

  Future<void> exit() async {
    if (leaving) return;
    if (round.active) {
      round.pause(true);
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Back home?'),
          content: const Text(
            'This puzzle will be put away. A fresh one will be waiting for you.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Go home'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (leave != true) {
        round.pause(false);
        return;
      }
    } else {
      leaving = true;
      await _adBreak();
    }
    if (mounted) {
      setState(() => allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> again() async {
    if (leaving) return;
    setState(() => leaving = true);
    await _adBreak();
    if (!mounted) return;
    timer?.cancel();
    round.removeListener(_changed);
    round.dispose();
    setState(() {
      recorded = false;
      leaving = false;
      _newRound();
    });
  }

  Future<void> guide() async {
    round.pause(true);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          sequential
              ? 'Count your way from 1 to 29.'
              : numbers
              ? 'One more across. One more down.'
              : 'Every letter has a home',
        ),
        content: SizedBox(
          width: 280,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AlphabetBoard(
                  board: PuzzleBoard.solved(kind: widget.options.kind),
                  small: true,
                ),
                const SizedBox(height: 18),
                Text(
                  sequential
                      ? 'Put 1 through 29 in order, left to right, then down. Leave the bottom-right space empty.'
                      : numbers
                      ? 'Start at 1. Add one to the right or down. Use all six rows. The gap takes the place of 10 at the bottom right. Matching numbers are interchangeable.'
                      : 'Read left to right, then down. The gap belongs after X.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to my puzzle'),
          ),
        ],
      ),
    );
    if (mounted) round.pause(false);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: allowPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(exit());
    },
    child: Scaffold(
      body: Garden(
        child: ListenableBuilder(
          listenable: round,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back to home',
                      onPressed: leaving ? null : exit,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const GameIcon(size: 32),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.options.againstAI
                                ? 'Play mode: Pip the AI'
                                : 'Play mode: Solo',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${widget.options.timed ? 'Timed · 5 min' : 'No timer'} · ${widget.options.limited ? '150 moves' : 'No move limit'}',
                            style: const TextStyle(fontSize: 11, color: teal),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: round.paused ? 'Resume' : 'Pause',
                      onPressed: round.active
                          ? () => round.pause(!round.paused)
                          : null,
                      icon: Icon(
                        round.paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (round.active || round.outcome == RoundOutcome.solved) ...[
                  if (round.outcome == RoundOutcome.solved)
                    Row(
                      key: const ValueKey('solved-banner'),
                      children: [
                        const Pip(size: 64),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HOORAY! You did it!',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                numbers
                                    ? 'Your pattern is complete. Enjoy your lovely work!'
                                    : 'Every letter is home. Enjoy your lovely work!',
                                style: TextStyle(fontSize: 12, color: teal),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else if (widget.options.againstAI)
                    PaperCard(
                      padding: 10,
                      color: const Color(0xFFE9F3EF),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 96,
                            height: numbers ? 114 : 96,
                            child: LiveAiBoard(board: round.friendBoard),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  round.paused
                                      ? 'Pip is paused, too.'
                                      : numbers
                                      ? 'Ready, set… 1, 2, 3!'
                                      : 'Ready, set… ABC!',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Pip’s live board",
                                  style: TextStyle(fontSize: 12, color: teal),
                                ),
                                Text(
                                  round.friendAtLimit
                                      ? 'Move limit reached'
                                      : '${round.friendMoves} ${round.friendMoves == 1 ? 'move' : 'moves'} · ${round.friendBoard.correctlyPlacedCount}/${round.board.symbolCount} in place',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value:
                                      round.friendBoard.correctlyPlacedCount /
                                      round.friendBoard.symbolCount,
                                  minHeight: 5,
                                  borderRadius: BorderRadius.circular(6),
                                  backgroundColor: Colors.white,
                                  color: teal,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        const Pip(size: 64),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            round.paused
                                ? 'Take a little breather.'
                                : 'One little slide at a time.',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _Stat(
                        icon: Icons.timer_outlined,
                        label: round.active && widget.options.timed
                            ? 'Time left'
                            : 'Time',
                        value: _time(
                          round.active && widget.options.timed
                              ? round.remainingSeconds
                              : round.seconds,
                        ),
                      ),
                      _Stat(
                        icon: Icons.touch_app_outlined,
                        label: round.active && widget.options.limited
                            ? 'Moves left'
                            : 'Moves',
                        value:
                            '${round.active && widget.options.limited ? round.remainingMoves : round.moves}',
                      ),
                      _Stat(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'In place',
                        value:
                            '${round.board.correctlyPlacedCount}/${round.board.symbolCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    key: const ValueKey('player-board-region'),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Stack(
                        children: [
                          round.paused
                              ? AspectRatio(
                                  aspectRatio: 5 / 6,
                                  child: PaperCard(
                                    color: const Color(0xFFE3F2E8),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Pip(size: 100),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Your puzzle can wait.',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        FilledButton(
                                          onPressed: () => round.pause(false),
                                          child: const Text('Keep playing'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : AlphabetBoard(
                                  board: round.board,
                                  onMove: round.active
                                      ? (index) {
                                          if (round.slide(index) &&
                                              round.active) {
                                            widget.audio.tap(
                                              widget.preferences.sound,
                                            );
                                          }
                                        }
                                      : null,
                                ),
                          if (round.outcome == RoundOutcome.solved)
                            const Positioned.fill(child: CelebrationFlourish()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (round.outcome == RoundOutcome.solved) ...[
                    FilledButton(
                      onPressed: leaving ? null : again,
                      child: Text(
                        leaving ? 'One moment…' : 'Another happy shuffle',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: leaving ? null : exit,
                      child: const Text('Back home'),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: round.paused ? null : guide,
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      label: Text(
                        numbers
                            ? 'Peek at the number guide'
                            : 'Peek at the ABC guide',
                      ),
                    ),
                    Text(
                      sequential
                          ? 'Slide the numbers into order, from 1 to 29.'
                          : numbers
                          ? 'Tap a number beside the gap. Match the pattern.'
                          : 'Tap a letter beside the gap. Y & Z stay put.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: teal),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 20),
                  const Center(child: Pip(size: 150)),
                  const SizedBox(height: 16),
                  Text(
                    switch (round.outcome) {
                      RoundOutcome.solved => 'You did it, sunshine!',
                      RoundOutcome.friendFinished =>
                        numbers
                            ? 'Pip found the pattern!'
                            : 'Pip found the ABCs!',
                      RoundOutcome.timeUp => 'Time for a little cheer!',
                      _ => 'Look how far you got!',
                    },
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    round.outcome == RoundOutcome.solved
                        ? 'Every letter is home. What a lovely job!'
                        : 'Every try helps your brain grow. Let’s try a fresh puzzle.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  PaperCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Stat(
                          icon: Icons.touch_app_outlined,
                          label: 'Moves',
                          value: '${round.moves}',
                        ),
                        _Stat(
                          icon: Icons.timer_outlined,
                          label: 'Time',
                          value: _time(round.seconds),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 230,
                      child: AlphabetBoard(board: round.board, small: true),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: leaving ? null : again,
                    child: Text(
                      leaving ? 'One moment…' : 'Another happy shuffle',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: leaving ? null : exit,
                    child: const Text('Back home'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String _time(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: teal),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
        ],
      ),
      Text(label, style: const TextStyle(fontSize: 10, color: teal)),
    ],
  );
}
