import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/move.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shuffling two knights back and forth repeats', () {
    final b = Board();
    expect(b.repetitionCount(), 1, reason: 'start position seen once');
    expect(b.isRepetition, isFalse);

    // Knights out and back: after both sides return, the start position is
    // on the board a second time.
    const out = [
      Move(from: Square(1, 7), to: Square(2, 5)),
      Move(from: Square(1, 0), to: Square(2, 2)),
      Move(from: Square(2, 5), to: Square(1, 7)),
      Move(from: Square(2, 2), to: Square(1, 0)),
    ];
    for (final m in out) {
      b.makeMove(m);
    }
    expect(b.repetitionCount(), 2);
    expect(b.isRepetition, isTrue);

    for (final m in out) {
      b.makeMove(m);
    }
    expect(b.repetitionCount(), 3, reason: 'threefold');

    // And it unwinds exactly.
    for (var i = 0; i < 8; i++) {
      b.undoMove();
    }
    expect(b.repetitionCount(), 1);
    expect(b.isRepetition, isFalse);
  });

  test('a capture erases everything before it', () {
    final b = Board();
    b.setupCustom({
      const Square(4, 7): const Piece(PieceType.king, Side.white),
      const Square(4, 0): const Piece(PieceType.king, Side.black),
      const Square(0, 4): const Piece(PieceType.rook, Side.white),
      const Square(1, 4): const Piece(PieceType.rook, Side.black),
    }, sideToMove: Side.white);

    b.makeMove(const Move(from: Square(0, 4), to: Square(1, 4))); // capture
    // Nothing before the capture can recur, so the scan must not reach back
    // past it and report a false repetition.
    expect(b.repetitionCount(), 1);
    expect(b.isRepetition, isFalse);
  });

  test('the seeded key matches the real hash', () {
    // Regression: seeding the history before _recomputeZobrist stored a
    // stale hash, so returning to the start position was never detected.
    final b = Board();
    final start = b.zobrist;
    b.makeMove(const Move(from: Square(1, 7), to: Square(2, 5)));
    b.makeMove(const Move(from: Square(1, 0), to: Square(2, 2)));
    b.makeMove(const Move(from: Square(2, 5), to: Square(1, 7)));
    b.makeMove(const Move(from: Square(2, 2), to: Square(1, 0)));
    expect(b.zobrist, start);
    expect(
      b.repetitionCount(),
      2,
      reason: 'start position not recognised on return',
    );
  });
}
