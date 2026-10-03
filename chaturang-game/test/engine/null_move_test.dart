import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/move.dart';
import 'package:chaturang/engine/move_generator.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/searcher.dart';
import 'package:chaturang/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

/// Null-move pruning rests on the board being able to pass cleanly and put
/// itself back. A leak here corrupts the search silently — the position is
/// still legal-looking, just not the one the caller thinks it is.
void main() {
  test('a null move round-trips the position exactly', () {
    final b = Board();
    b.makeMove(const Move(from: Square(4, 6), to: Square(4, 5)));
    final key = b.zobrist;
    final stm = b.sideToMove;
    b.makeNullMove();
    expect(b.sideToMove, stm.opposite);
    expect(b.zobrist, isNot(key), reason: 'a passed position must hash apart');
    expect(b.nullMoveDepth, 1);
    b.undoNullMove();
    expect(b.zobrist, key);
    expect(b.sideToMove, stm);
    expect(b.nullMoveDepth, 0);
  });

  test('passing does not invent a repetition', () {
    // The passed position was never on the board. Counting it would let the
    // search claim draws that cannot happen in the game.
    final b = Board();
    final before = b.repetitionCount();
    b.makeNullMove();
    b.undoNullMove();
    expect(b.repetitionCount(), before);
    expect(b.isRepetition, isFalse);
  });

  test('real moves still undo correctly across a null move', () {
    final b = Board();
    final start = b.zobrist;
    b.makeMove(const Move(from: Square(4, 6), to: Square(4, 5)));
    b.makeNullMove();
    b.undoNullMove();
    b.undoMove();
    expect(b.zobrist, start);
    expect(b.plyCount, 0);
  });

  test('a bare-pawn endgame is left to the ordinary search', () {
    // Zugzwang country: the whole difficulty is being forced to move, so
    // "passing was fine" proves nothing. The guard should keep null-move out
    // of it, and the search should still find a sound move.
    final b = Board();
    b.setupCustom({
      const Square(4, 7): const Piece(PieceType.king, Side.white),
      const Square(4, 1): const Piece(PieceType.pawn, Side.white),
      const Square(4, 0): const Piece(PieceType.king, Side.black),
    }, sideToMove: Side.white);
    final r = Searcher().search(b, depth: 5);
    expect(r.move, isNotNull);
    expect(MoveGenerator.legalMoves(b), contains(r.move));
  });

  test('search results stay sane with every combination of flags', () {
    // Not an equivalence check — pruning legitimately changes what is found.
    // This is the weaker claim that each combination returns a legal move
    // and does not blow up.
    final b = Board();
    b.makeMove(const Move(from: Square(4, 6), to: Square(4, 4)));
    b.makeMove(const Move(from: Square(3, 1), to: Square(3, 3)));
    for (final nm in [false, true]) {
      for (final lmr in [false, true]) {
        final r = Searcher(
          options: SearchOptions(nullMove: nm, lateMoveReductions: lmr),
        ).search(b, depth: 5);
        expect(r.move, isNotNull, reason: 'nullMove=$nm lmr=$lmr');
        expect(
          MoveGenerator.legalMoves(b),
          contains(r.move),
          reason: 'nullMove=$nm lmr=$lmr returned an illegal move',
        );
      }
    }
  });
}
