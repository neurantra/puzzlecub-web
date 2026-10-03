import 'dart:math';

/// Alphabets use a 5×5 sliding area and fixed shelf; numbers use all 6×5 cells.
/// Numbers share the alphabet mode's stable internal tile identities; visible
/// values are row + column + 1, and equal values are interchangeable.
enum PuzzleKind { alphabets, numbers, sequential }

class PuzzleBoard {
  static const String lockedEmptyTile = '__locked_empty__';
  static const int activeRows = 5;
  static const int activeColumns = 5;
  static const int activeTileCount = activeRows * activeColumns; // 25
  static const int movableSymbolCount = 24; // A..X

  PuzzleBoard({
    this.kind = PuzzleKind.alphabets,
    required this.rows,
    required this.columns,
    required List<String?> tiles,
  }) : tiles = List.unmodifiable(tiles) {
    if (tiles.length != rows * columns) {
      throw ArgumentError('Tile count must equal rows * columns.');
    }
  }

  factory PuzzleBoard.solved({
    int rows = 6,
    int columns = 5,
    PuzzleKind kind = PuzzleKind.alphabets,
  }) {
    if (rows != 6 || columns != 5) {
      throw ArgumentError('Alphabet mode needs a 6×5 display grid.');
    }
    final tileCount = rows * columns;
    final numberMode = kind != PuzzleKind.alphabets;
    final symbols = List<String?>.generate(tileCount, (index) {
      if (index < (numberMode ? tileCount - 1 : movableSymbolCount)) {
        return String.fromCharCode('A'.codeUnitAt(0) + index);
      }
      if (index == (numberMode ? tileCount - 1 : activeTileCount - 1)) {
        return null; // blank
      }
      if (index == activeTileCount) return 'Y';
      if (index == activeTileCount + 1) return 'Z';
      return lockedEmptyTile;
    });
    return PuzzleBoard(
      rows: rows,
      columns: columns,
      tiles: symbols,
      kind: kind,
    );
  }

  final PuzzleKind kind;
  bool get isNumbers => kind != PuzzleKind.alphabets;
  int get playableRows => isNumbers ? rows : activeRows;
  int get playableCells => playableRows * columns;
  int get symbolCount => playableCells - 1;

  // Stable internal identities preserve tile animations and the solver's legal
  // permutation. Displayed values, not identities, determine number-mode wins.
  String displaySymbol(String tile) {
    if (!isNumbers || tile == lockedEmptyTile) return tile;
    final goal = tile.codeUnitAt(0) - 65;
    return kind == PuzzleKind.sequential
        ? '${goal + 1}'
        : '${goal ~/ 5 + goal % 5 + 1}';
  }

  bool correctAt(int index) {
    if (index == symbolCount) return tiles[index] == null;
    final tile = tiles[index];
    if (tile == null || tile == lockedEmptyTile) return false;
    return displaySymbol(tile) ==
        displaySymbol(String.fromCharCode(65 + index));
  }

  final int rows;
  final int columns;
  final List<String?> tiles;

  int get blankIndex => tiles.indexOf(null);

  bool get isSolved {
    for (var index = 0; index < symbolCount; index++) {
      if (!correctAt(index)) {
        return false;
      }
    }
    return tiles[symbolCount] == null &&
        (isNumbers ||
            (tiles[activeTileCount] == 'Y' &&
                tiles[activeTileCount + 1] == 'Z' &&
                tiles
                    .skip(activeTileCount + 2)
                    .every((tile) => tile == lockedEmptyTile)));
  }

  /// How many movable symbols currently sit in their solved positions.
  /// Used for the consolation score when the player runs out of moves.
  int get correctlyPlacedCount {
    var n = 0;
    for (var i = 0; i < symbolCount; i++) {
      if (correctAt(i)) n++;
    }
    return n;
  }

  /// How many of the [playableRows] rows are fully in their solved state.
  /// A row counts when every cell holds its solved tile — for the last
  /// active row that includes the blank at index [activeTileCount] − 1.
  /// Used as the vs-AI race progress metric (0..5 → 0–100%).
  int get completedRows {
    var done = 0;
    for (var r = 0; r < playableRows; r++) {
      var rowComplete = true;
      for (var c = 0; c < activeColumns; c++) {
        final i = r * columns + c;
        final ok = i < symbolCount
            ? correctAt(i)
            : tiles[i] == null; // the blank closes the final row
        if (!ok) {
          rowComplete = false;
          break;
        }
      }
      if (rowComplete) done++;
    }
    return done;
  }

  bool canMove(int tileIndex) {
    if (tileIndex < 0 || tileIndex >= tiles.length) return false;
    final tile = tiles[tileIndex];
    return tileIndex < playableCells &&
        tile != null &&
        tile != lockedEmptyTile &&
        _isAdjacent(tileIndex, blankIndex);
  }

  PuzzleBoard move(int tileIndex) {
    if (!canMove(tileIndex)) return this;
    final next = tiles.toList();
    next[blankIndex] = next[tileIndex];
    next[tileIndex] = null;
    return PuzzleBoard(rows: rows, columns: columns, tiles: next, kind: kind);
  }

  PuzzleBoard shuffled({int moves = 180, Random? random}) {
    final rng = random ?? Random();
    var board = this;
    int? previousBlank;
    for (var step = 0; step < moves; step++) {
      final neighbors = board._movableIndexes().where((index) {
        return previousBlank == null || index != previousBlank;
      }).toList();
      final choices = neighbors.isEmpty ? board._movableIndexes() : neighbors;
      previousBlank = board.blankIndex;
      board = board.move(choices[rng.nextInt(choices.length)]);
    }
    return board;
  }

  List<int> _movableIndexes() {
    final blank = blankIndex;
    return List<int>.generate(playableCells, (index) => index)
        .where((index) => tiles[index] != null && _isAdjacent(index, blank))
        .toList();
  }

  bool _isAdjacent(int a, int b) {
    final rowA = a ~/ columns;
    final colA = a % columns;
    final rowB = b ~/ columns;
    final colB = b % columns;
    return (rowA - rowB).abs() + (colA - colB).abs() == 1;
  }
}
