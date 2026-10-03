/// A square on the 8x8 board.
///
/// Coordinate system follows the legacy game: rank 0 is Black's back rank,
/// rank 7 is White's back rank. White moves up the board (rank decreases).
///
/// Algebraic notation uses 1-indexed ranks, so `a1` = (file 0, rank 0) =
/// Black's a-file rook starting square, and `h8` = (file 7, rank 7) =
/// White's h-file rook starting square.
class Square {
  const Square(this.file, this.rank)
    : assert(file >= 0 && file < 8, 'file out of range'),
      assert(rank >= 0 && rank < 8, 'rank out of range');

  factory Square.algebraic(String s) {
    if (s.length != 2) {
      throw ArgumentError.value(s, 'algebraic', 'must be length 2');
    }
    final f = s.codeUnitAt(0) - 0x61; // 'a'
    final r = int.parse(s[1]) - 1;
    return Square(f, r);
  }

  final int file;
  final int rank;

  String get algebraic => '${String.fromCharCode(0x61 + file)}${rank + 1}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Square && other.file == file && other.rank == rank);

  @override
  int get hashCode => file * 8 + rank;

  @override
  String toString() => algebraic;
}
