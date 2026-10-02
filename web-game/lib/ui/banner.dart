import 'package:flutter/material.dart';

import '../game/session.dart';
import 'style.dart';

/// The target phrase with its index ruler (spec 8.1).
///
/// Each letter sits under its position number, because every deduction in the
/// game is "position k must hold letter k". Keeping the mapping on screen is
/// what makes the axis scan a glance rather than a memory exercise.
class TargetBanner extends StatelessWidget {
  const TargetBanner({
    super.key,
    required this.session,
    this.onLetterTap,
    this.compact = false,
  });

  final bool compact;
  final Session session;
  final void Function(int)? onLetterTap;

  @override
  Widget build(BuildContext context) {
    final phrase = session.puzzle.phrase;
    final words = phrase.text.split(' ');
    var index = 0;
    final groups = <List<int>>[];
    for (final w in words) {
      groups.add([for (var i = 0; i < w.length; i++) index++]);
    }

    return Surface(
      padding: compact
          ? const EdgeInsets.all(8)
          : const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact)
            Row(
              children: [
                const Flexible(child: Eyebrow('Target phrase')),
                const SizedBox(width: 8),
                Pill(phrase.tier.label, icon: Icons.tag_rounded),
              ],
            ),
          if (!compact) const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final group in groups)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final i in group)
                      _LetterSlot(
                        index: i,
                        letter: phrase.letters[i],
                        remaining: session.remaining(i),
                        onTap: onLetterTap == null
                            ? null
                            : () => onLetterTap!(i),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LetterSlot extends StatelessWidget {
  const _LetterSlot({
    required this.index,
    required this.letter,
    required this.remaining,
    this.onTap,
  });

  final int index;
  final String letter;
  final int remaining;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = remaining == 0;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: muted,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 24,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? mint : givenFill,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: done ? teal : ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
