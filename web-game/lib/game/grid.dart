/// A nine-by-nine Alphadoku grid.
///
/// Cells hold a letter *index* into the puzzle's phrase (0-8), or [empty] for a
/// blank. Working in indices rather than characters keeps the solver identical
/// to a digit Sudoku solver; letters are only reapplied for display.
class Grid {
  Grid() : _cells = List.filled(81, empty);
  Grid.from(List<int> cells) : _cells = List.of(cells);
  Grid.copy(Grid other) : _cells = List.of(other._cells);

  static const int empty = -1;
  static const int size = 9;

  final List<int> _cells;

  List<int> get cells => List.unmodifiable(_cells);

  int at(int row, int col) => _cells[row * size + col];
  void set(int row, int col, int value) => _cells[row * size + col] = value;

  bool isEmpty(int row, int col) => at(row, col) == empty;
  int get filledCount => _cells.where((v) => v != empty).length;
  bool get isComplete => !_cells.contains(empty);

  static int boxOf(int row, int col) => (row ~/ 3) * 3 + col ~/ 3;

  List<int> row(int r) => [for (var c = 0; c < size; c++) at(r, c)];
  List<int> column(int c) => [for (var r = 0; r < size; r++) at(r, c)];

  /// The nine cells of box [b], in reading order.
  List<int> box(int b) {
    final r0 = (b ~/ 3) * 3, c0 = (b % 3) * 3;
    return [
      for (var r = r0; r < r0 + 3; r++)
        for (var c = c0; c < c0 + 3; c++) at(r, c),
    ];
  }

  /// Whether [value] may legally go at (row, col) under the classical rules.
  bool allows(int row, int col, int value) {
    for (var i = 0; i < size; i++) {
      if (i != col && at(row, i) == value) return false;
      if (i != row && at(i, col) == value) return false;
    }
    final r0 = (row ~/ 3) * 3, c0 = (col ~/ 3) * 3;
    for (var r = r0; r < r0 + 3; r++) {
      for (var c = c0; c < c0 + 3; c++) {
        if ((r != row || c != col) && at(r, c) == value) return false;
      }
    }
    return true;
  }

  /// True when no unit repeats a value. Blanks are ignored, so a partial grid
  /// can still be consistent.
  bool get isConsistent {
    for (var i = 0; i < size; i++) {
      if (_repeats(row(i)) || _repeats(column(i)) || _repeats(box(i))) {
        return false;
      }
    }
    return true;
  }

  static bool _repeats(List<int> unit) {
    final seen = <int>{};
    for (final v in unit) {
      if (v == empty) continue;
      if (!seen.add(v)) return true;
    }
    return false;
  }

  /// Candidate values for an empty cell.
  Set<int> candidates(int row, int col) {
    if (!isEmpty(row, col)) return const {};
    return {
      for (var v = 0; v < size; v++)
        if (allows(row, col, v)) v,
    };
  }
}
