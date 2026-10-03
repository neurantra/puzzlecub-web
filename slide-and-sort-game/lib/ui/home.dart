import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../game/puzzle_board.dart';
import '../game/round.dart';
import '../services/preferences.dart';
import '../services/audio.dart';
import '../services/ads.dart';
import 'age.dart';
import 'play.dart';
import 'toy_box.dart';
import 'home_ad_banner.dart';
import 'app_menu.dart';
import '../services/family_games.dart';
import 'package:flutter/foundation.dart';

class AlphabetHome extends StatefulWidget {
  const AlphabetHome({
    super.key,
    required this.preferences,
    required this.audio,
    required this.ads,
  });
  final Preferences preferences;
  final GameAudio audio;
  final GameAds ads;
  @override
  State<AlphabetHome> createState() => _AlphabetHomeState();
}

class _AlphabetHomeState extends State<AlphabetHome> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  PuzzleKind kind = PuzzleKind.alphabets;
  bool get numbers => kind != PuzzleKind.alphabets;
  bool get sequential => kind == PuzzleKind.sequential;
  bool againstAI = false, timed = false, limited = false, starting = false;
  PuzzleBoard get preview =>
      PuzzleBoard.solved(kind: kind).shuffled(moves: 8, random: Random(42));
  @override
  void initState() {
    super.initState();
    kind = switch (widget.preferences.storage.getString('puzzleKind')) {
      'sequential' => PuzzleKind.sequential,
      'numbers' => PuzzleKind.numbers,
      'alphabets' => PuzzleKind.alphabets,
      _ =>
        (widget.preferences.storage.getBool('numbers') ?? false)
            ? PuzzleKind.numbers
            : PuzzleKind.alphabets,
    };
    againstAI = widget.preferences.storage.getBool('againstAI') ?? false;
    timed = widget.preferences.storage.getBool('timed') ?? false;
    limited = widget.preferences.storage.getBool('limited') ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.preferences.declared) {
        await editAge(context, widget.preferences, first: true);
      }
      if (!mounted) return;
      unawaited(widget.audio.music(widget.preferences.music));
      unawaited(widget.ads.prepare());
    });
  }

  Future<void> start() async {
    if (starting) return;
    setState(() => starting = true);
    widget.audio.tap(widget.preferences.sound);
    try {
      if (!await widget.preferences.storage.setString(
        'puzzleKind',
        kind.name,
      )) {
        throw StateError('Could not save puzzle choice');
      }
      await widget.preferences.setFlag('againstAI', againstAI);
      await widget.preferences.setFlag('timed', timed);
      await widget.preferences.setFlag('limited', limited);
    } catch (_) {
      /* A preferences write is not required for this round. */
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlayScreen(
          options: PlayOptions(
            kind: kind,
            againstAI: againstAI,
            timed: timed,
            limited: limited,
          ),
          preferences: widget.preferences,
          audio: widget.audio,
          ads: widget.ads,
        ),
      ),
    );
    if (mounted) setState(() => starting = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 712),
                  child: FilledButton(
                    onPressed: starting ? null : start,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(starting ? 'Getting ready…' : "Let's play"),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _scroll,
                  builder: (context, _) {
                    final more =
                        !_scroll.hasClients ||
                        !_scroll.position.hasContentDimensions ||
                        _scroll.position.extentAfter > 8;
                    return TextButton.icon(
                      onPressed: more
                          ? () {
                              if (!_scroll.hasClients) return;
                              final target =
                                  (_scroll.offset +
                                          _scroll.position.viewportDimension *
                                              .7)
                                      .clamp(
                                        0.0,
                                        _scroll.position.maxScrollExtent,
                                      );
                              if (MediaQuery.disableAnimationsOf(context)) {
                                _scroll.jumpTo(target);
                              } else {
                                _scroll.animateTo(
                                  target,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            }
                          : null,
                      icon: Icon(
                        more
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.check_rounded,
                      ),
                      label: Text(more ? 'More below' : 'You’re all set!'),
                    );
                  },
                ),
              ],
            ),
          ),
          if (!starting) HomeAdBanner(ads: widget.ads),
        ],
      ),
    ),
    body: Garden(
      playful: true,
      child: Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const GameIcon(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Slide & Sort:',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(fontSize: 22),
                        ),
                        const Text(
                          'ABCs & 123s',
                          style: TextStyle(
                            color: teal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Pip(size: 48),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'How to play',
                        onPressed: () => showHowTo(
                          context,
                          numbers: numbers,
                          sequential: sequential,
                        ),
                        icon: const Icon(Icons.help_outline_rounded),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Menu',
                        icon: const Icon(Icons.menu_rounded),
                        onSelected: (value) {
                          if (value == 'settings') {
                            showSettings(
                              context,
                              widget.preferences,
                              widget.ads,
                            );
                          } else if (value.startsWith('game:')) {
                            final game = FamilyGame.values.byName(
                              value.substring(5),
                            );
                            openFamilyLink(
                              context,
                              game.link(defaultTargetPlatform),
                            );
                          } else {
                            showAppInformation(context, value);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'about',
                            child: Text('About'),
                          ),
                          const PopupMenuItem(
                            value: 'privacy',
                            child: Text('Privacy'),
                          ),
                          const PopupMenuItem(
                            value: 'terms',
                            child: Text('Terms'),
                          ),
                          const PopupMenuItem(
                            value: 'settings',
                            child: Text('Settings'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            enabled: false,
                            child: Text('More from Neurantra'),
                          ),
                          for (final game in FamilyGame.values)
                            PopupMenuItem(
                              value: 'game:${game.name}',
                              child: Text(game.title),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final scene = Column(
                    children: [
                      Transform.rotate(
                        angle: -.035,
                        child: SizedBox(
                          width: c.maxWidth > 550 ? 260 : 145,
                          child: AlphabetBoard(board: preview, small: true),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        sequential
                            ? 'Count your way from 1 to 29.'
                            : numbers
                            ? 'One more across. One more down.'
                            : 'A happy little home for every letter',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: teal,
                        ),
                      ),
                    ],
                  );
                  final options = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Choose your puzzle',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        key: const ValueKey('puzzle-choice-row'),
                        children: [
                          for (final (choice, label, description) in [
                            (PuzzleKind.alphabets, 'A–Z', 'Alphabets'),
                            (PuzzleKind.numbers, '1–9', 'Number pattern'),
                            (
                              PuzzleKind.sequential,
                              '1–29',
                              'Sequential numbers',
                            ),
                          ]) ...[
                            if (choice != PuzzleKind.alphabets)
                              const SizedBox(width: 6),
                            Expanded(
                              child: Semantics(
                                label: description,
                                selected: kind == choice,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 12,
                                    ),
                                    backgroundColor: kind == choice
                                        ? const Color(0xFFE3F2E8)
                                        : cream,
                                    foregroundColor: ink,
                                    side: BorderSide(
                                      color: kind == choice
                                          ? teal
                                          : const Color(0xFFE5E4D9),
                                      width: kind == choice ? 2 : 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  onPressed: () =>
                                      setState(() => kind = choice),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(switch (kind) {
                        PuzzleKind.alphabets => 'Alphabets · A to Z',
                        PuzzleKind.numbers =>
                          'Number pattern · one more across and down',
                        PuzzleKind.sequential =>
                          'Number sequence · count from 1 to 29',
                      }, style: const TextStyle(fontSize: 11, color: teal)),
                      const SizedBox(height: 14),
                      _Choice(
                        label: 'PLAY MODE',
                        tint: Color(0xFFE9DEFA),
                        first: 'Solo',
                        second: 'Pip the AI',
                        value: againstAI,
                        onChanged: (v) => setState(() => againstAI = v),
                        firstIcon: Icons.person_outline_rounded,
                        secondIcon: Icons.smart_toy_outlined,
                      ),
                      const SizedBox(height: 14),
                      _Choice(
                        label: 'TIME',
                        tint: Color(0xFFD9EEFA),
                        first: 'No timer',
                        second: '5 minutes',
                        value: timed,
                        onChanged: (v) => setState(() => timed = v),
                        firstIcon: Icons.all_inclusive_rounded,
                        secondIcon: Icons.timer_outlined,
                      ),
                      const SizedBox(height: 14),
                      _Choice(
                        label: 'MOVES',
                        tint: Color(0xFFFFE1D3),
                        first: 'No limit',
                        second: '150 moves',
                        value: limited,
                        onChanged: (v) => setState(() => limited = v),
                        firstIcon: Icons.air_rounded,
                        secondIcon: Icons.touch_app_outlined,
                      ),
                    ],
                  );
                  if (c.maxWidth > 550) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: scene),
                        const SizedBox(width: 26),
                        Expanded(child: PaperCard(child: options)),
                      ],
                    );
                  }
                  return PaperCard(padding: 16, child: options);
                },
              ),
              const SizedBox(height: 22),
              const SizedBox(height: 16),
              Text(
                widget.preferences.wins == 0
                    ? 'No levels. Just one lovely puzzle after another.'
                    : '${widget.preferences.wins} happy ${widget.preferences.wins == 1 ? 'finish' : 'finishes'} · Keep growing!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: teal),
              ),
              const SizedBox(height: 24),
              const FamilyGamesPanel(),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    this.tint = const Color(0xFFE3F2E8),
    required this.first,
    required this.second,
    required this.value,
    required this.onChanged,
    required this.firstIcon,
    required this.secondIcon,
  });
  final Color tint;
  final String label, first, second;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData firstIcon, secondIcon;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
          color: teal,
        ),
      ),
      const SizedBox(height: 7),
      Row(
        children: [
          for (final selected in [false, true]) ...[
            if (selected) const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                selected: value == selected,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 12,
                    ),
                    backgroundColor: value == selected
                        ? tint
                        : Color.lerp(tint, Colors.white, .75),
                    foregroundColor: ink,
                    side: BorderSide(
                      color: value == selected ? teal : const Color(0xFFE5E4D9),
                      width: value == selected ? 2 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => onChanged(selected),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Icon(selected ? secondIcon : firstIcon, size: 17),
                      Text(
                        selected ? second : first,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  );
}

Future<void> showHowTo(
  BuildContext context, {
  bool numbers = false,
  bool sequential = false,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('A little slide, a big smile'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Pip(size: 90)),
          SizedBox(height: 12),
          Text(
            numbers
                ? '1. Tap a number next to the empty space to slide it.'
                : '1. Tap a letter next to the empty space to slide it.',
          ),
          SizedBox(height: 12),
          Text(
            sequential
                ? '2. Put 1 through 29 in order, left to right, then down. All six rows are in play; leave the bottom-right space empty.'
                : numbers
                ? '2. Start with 1 at the top left. Add one each step right or down. Use all six rows, ending with 6, 7, 8, 9 and the gap. Equal numbers can trade places.'
                : '2. Put A–X in order, left to right, row by row. The empty space goes after X. Y and Z stay on their little shelf.',
          ),
          SizedBox(height: 12),
          Text(
            '3. Play your way! Choose a timer, a move limit, or neither. Pip the AI starts with the same puzzle and slides once every second.',
          ),
          SizedBox(height: 12),
          Text(
            numbers
                ? 'Need a peek? The number guide shows the whole pattern. You can pause whenever you like.'
                : 'Need a peek? The ABC guide shows where every letter belongs. You can pause whenever you like.',
          ),
        ],
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Got it!'),
      ),
    ],
  ),
);
Future<void> showSettings(
  BuildContext context,
  Preferences preferences,
  GameAds ads,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: ListenableBuilder(
      listenable: Listenable.merge([preferences, ads]),
      builder: (context, _) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your little corner',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              for (final (label, key, value) in [
                ('Sound effects', 'sound', preferences.sound),
                ('Garden music', 'music', preferences.music),
                ('Gentle motion', 'reducedMotion', preferences.reducedMotion),
              ])
                SwitchListTile(
                  title: Text(label),
                  subtitle: key == 'reducedMotion'
                      ? const Text('Keep animations still')
                      : null,
                  value: value,
                  onChanged: (v) async {
                    try {
                      await preferences.setFlag(key, v);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not save. Try again.'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ListTile(
                title: const Text('Age information'),
                subtitle: Text(
                  preferences.year?.toString() ?? 'Not shared · protected play',
                ),
                trailing: const Icon(Icons.lock_outline_rounded),
                onTap: () => editAge(context, preferences),
              ),
              if (ads.privacyRequired)
                ListTile(
                  title: const Text('Ad privacy choices'),
                  onTap: ads.privacy,
                ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Free to play, always. No purchases.\nBirth year and happy finishes stay on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: teal),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
