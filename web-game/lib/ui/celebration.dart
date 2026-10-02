import 'package:flutter/material.dart';

import '../game/session.dart';
import 'style.dart';

/// Solved sheet. The axis gets the credit: it is the deduction the game is
/// built around, so it leads the summary.
enum SolvedAction { again, home }

Future<SolvedAction?> showSolvedSheet(BuildContext context, Session session) {
  final elapsed = session.elapsed;
  final minutes = elapsed.inMinutes;
  final seconds = elapsed.inSeconds % 60;
  return showModalBottomSheet<SolvedAction>(
    context: context,
    backgroundColor: paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Eyebrow('Solved'),
              const SizedBox(height: 6),
              Text(
                session.puzzle.phrase.text,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 16),
              Surface(
                color: axisGlow,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: gold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The axis was ${session.puzzle.axis.label}, hidden among '
                        '${session.puzzle.viableAxesAtStart} candidates.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Time',
                      value: '$minutes:${seconds.toString().padLeft(2, '0')}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Stat(
                      label: 'Mistakes',
                      value: '${session.mistakes}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Stat(label: 'Hints', value: '${session.hintsUsed}'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(context, SolvedAction.again),
                child: Text('Play ${session.puzzle.difficulty.label} again'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, SolvedAction.home),
                child: const Text('Back to home'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Review board'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: teal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
            color: muted,
          ),
        ),
      ],
    ),
  );
}
