import 'package:flutter/material.dart';

import '../game/axis.dart';
import '../game/grid.dart';
import '../game/session.dart';
import 'style.dart';
import 'game_control.dart';

/// The 9x9 board, with row and column headers that double as the axis
/// shortlist (spec 8.2: tapping a header slashes that track out).
class Board extends StatelessWidget {
  const Board({
    super.key,
    required this.session,
    required this.onHeaderTap,
    this.onCellTap,
  });

  final void Function(int row, int col)? onCellTap;
  final Session session;
  final void Function(AxisTrack) onHeaderTap;

  @override
  Widget build(BuildContext context) {
    final letters = session.puzzle.phrase.letters;
    final conflicts = session.conflicts;
    final highlight = session.selected == null
        ? <int>{}
        : session.cellsWith(
            session.board.at(session.selected! ~/ 9, session.selected! % 9),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final headerSize = 22.0;
        final boardSize = constraints.maxWidth - headerSize;
        final cell = boardSize / 9;
        return SizedBox(
          width: constraints.maxWidth,
          height: boardSize + headerSize,
          child: Column(
            children: [
              _ColumnHeaders(
                session: session,
                cell: cell,
                inset: headerSize,
                height: headerSize,
                onTap: onHeaderTap,
              ),
              SizedBox(
                height: boardSize,
                child: Row(
                  children: [
                    _RowHeaders(
                      session: session,
                      cell: cell,
                      width: headerSize,
                      onTap: onHeaderTap,
                    ),
                    SizedBox(
                      width: boardSize,
                      height: boardSize,
                      child: _Cells(
                        session: session,
                        letters: letters,
                        conflicts: conflicts,
                        highlight: highlight,
                        onCellTap: onCellTap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Cells extends StatelessWidget {
  const _Cells({
    required this.session,
    required this.letters,
    required this.conflicts,
    required this.highlight,
    this.onCellTap,
  });

  final Session session;
  final List<String> letters;
  final Set<int> conflicts;
  final Set<int> highlight;
  final void Function(int row, int col)? onCellTap;

  @override
  Widget build(BuildContext context) {
    final locked = session.lockedAxis;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink.withValues(alpha: .22), width: 1.6),
      ),
      clipBehavior: Clip.antiAlias,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
        ),
        itemCount: 81,
        itemBuilder: (context, i) {
          final r = i ~/ 9, c = i % 9;
          final value = session.board.at(r, c);
          final given = session.isGiven(r, c);
          final isSelected = session.selected == i;
          final onAxis =
              locked != null &&
              (locked.kind == AxisKind.row
                  ? locked.index == r
                  : locked.index == c);

          final marks = session.notes[i] ?? {};
          return GameControl(
            key: ValueKey('cell-$i'),
            label:
                'Row ${r + 1}, column ${c + 1}, '
                '${value == Grid.empty ? "empty" : letters[value]}'
                '${session.isFixed(r, c) ? ", fixed" : ""}'
                '${conflicts.contains(i) ? ", conflict" : ""}'
                '${marks.isEmpty ? "" : ", notes ${marks.map((v) => letters[v]).join(", ")}"}',
            selected: isSelected,
            hint: 'Select cell',
            onTap: () => (onCellTap ?? session.select)(r, c),
            child: Container(
              decoration: BoxDecoration(
                color: _fill(
                  given: given,
                  selected: isSelected,
                  onAxis: onAxis,
                  highlighted: value != Grid.empty && highlight.contains(i),
                ),
                border: Border(
                  right: BorderSide(
                    color: c % 3 == 2 && c != 8
                        ? ink.withValues(alpha: .22)
                        : line,
                    width: c % 3 == 2 && c != 8 ? 1.6 : .8,
                  ),
                  bottom: BorderSide(
                    color: r % 3 == 2 && r != 8
                        ? ink.withValues(alpha: .22)
                        : line,
                    width: r % 3 == 2 && r != 8 ? 1.6 : .8,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: isSelected ? Border.all(color: teal, width: 2) : null,
                ),
                child: Center(
                  child: value == Grid.empty
                      ? _Notes(
                          marks: session.notes[i] ?? const {},
                          letters: letters,
                        )
                      : FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Text(
                              letters[value],
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: conflicts.contains(i)
                                    ? coral
                                    : given
                                    ? ink
                                    : teal,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _fill({
    required bool given,
    required bool selected,
    required bool onAxis,
    required bool highlighted,
  }) {
    if (selected) return mint;
    if (onAxis) return axisGlow;
    if (highlighted) return mint.withValues(alpha: .45);
    if (given) return givenFill;
    return Colors.white;
  }
}

/// Pencil marks, laid out on a 3x3 micro-grid.
class _Notes extends StatelessWidget {
  const _Notes({required this.marks, required this.letters});

  final Set<int> marks;
  final List<String> letters;

  @override
  Widget build(BuildContext context) {
    if (marks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: 9,
        itemBuilder: (context, i) => FittedBox(
          child: Text(
            marks.contains(i) ? letters[i] : ' ',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders({
    required this.session,
    required this.cell,
    required this.inset,
    required this.height,
    required this.onTap,
  });

  final Session session;
  final double cell, inset, height;
  final void Function(AxisTrack) onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      children: [
        SizedBox(width: inset),
        for (var c = 0; c < 9; c++)
          SizedBox(
            width: cell,
            child: _HeaderChip(
              axis: AxisTrack(AxisKind.column, c),
              session: session,
              onTap: onTap,
            ),
          ),
      ],
    ),
  );
}

class _RowHeaders extends StatelessWidget {
  const _RowHeaders({
    required this.session,
    required this.cell,
    required this.width,
    required this.onTap,
  });

  final Session session;
  final double cell, width;
  final void Function(AxisTrack) onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      children: [
        for (var r = 0; r < 9; r++)
          SizedBox(
            height: cell,
            child: _HeaderChip(
              axis: AxisTrack(AxisKind.row, r),
              session: session,
              onTap: onTap,
            ),
          ),
      ],
    ),
  );
}

/// A row or column header. Slashed when the player has ruled it out, gold when
/// it is the confirmed axis.
class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.axis,
    required this.session,
    required this.onTap,
  });

  final AxisTrack axis;
  final Session session;
  final void Function(AxisTrack) onTap;

  @override
  Widget build(BuildContext context) {
    final out = session.ruledOut.contains(axis);
    final won = session.lockedAxis == axis;
    return GameControl(
      key: ValueKey('header-${axis.label}'),
      label:
          '${axis.kind.label} ${axis.index + 1}, ${won
              ? "confirmed"
              : out
              ? "crossed off"
              : "possible"}',
      hint: out ? 'Restore candidate' : 'Cross off candidate',
      selected: won,
      onTap: session.lockedAxis == null && !session.isSolved
          ? () => onTap(axis)
          : null,
      child: Center(
        child: Text(
          '${axis.index + 1}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: won ? teal : muted,
            decoration: out ? TextDecoration.lineThrough : null,
            decorationColor: muted,
            decorationThickness: 2,
          ),
        ),
      ),
    );
  }
}
