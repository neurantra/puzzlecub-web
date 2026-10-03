import 'move.dart';
import 'pieces.dart';
import 'square.dart';

/// Position -> move lookup for the opening.
///
/// Chaturang has no published theory, so the book is grown from the engine's
/// own deep analysis by `tool/build_book.dart`. It does not make the engine
/// find better opening moves than it otherwise would — it is the same engine
/// — it makes it find them instantly, and spend the whole search budget on
/// the middlegame instead of rediscovering the same first moves every game.
///
/// Keyed by Zobrist hash, so transpositions hit the same entry.
class OpeningBook {
  const OpeningBook._(this._moves);

  final Map<BigInt, Move> _moves;

  static const OpeningBook empty = OpeningBook._({});

  int get length => _moves.length;

  /// The book move for [zobrist], or null when out of book.
  Move? lookup(BigInt zobrist) => _moves[zobrist];

  /// Parses the text format written by `tool/build_book.dart`:
  /// a hex Zobrist key, a space, then the move as `e2e4` with an optional
  /// promotion letter. Blank lines and `#` comments are ignored.
  ///
  /// A malformed line is skipped rather than thrown: a book is an
  /// optimisation, and a corrupt one should cost the engine its head start,
  /// not the game.
  factory OpeningBook.parse(String text) {
    final moves = <BigInt, Move>{};
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length != 2) continue;
      final key = BigInt.tryParse(parts[0], radix: 16)?.toSigned(64);
      final move = _decode(parts[1]);
      if (key == null || move == null) continue;
      moves[key] = move;
    }
    return OpeningBook._(Map.unmodifiable(moves));
  }

  static Move? _decode(String s) {
    if (s.length < 4 || s.length > 5) return null;
    // Uses the board's own algebraic convention (rank 0 is Black's back
    // rank, so a1 is (0, 0)) rather than inventing a second one.
    final Square from;
    final Square to;
    try {
      from = Square.algebraic(s.substring(0, 2));
      to = Square.algebraic(s.substring(2, 4));
    } catch (_) {
      return null;
    }
    PieceType? promotion;
    if (s.length == 5) {
      for (final t in PieceType.values) {
        if (t.letter == s[4].toUpperCase()) promotion = t;
      }
      if (promotion == null) return null;
    }
    return Move(from: from, to: to, promotion: promotion);
  }
}
