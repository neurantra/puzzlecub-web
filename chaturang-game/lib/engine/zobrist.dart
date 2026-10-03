import 'dart:math';

import 'pieces.dart';

/// Zobrist hashing for board positions.
///
/// Each (piece-type, side, square) combination gets a random 64-bit number,
/// plus extras for side-to-move and the two king-knight-leap-spent flags.
/// A position's hash is the XOR of all per-piece hashes that apply.
///
/// XOR is associative and commutative, so adding or removing a piece is
/// just one XOR. This lets the board maintain its hash incrementally during
/// make/undo without recomputing from scratch.
///
/// Hashes are deterministic (fixed RNG seed) so the same position always
/// produces the same hash across app runs and across isolates.
class Zobrist {
  Zobrist._();

  /// piece(type, side, file, rank) → 64-bit hash.
  static BigInt piece(PieceType type, Side side, int file, int rank) {
    final pieceIdx = type.index * 2 + side.index;
    final sqIdx = file * 8 + rank;
    return _data.piece[pieceIdx][sqIdx];
  }

  /// XOR'ed in when it's black's turn to move (white-to-move = 0).
  static BigInt get sideToMove => _data.sideToMove;

  /// XOR'ed in when [side]'s king has spent its once-per-game knight leap.
  static BigInt kingLeap(Side side) => _data.kingLeap[side.index];
}

/// Lazily-initialized hash table, materialized exactly once on first access.
/// Construction is deterministic (fixed seed) so hashes are stable.
final _ZobristData _data = _ZobristData();

class _ZobristData {
  _ZobristData() {
    final r = Random(0x6843DB7C);
    BigInt next() {
      final hi = r.nextInt(0x100000000); // 2^32
      final lo = r.nextInt(0x100000000);
      return ((BigInt.from(hi) << 32) | BigInt.from(lo)).toSigned(64);
    }

    // 6 piece types × 2 sides = 12 piece kinds; 64 squares each.
    piece = List.generate(12, (_) => List.generate(64, (_) => next()));
    sideToMove = next();
    kingLeap = [next(), next()];
  }

  late final List<List<BigInt>> piece;
  late final BigInt sideToMove;
  late final List<BigInt> kingLeap;
}
