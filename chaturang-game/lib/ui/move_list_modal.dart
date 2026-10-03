import 'package:flutter/material.dart';

import '../engine/move.dart';
import 'theme.dart';

/// Shows a scrollable two-column move list — White on the left, Black
/// on the right, numbered row-per-pair — for a finished game. Intended
/// to be launched from the game-over modal via 'View moves'. Pure
/// presentation: takes a flat `List<Move>` in play order, no engine
/// state held inside.
Future<void> showMoveListModal(
  BuildContext context, {
  required List<Move> moves,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ChaturangTheme.deepMaroon,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(top: false, child: _MoveListSheet(moves: moves));
    },
  );
}

class _MoveListSheet extends StatelessWidget {
  const _MoveListSheet({required this.moves});

  final List<Move> moves;

  @override
  Widget build(BuildContext context) {
    // Pair white + black moves into rows. An odd-length list (game
    // ended on white's move) leaves the last row's black slot empty.
    final pairs = <(Move white, Move? black)>[];
    for (var i = 0; i < moves.length; i += 2) {
      pairs.add((moves[i], i + 1 < moves.length ? moves[i + 1] : null));
    }
    final isEmpty = pairs.isEmpty;

    return ConstrainedBox(
      constraints: BoxConstraints(
        // Cap at 80% of screen so the sheet never goes fullscreen even
        // for marathon games. Short games will size themselves naturally.
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DragHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Moves',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'RoyalSans',
                color: ChaturangTheme.saffronLight,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Text(
                'No moves were played.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ChaturangTheme.secondaryText,
                  fontSize: 14,
                ),
              ),
            )
          else ...[
            const _ColumnHeaders(),
            const SizedBox(height: 4),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: pairs.length,
                itemBuilder: (context, index) {
                  final (white, black) = pairs[index];
                  return _MoveRow(
                    moveNumber: index + 1,
                    white: white,
                    black: black,
                    isLastRow: index == pairs.length - 1,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders();

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      color: ChaturangTheme.secondaryText,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
      fontFamily: 'monospace',
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: headerStyle)),
          Expanded(child: Text('WHITE', style: headerStyle)),
          Expanded(child: Text('BLACK', style: headerStyle)),
        ],
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({
    required this.moveNumber,
    required this.white,
    required this.black,
    required this.isLastRow,
  });

  final int moveNumber;
  final Move white;
  final Move? black;

  /// Slight visual emphasis on the final row so the player can find the
  /// game-ending move at a glance. Doesn't try to guess WHICH cell
  /// ended the game — could have been either side — both cells in the
  /// last row read a touch brighter.
  final bool isLastRow;

  @override
  Widget build(BuildContext context) {
    final accent = ChaturangTheme.parchment.withValues(
      alpha: isLastRow ? 1.0 : 0.85,
    );
    final numberStyle = TextStyle(
      color: ChaturangTheme.saffronLight.withValues(
        alpha: isLastRow ? 1.0 : 0.7,
      ),
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontFamily: 'monospace',
    );
    final moveStyle = TextStyle(
      color: accent,
      fontSize: 15,
      fontFamily: 'monospace',
      fontWeight: isLastRow ? FontWeight.w700 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('$moveNumber.', style: numberStyle)),
          Expanded(child: Text(_formatMove(white), style: moveStyle)),
          Expanded(
            child: Text(
              black == null ? '' : _formatMove(black!),
              style: moveStyle,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMove(Move m) => '${m.from.algebraic} → ${m.to.algebraic}';

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: ChaturangTheme.parchment.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
