import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/move.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/square.dart';
import 'package:chaturang/engine/zobrist.dart';
import 'package:flutter_test/flutter_test.dart';

Square sq(String s) => Square.algebraic(s);

void main() {
  group('Zobrist hashing', () {
    test('two freshly-set-up initial boards hash identically', () {
      final a = Board();
      final b = Board();
      expect(a.zobrist, b.zobrist);
      expect(a.zobrist, isNot(0)); // not the zero-init default
    });

    test('side-to-move difference produces different hashes', () {
      final w = Board()
        ..setupCustom({
          sq('d8'): const Piece(PieceType.king, Side.white),
          sq('e1'): const Piece(PieceType.king, Side.black),
        }, sideToMove: Side.white);
      final b = Board()
        ..setupCustom({
          sq('d8'): const Piece(PieceType.king, Side.white),
          sq('e1'): const Piece(PieceType.king, Side.black),
        }, sideToMove: Side.black);
      expect(w.zobrist, isNot(b.zobrist));
    });

    test('king-leap-used flag changes the hash', () {
      final fresh = Board()
        ..setupCustom({
          sq('d8'): const Piece(PieceType.king, Side.white),
          sq('e1'): const Piece(PieceType.king, Side.black),
        });
      final spent = Board()
        ..setupCustom({
          sq('d8'): const Piece(PieceType.king, Side.white),
          sq('e1'): const Piece(PieceType.king, Side.black),
        }, whiteKingKnightUsed: true);
      expect(fresh.zobrist, isNot(spent.zobrist));
    });

    test('make-then-undo restores the original hash', () {
      final board = Board();
      final original = board.zobrist;
      board.makeMove(
        const Move(from: Square(1, 6), to: Square(2, 4)),
      ); // Nb1-c3-ish
      expect(board.zobrist, isNot(original));
      board.undoMove();
      expect(board.zobrist, original);
    });

    test(
      'same position via different move orders has same hash (transposition)',
      () {
        // Two sequences that arrive at the same position by white & black
        // each moving a knight a different way around:
        //
        // Path 1: white Nb-c, black Nb-c, white Ng-f, black Ng-f
        // Path 2: white Ng-f, black Ng-f, white Nb-c, black Nb-c
        final a = Board();
        a.makeMove(Move(from: sq('b8'), to: sq('c6')));
        a.makeMove(Move(from: sq('b1'), to: sq('c3')));
        a.makeMove(Move(from: sq('g8'), to: sq('f6')));
        a.makeMove(Move(from: sq('g1'), to: sq('f3')));

        final b = Board();
        b.makeMove(Move(from: sq('g8'), to: sq('f6')));
        b.makeMove(Move(from: sq('g1'), to: sq('f3')));
        b.makeMove(Move(from: sq('b8'), to: sq('c6')));
        b.makeMove(Move(from: sq('b1'), to: sq('c3')));

        expect(a.zobrist, b.zobrist);
      },
    );

    test('capture + undo restores hash', () {
      final board = Board()
        ..setupCustom({
          sq('d8'): const Piece(PieceType.king, Side.white),
          sq('e5'): const Piece(PieceType.rook, Side.white),
          sq('e6'): const Piece(PieceType.pawn, Side.black),
          sq('a1'): const Piece(PieceType.king, Side.black),
        }, sideToMove: Side.white);
      final original = board.zobrist;
      board.makeMove(Move(from: sq('e5'), to: sq('e6'))); // Rxe6
      expect(board.zobrist, isNot(original));
      board.undoMove();
      expect(board.zobrist, original);
    });

    test('Zobrist module emits non-trivial 64-bit values', () {
      // Sanity check: two different (piece, side, square) combos should
      // produce two different hashes — protects against silently broken
      // initialization.
      final h1 = Zobrist.piece(PieceType.king, Side.white, 3, 7);
      final h2 = Zobrist.piece(PieceType.king, Side.white, 3, 6);
      final h3 = Zobrist.piece(PieceType.king, Side.black, 3, 7);
      expect(h1, isNot(h2));
      expect(h1, isNot(h3));
      expect(h1, isNot(0));
    });
  });
}
