import 'package:flutter/material.dart';

import 'style.dart';
import 'techniques.dart';

Future<void> showRulesSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  backgroundColor: paper,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .8,
    maxChildSize: .95,
    builder: (context, controller) => ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
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
        Text('How to play', style: Theme.of(context).textTheme.headlineSmall),
        TextButton.icon(
          onPressed: () => showTechniques(context),
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text('Solving techniques'),
        ),
        const SizedBox(height: 16),
        const _Rule(
          n: '1',
          title: 'It is a Sudoku, in letters',
          body:
              'Nine letters replace the digits 1-9. Every row, every column '
              'and every 3x3 box holds all nine letters exactly once.',
        ),
        const _Rule(
          n: '2',
          title: 'The phrase is never a secret',
          body:
              'The target phrase is shown from the start, numbered 1 to 9. '
              'You are never guessing which letters are in play - only where '
              'they go.',
        ),
        const _Rule(
          n: '3',
          title: 'One track spells it',
          body:
              'Exactly one row or one column spells the phrase in reading '
              'order: letter 1 in position 1, letter 2 in position 2, and so '
              'on. Eighteen tracks, one answer.',
        ),
        const _Rule(
          n: '4',
          title: 'Scan, then slash',
          body:
              'If a track already holds a letter that disagrees with the '
              'phrase, it cannot be the axis. Tap its header number to cross '
              'it off and narrow the field.',
        ),
        const _Rule(
          n: '5',
          title: 'Lock it in',
          body:
              'Tap Choose a line to open large row and column controls. Cross off '
              'impossible lines or confirm your deduction. Medium fills a correct '
              'line. Hard and Pro confirm it without filling any letters.',
        ),
        const _Rule(
          n: '6',
          title: 'Place letters and use your tools',
          body:
              'Tap a cell, then a letter below the board. Tinted starting '
              'letters are fixed. Tap a filled cell to highlight matching letters. '
              '“5 left” means five more copies of that letter remain to be placed. Each letter appears nine times. These counts include incorrect entries; they do not verify correctness. '
              'Notes toggles pencil marks in empty cells. Erase clears a selected '
              'editable cell and its notes. Before completion, Undo reverses your last placement, '
              'note, erase, hint or successful confirmation. Revealed Easy and Medium '
              'line letters are protected; Undo a Medium confirmation to restore the '
              'previous board. Hint fills a selected empty '
              'cell with its correct letter on Easy, Medium and Hard, using an earned ad credit or Unlimited Hints. Pro has no revealing hints.',
        ),
        const _Rule(
          n: '7',
          title: 'Choose your challenge',
          body:
              'Easy reveals the hidden line. Medium introduces the hunt. '
              'Hard adds Expert Deduction: fill a confirmed line yourself. Pro adds '
              'a no-hints challenge with fewer starting letters. '
              'Red letters mark duplicate conflicts; the final mistake count '
              'also includes incorrect placements and wrong lock attempts. '
              'Complete the grid to see your time, mistakes and tier.',
        ),
        const _Rule(
          n: '8',
          title: 'Help and navigation',
          body:
              'Open this help from the question mark on Home or in a puzzle. '
              'Swipe down to close it. The back arrow returns Home. Progress '
              'saves on this device after each action and when you leave. Continue on '
              'Home restores your board, notes and Undo history. Time pauses in '
              'the background. There is one saved-game slot. After a win, Play '
              'again starts the same tier, Back to home changes tiers, and Review '
              'board keeps the completed grid visible.',
        ),
        const _Rule(
          n: '9',
          title: 'Unlimited browser play',
          body:
              'Puzzles are unlimited on PuzzleCub. Hints are free during the launch beta in Easy, Medium and Hard. Pro stays unassisted. There are no purchases. Your saved game stays in this browser.',
        ),
        const _Rule(
          n: '10',
          title: 'Accessible ways to play',
          body:
              'Use the Row and Column selectors to select a cell without tapping '
              'small grid squares. Choose a line opens full-size elimination and '
              'confirmation controls. With a keyboard, use arrows to move, letters '
              'or 1–9 to enter a value, Backspace to erase, and Control-Z or '
              'Command-Z to undo. Tab moves between controls; Enter activates them.',
        ),
      ],
    ),
  ),
);

class _Rule extends StatelessWidget {
  const _Rule({required this.n, required this.title, required this.body});

  final String n, title, body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: teal, shape: BoxShape.circle),
          child: Text(
            n,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
