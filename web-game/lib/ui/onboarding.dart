import 'dart:math';
import 'package:flutter/material.dart';
import '../game/axis.dart';
import '../game/difficulty.dart';
import '../game/generator.dart';
import '../game/grid.dart';
import '../game/phrase.dart';
import '../game/puzzle.dart';
import '../game/session.dart';
import '../services/session_store.dart';
import 'banner.dart';
import 'board.dart';
import 'style.dart';

/// A deterministic practice board with real actions and no access to the save slot.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.store});
  final SessionStore store;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final Session session;
  late final int target;
  late final AxisTrack contradicted;
  late final int contradiction;
  int step = 0;
  String? feedback;
  bool finishing = false;

  @override
  void initState() {
    super.initState();
    final original = Generator(random: Random(21)).generate(
      Difficulty.medium,
      phrase: const Phrase(text: 'SUBMARINE', tier: PhraseTier.single),
    );
    final givens = Grid.copy(original.solution);
    final axisCells = {for (var i = 0; i < 9; i++) original.axis.cell(i)};
    // A nearly complete row makes the first placement a genuine forced move.
    target = List.generate(
      81,
      (i) => i,
    ).firstWhere((i) => !axisCells.contains((i ~/ 9, i % 9)));
    givens.set(target ~/ 9, target % 9, Grid.empty);
    // Leave only one blank on the target line: the remaining eight letters
    // visibly demonstrate why that line, and no other, matches the phrase.
    final (ar, ac) = List.generate(
      9,
      original.axis.cell,
    ).firstWhere((cell) => cell.$1 != target ~/ 9);
    givens.set(ar, ac, Grid.empty);
    session = Session(
      Puzzle(
        id: 'practice-v1',
        phrase: original.phrase,
        difficulty: Difficulty.medium,
        axis: original.axis,
        givens: givens,
        solution: original.solution,
        viableAxesAtStart: compatibleAxes(givens).length,
      ),
    )..pause();
    contradicted = AxisTrack.all.firstWhere((a) => !a.isCompatible(givens));
    contradiction = List.generate(9, (i) => i).firstWhere((i) {
      final (r, c) = contradicted.cell(i);
      return !givens.isEmpty(r, c) && givens.at(r, c) != i;
    });
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  void _select(int r, int c) {
    if (step != 0 || r * 9 + c != target) {
      setState(
        () => feedback = 'Use the highlighted instruction above the board.',
      );
      return;
    }
    session.select(r, c);
    setState(() {
      step = 1;
      feedback = null;
    });
  }

  void _place(int value) {
    if (value != session.puzzle.solution.cells[target]) {
      setState(
        () => feedback =
            'Look across this row. Which letter is missing? Try again.',
      );
      return;
    }
    session.place(value);
    setState(() {
      step = 2;
      feedback = null;
    });
  }

  void _cross(AxisTrack axis) {
    if (step != 2 || axis != contradicted) {
      setState(
        () =>
            feedback = 'Compare ${contradicted.label} with the target phrase.',
      );
      return;
    }
    session.toggleAxis(axis);
    setState(() {
      step = 3;
      feedback = null;
    });
  }

  Future<void> _finish() async {
    setState(() => finishing = true);
    try {
      await widget.store.completeTutorial();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          finishing = false;
          feedback = 'Could not remember completion. Tap Finish to retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final letters = session.puzzle.phrase.letters;
    final (cr, cc) = contradicted.cell(contradiction);
    final instructions = [
      'Every row, column and 3×3 box uses all nine letters once. Select the empty cell at row ${target ~/ 9 + 1}, column ${target % 9 + 1}.',
      'Only one letter is missing from this row. Tap it below. Starting letters cannot be changed.',
      '${contradicted.kind.label} ${contradicted.index + 1} has ${letters[session.board.at(cr, cc)]} in position ${contradiction + 1}; the phrase needs ${letters[contradiction]}. Cross off that line.',
      '${session.puzzle.axis.label} matches the phrase in all eight filled positions. Confirm this hidden line to reveal its missing letter.',
      'You did it! Medium fills a confirmed line. Hard uses Expert Deduction: fill the letters yourself. Pro adds a no-hints challenge. Your normal games save automatically.',
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn by playing'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Surface(
                    color: axisGlow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          step == 4
                              ? 'Practice complete'
                              : 'Step ${step + 1} of 4',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          child: Text(instructions[step]),
                        ),
                        if (feedback != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              feedback!,
                              style: const TextStyle(color: coral),
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (step == 0)
                          OutlinedButton(
                            onPressed: () => _select(target ~/ 9, target % 9),
                            child: Text(
                              'Select row ${target ~/ 9 + 1}, column ${target % 9 + 1}',
                            ),
                          ),
                        if (step == 1)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < 9; i++)
                                SizedBox(
                                  width: 52,
                                  child: OutlinedButton(
                                    key: ValueKey('practice-letter-$i'),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () => _place(i),
                                    child: Text(letters[i]),
                                  ),
                                ),
                            ],
                          ),
                        if (step == 2)
                          OutlinedButton(
                            onPressed: () => _cross(contradicted),
                            child: Text('Cross off ${contradicted.label}'),
                          ),
                        if (step == 3)
                          FilledButton(
                            onPressed: () {
                              session.commitAxis(session.puzzle.axis);
                              setState(() {
                                step = 4;
                                feedback = null;
                              });
                            },
                            child: Text('Confirm ${session.puzzle.axis.label}'),
                          ),
                        if (step == 4)
                          FilledButton(
                            onPressed: finishing ? null : _finish,
                            child: Text(
                              finishing ? 'Saving…' : 'Finish tutorial',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TargetBanner(session: session),
                  const SizedBox(height: 14),
                  Board(
                    session: session,
                    onHeaderTap: _cross,
                    onCellTap: _select,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Practice is separate from your saved puzzle. You can replay it from Home.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
