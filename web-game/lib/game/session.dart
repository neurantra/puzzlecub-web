import 'package:flutter/foundation.dart';

import 'axis.dart';
import 'grid.dart';
import 'puzzle.dart';

/// Live state of one play-through: the board, pencil marks, the player's axis
/// shortlist, and the history needed for undo.
class Session extends ChangeNotifier {
  Session(this.puzzle, {DateTime Function()? now})
    : board = Grid.copy(puzzle.givens),
      _now = now ?? DateTime.now {
    _runningSince = _now();
    if (puzzle.difficulty.revealAxis) {
      lockedAxis = puzzle.axis;
      puzzle.axis.apply(board);
      _ruledOut.addAll(AxisTrack.all.where((a) => a != puzzle.axis));
    }
  }

  final Puzzle puzzle;
  final Grid board;

  /// Pencil marks per cell index.
  final Map<int, Set<int>> notes = {};

  final Set<AxisTrack> _ruledOut = {};
  final List<_Move> _history = [];

  int? selected;
  bool noteMode = false;
  AxisTrack? lockedAxis;
  final DateTime Function() _now;
  DateTime? _runningSince;
  Duration _accumulated = Duration.zero;
  int hintsUsed = 0;
  int mistakes = 0;

  /// Axes the player has crossed off by hand.
  Set<AxisTrack> get ruledOut => Set.unmodifiable(_ruledOut);

  /// Axes still on the player's shortlist.
  List<AxisTrack> get shortlist =>
      AxisTrack.all.where((a) => !_ruledOut.contains(a)).toList();

  /// Axes a scan of the board cannot rule out. Used to validate the player's
  /// own slashes without giving the answer away.
  List<AxisTrack> get scannableAxes => compatibleAxes(board);

  bool isGiven(int row, int col) => !puzzle.givens.isEmpty(row, col);

  bool get isSolved =>
      board.isComplete &&
      board.cells.toString() == puzzle.solution.cells.toString();

  Duration get elapsed =>
      _accumulated +
      (_runningSince == null
          ? Duration.zero
          : _now().difference(_runningSince!));

  void pause() {
    _accumulated = elapsed;
    _runningSince = null;
  }

  void resume() {
    if (!isSolved) _runningSince ??= _now();
  }

  bool get canUndo => !isSolved && _history.isNotEmpty;
  bool get hintsAllowed => puzzle.difficulty.allowsHints;
  bool isFixed(int row, int col) =>
      isGiven(row, col) ||
      (puzzle.difficulty.autoFillAxis &&
          lockedAxis != null &&
          (lockedAxis!.kind == AxisKind.row
              ? lockedAxis!.index == row
              : lockedAxis!.index == col));

  void _changed() {
    if (isSolved) pause();
    notifyListeners();
  }

  /// Letters still to be placed, by letter index.
  int remaining(int letterIndex) => puzzle.remainingOf(board, letterIndex);

  void select(int row, int col) {
    if (row < 0 || row > 8 || col < 0 || col > 8) return;
    selected = row * 9 + col;
    _changed();
  }

  void toggleNoteMode() {
    if (isSolved) return;
    noteMode = !noteMode;
    _changed();
  }

  /// Place [letterIndex] into the selected cell, or pencil it in.
  ///
  /// Returns false when the move is rejected: givens are immovable.
  bool place(int letterIndex) {
    if (letterIndex < 0 || letterIndex > 8) return false;
    final i = selected;
    if (i == null) return false;
    final r = i ~/ 9, c = i % 9;
    if (isSolved || isFixed(r, c)) return false;

    if (noteMode) {
      if (!board.isEmpty(r, c)) return false;
      final set = notes.putIfAbsent(i, () => <int>{});
      _history.add(_Move.note(i, letterIndex, set.contains(letterIndex)));
      set.contains(letterIndex)
          ? set.remove(letterIndex)
          : set.add(letterIndex);
      _changed();
      return true;
    }

    final previous = board.at(r, c);
    if (previous == letterIndex) return clear();

    _history.add(_Move.cell(i, previous, notes[i]?.toSet()));
    board.set(r, c, letterIndex);
    notes.remove(i);
    if (puzzle.solution.at(r, c) != letterIndex) mistakes++;
    _changed();
    return true;
  }

  bool clear() {
    final i = selected;
    if (i == null) return false;
    final r = i ~/ 9, c = i % 9;
    if (isSolved || isFixed(r, c)) return false;
    if (board.isEmpty(r, c) && (notes[i]?.isEmpty ?? true)) return false;

    _history.add(_Move.cell(i, board.at(r, c), notes[i]?.toSet()));
    board.set(r, c, Grid.empty);
    notes.remove(i);
    _changed();
    return true;
  }

  void undo() {
    if (!canUndo) return;
    final move = _history.removeLast();
    if (move.axisBoard != null) {
      for (var i = 0; i < 81; i++) {
        board.set(i ~/ 9, i % 9, move.axisBoard!.at(i ~/ 9, i % 9));
      }
      notes
        ..clear()
        ..addAll(move.axisNotes!);
      lockedAxis = null;
      _ruledOut
        ..clear()
        ..addAll(move.axisRuledOut!);
    } else if (move.isNote) {
      final set = notes.putIfAbsent(move.index, () => <int>{});
      move.noteWasSet ? set.add(move.value!) : set.remove(move.value!);
    } else {
      board.set(move.index ~/ 9, move.index % 9, move.value ?? Grid.empty);
      if (move.notes == null) {
        notes.remove(move.index);
      } else {
        notes[move.index] = move.notes!;
      }
    }
    _changed();
  }

  /// Cross an axis off the shortlist, or restore it.
  void toggleAxis(AxisTrack axis) {
    if (isSolved || lockedAxis != null) return;
    _ruledOut.contains(axis) ? _ruledOut.remove(axis) : _ruledOut.add(axis);
    _changed();
  }

  /// Commit to an axis. Writing the phrase along the right track is the
  /// game's payoff; the wrong one costs a mistake and nothing else.
  bool commitAxis(AxisTrack axis) {
    if (isSolved || lockedAxis != null) return false;
    if (axis != puzzle.axis) {
      mistakes++;
      _ruledOut.add(axis);
      _changed();
      return false;
    }
    _history.add(_Move.axis(board, notes, _ruledOut));
    lockedAxis = axis;
    if (puzzle.difficulty.autoFillAxis) {
      for (var step = 0; step < Grid.size; step++) {
        final (r, c) = axis.cell(step);
        board.set(r, c, step);
        notes.remove(r * 9 + c);
      }
    }
    _ruledOut
      ..clear()
      ..addAll(AxisTrack.all.where((a) => a != axis));
    _changed();
    return true;
  }

  /// Reveal one correct letter in the selected cell.
  bool hint() {
    if (isSolved || !hintsAllowed) return false;
    final i = selected;
    if (i == null) return false;
    final r = i ~/ 9, c = i % 9;
    if (!board.isEmpty(r, c)) return false;
    _history.add(_Move.cell(i, board.at(r, c), notes[i]?.toSet()));
    hintsUsed++;
    board.set(r, c, puzzle.solution.at(r, c));
    notes.remove(i);
    _changed();
    return true;
  }

  Map<String, Object?> toSave() => {
    'version': 1,
    'puzzle': puzzle.toSave(),
    'board': board.cells,
    'notes': _writeNotes(notes),
    'ruledOut': _ruledOut.map(AxisTrack.all.indexOf).toList(),
    'lockedAxis': lockedAxis == null
        ? null
        : AxisTrack.all.indexOf(lockedAxis!),
    'selected': selected,
    'noteMode': noteMode,
    'elapsedMs': elapsed.inMilliseconds,
    'mistakes': mistakes,
    'hintsUsed': hintsUsed,
    'history': _history.map((move) => move.toSave()).toList(),
  };

  factory Session.fromSave(
    Map<String, dynamic> data, {
    DateTime Function()? now,
  }) {
    if (data['version'] != 1) {
      throw const FormatException('Unsupported save version');
    }
    final puzzle = Puzzle.fromSave(data['puzzle'] as Map<String, dynamic>);
    final session = Session(puzzle, now: now)..pause();
    final saved = readSavedGrid(data['board']);
    for (var i = 0; i < 81; i++) {
      if (puzzle.givens.cells[i] != Grid.empty &&
          saved.cells[i] != puzzle.givens.cells[i]) {
        throw const FormatException('A saved starting letter changed');
      }
      session.board.set(i ~/ 9, i % 9, saved.cells[i]);
    }
    session.notes.addAll(_readNotes(data['notes']));
    session._ruledOut
      ..clear()
      ..addAll(_readAxes(data['ruledOut']));
    session.lockedAxis = data['lockedAxis'] == null
        ? null
        : _readAxis(data['lockedAxis']);
    if (session.lockedAxis != null && session.lockedAxis != puzzle.axis) {
      throw const FormatException('Invalid line confirmation');
    }
    if (session.lockedAxis != null &&
        puzzle.difficulty.autoFillAxis &&
        !session.lockedAxis!.spellsPhrase(session.board)) {
      throw const FormatException('Invalid revealed line');
    }
    session.selected = data['selected'] as int?;
    if (session.selected != null &&
        (session.selected! < 0 || session.selected! > 80)) {
      throw const FormatException('Invalid selection');
    }
    session.noteMode = data['noteMode'] as bool;
    final ms = data['elapsedMs'] as int;
    session.mistakes = data['mistakes'] as int;
    session.hintsUsed = data['hintsUsed'] as int;
    if (ms < 0 || session.mistakes < 0 || session.hintsUsed < 0) {
      throw const FormatException('Invalid statistics');
    }
    session._accumulated = Duration(milliseconds: ms);
    session._history.addAll(
      (data['history'] as List).map(
        (v) => _Move.fromSave(v as Map<String, dynamic>),
      ),
    );
    if (puzzle.difficulty.revealAxis && session.lockedAxis != puzzle.axis) {
      throw const FormatException('Missing revealed line');
    }
    for (final entry in session.notes.entries) {
      if (entry.value.isNotEmpty &&
          session.board.cells[entry.key] != Grid.empty) {
        throw const FormatException('Notes under a filled cell');
      }
    }
    for (final move in session._history) {
      if (move.axisBoard != null) {
        for (var i = 0; i < 81; i++) {
          if (puzzle.givens.cells[i] != Grid.empty &&
              move.axisBoard!.cells[i] != puzzle.givens.cells[i]) {
            throw const FormatException('Undo would change a starting letter');
          }
        }
      } else if (puzzle.givens.cells[move.index] != Grid.empty) {
        throw const FormatException('Undo would change a starting letter');
      }
    }
    return session;
  }

  /// Cells holding [letterIndex], for the tray's highlight-all behaviour.
  Set<int> cellsWith(int letterIndex) => {
    for (var i = 0; i < 81; i++)
      if (board.at(i ~/ 9, i % 9) == letterIndex) i,
  };

  /// Cells that conflict with another placement, for live error marking.
  Set<int> get conflicts {
    final bad = <int>{};
    for (var i = 0; i < 81; i++) {
      final r = i ~/ 9, c = i % 9;
      final v = board.at(r, c);
      if (v == Grid.empty) continue;
      if (!board.allows(r, c, v)) bad.add(i);
    }
    return bad;
  }
}

class _Move {
  _Move.cell(this.index, this.value, this.notes)
    : isNote = false,
      noteWasSet = false;
  _Move.note(this.index, this.value, this.noteWasSet)
    : isNote = true,
      notes = null;

  _Move.axis(Grid board, Map<int, Set<int>> marks, Set<AxisTrack> ruledOut)
    : index = -1,
      value = null,
      notes = null,
      isNote = false,
      noteWasSet = false {
    axisBoard = Grid.copy(board);
    axisNotes = {
      for (final entry in marks.entries) entry.key: entry.value.toSet(),
    };
    axisRuledOut = ruledOut.toSet();
  }

  Map<String, Object?> toSave() => {
    'index': index,
    'value': value,
    'notes': notes?.toList(),
    'isNote': isNote,
    'noteWasSet': noteWasSet,
    'axisBoard': axisBoard?.cells,
    'axisNotes': axisNotes == null ? null : _writeNotes(axisNotes!),
    'axisRuledOut': axisRuledOut?.map(AxisTrack.all.indexOf).toList(),
  };

  factory _Move.fromSave(Map<String, dynamic> data) {
    if (data['axisBoard'] != null) {
      return _Move.axis(
        readSavedGrid(data['axisBoard']),
        _readNotes(data['axisNotes']),
        _readAxes(data['axisRuledOut']),
      );
    }
    final index = data['index'] as int;
    final value = data['value'] as int;
    final isNote = data['isNote'] as bool;
    if (index < 0 || index > 80 || value < (isNote ? 0 : -1) || value > 8) {
      throw const FormatException('Invalid undo move');
    }
    return isNote
        ? _Move.note(index, value, data['noteWasSet'] as bool)
        : _Move.cell(
            index,
            value,
            data['notes'] == null ? null : _readMarks(data['notes']),
          );
  }

  Grid? axisBoard;
  Map<int, Set<int>>? axisNotes;
  Set<AxisTrack>? axisRuledOut;

  final int index;
  final int? value;
  final Set<int>? notes;
  final bool isNote;
  final bool noteWasSet;
}

Map<String, Object?> _writeNotes(Map<int, Set<int>> notes) => {
  for (final entry in notes.entries) '${entry.key}': entry.value.toList(),
};
Set<int> _readMarks(dynamic value) {
  final marks = (value as List).cast<int>().toSet();
  if (marks.any((v) => v < 0 || v > 8)) {
    throw const FormatException('Invalid notes');
  }
  return marks;
}

Map<int, Set<int>> _readNotes(dynamic value) {
  final result = <int, Set<int>>{};
  for (final entry in (value as Map<String, dynamic>).entries) {
    final index = int.parse(entry.key);
    if (index < 0 || index > 80) {
      throw const FormatException('Invalid note cell');
    }
    result[index] = _readMarks(entry.value);
  }
  return result;
}

AxisTrack _readAxis(dynamic value) {
  final index = value as int;
  if (index < 0 || index >= 18) throw const FormatException('Invalid line');
  return AxisTrack.all[index];
}

Set<AxisTrack> _readAxes(dynamic value) =>
    (value as List).map(_readAxis).toSet();
