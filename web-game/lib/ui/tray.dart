import 'package:flutter/material.dart';
import '../game/session.dart';
import 'style.dart';

/// Full-size keys wrap to two rows on phones instead of shrinking nine targets.
class LetterTray extends StatelessWidget {
  const LetterTray({
    super.key,
    required this.session,
    required this.onLetter,
    required this.onClear,
    required this.onUndo,
    required this.onNotes,
    required this.onHint,
  });
  final Session session;
  final void Function(int) onLetter;
  final VoidCallback onClear, onUndo, onNotes, onHint;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth >= 9 * 52 + 8 * 6 ? 9 : 5;
          final width = (constraints.maxWidth - (count - 1) * 6) / count;
          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 9; i++)
                SizedBox(
                  width: width,
                  child: Semantics(
                    label:
                        'Letter ${session.puzzle.phrase.letters[i]}, ${session.remaining(i).clamp(0, 9)} remaining',
                    child: OutlinedButton(
                      key: ValueKey('letter-$i'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(48, 60),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: session.isSolved ? null : () => onLetter(i),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            session.puzzle.phrase.letters[i],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${session.remaining(i).clamp(0, 9)} left',
                            style: const TextStyle(fontSize: 11, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _Tool(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: session.canUndo ? onUndo : null,
          ),
          _Tool(
            icon: Icons.backspace_outlined,
            label: 'Erase',
            onTap: session.isSolved ? null : onClear,
          ),
          _Tool(
            icon: Icons.edit_note_rounded,
            label: 'Notes',
            active: session.noteMode,
            onTap: session.isSolved ? null : onNotes,
          ),
          _Tool(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Hint',
            onTap: session.isSolved || !session.hintsAllowed ? null : onHint,
          ),
        ],
      ),
      if (!session.hintsAllowed)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Pro: no revealing hints. Notes and Undo are available.',
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ),
    ],
  );
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        toggled: label == 'Notes' ? active : null,
        child: TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 60),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            foregroundColor: active ? Colors.white : ink,
            backgroundColor: active ? teal : Colors.white,
          ),
          onPressed: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
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
  );
}
