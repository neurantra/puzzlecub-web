import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/move.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Square', () {
    test('algebraic roundtrip', () {
      for (var f = 0; f < 8; f++) {
        for (var r = 0; r < 8; r++) {
          final sq = Square(f, r);
          expect(Square.algebraic(sq.algebraic), sq);
        }
      }
    });

    test('known squares map to expected files and ranks', () {
      expect(Square.algebraic('a1'), const Square(0, 0));
      expect(Square.algebraic('h8'), const Square(7, 7));
      expect(Square.algebraic('e1').toString(), 'e1');
      expect(Square.algebraic('d8').toString(), 'd8');
    });
  });

  group('Board initial position', () {
    late Board board;
    setUp(() => board = Board());

    test('white to move, ply 0, no knight-leap used', () {
      expect(board.sideToMove, Side.white);
      expect(board.plyCount, 0);
      expect(board.kingKnightMoveUsed(Side.white), isFalse);
      expect(board.kingKnightMoveUsed(Side.black), isFalse);
    });

    test('Black back rank: a1 R, b1 N, c1 E, d1 C, e1 K, f1 E, g1 N, h1 R', () {
      const expected = [
        ('a1', PieceType.rook),
        ('b1', PieceType.knight),
        ('c1', PieceType.elephant),
        ('d1', PieceType.counsellor),
        ('e1', PieceType.king),
        ('f1', PieceType.elephant),
        ('g1', PieceType.knight),
        ('h1', PieceType.rook),
      ];
      for (final (sq, type) in expected) {
        final p = board.pieceAt(Square.algebraic(sq));
        expect(p, isNotNull, reason: '$sq should be occupied');
        expect(p!.type, type, reason: '$sq piece type');
        expect(p.side, Side.black, reason: '$sq side');
      }
    });

    test('White back rank: a8 R, b8 N, c8 E, d8 K, e8 C, f8 E, g8 N, h8 R', () {
      const expected = [
        ('a8', PieceType.rook),
        ('b8', PieceType.knight),
        ('c8', PieceType.elephant),
        ('d8', PieceType.king),
        ('e8', PieceType.counsellor),
        ('f8', PieceType.elephant),
        ('g8', PieceType.knight),
        ('h8', PieceType.rook),
      ];
      for (final (sq, type) in expected) {
        final p = board.pieceAt(Square.algebraic(sq));
        expect(p, isNotNull, reason: '$sq should be occupied');
        expect(p!.type, type, reason: '$sq piece type');
        expect(p.side, Side.white, reason: '$sq side');
      }
    });

    test('pawns on rank 2 (black) and rank 7 (white)', () {
      for (var f = 0; f < 8; f++) {
        final blackPawn = board.pieceAt(Square(f, 1));
        expect(blackPawn?.type, PieceType.pawn);
        expect(blackPawn?.side, Side.black);
        final whitePawn = board.pieceAt(Square(f, 6));
        expect(whitePawn?.type, PieceType.pawn);
        expect(whitePawn?.side, Side.white);
      }
    });

    test('middle four ranks are empty', () {
      for (var f = 0; f < 8; f++) {
        for (var r = 2; r <= 5; r++) {
          expect(
            board.pieceAt(Square(f, r)),
            isNull,
            reason: '${Square(f, r)} should be empty',
          );
        }
      }
    });
  });

  group('Board.makeMove / undoMove', () {
    test('side to move alternates', () {
      final board = Board();
      expect(board.sideToMove, Side.white);
      board.makeMove(
        Move(from: Square.algebraic('e7'), to: Square.algebraic('e6')),
      );
      expect(board.sideToMove, Side.black);
      expect(board.plyCount, 1);
      board.undoMove();
      expect(board.sideToMove, Side.white);
      expect(board.plyCount, 0);
    });

    test('quiet move and undo restores piece position', () {
      final board = Board();
      final from = Square.algebraic('e7');
      final to = Square.algebraic('e6');
      final piece = board.pieceAt(from);

      board.makeMove(Move(from: from, to: to));
      expect(board.pieceAt(from), isNull);
      expect(board.pieceAt(to), piece);

      board.undoMove();
      expect(board.pieceAt(from), piece);
      expect(board.pieceAt(to), isNull);
    });

    test('capture is restored on undo', () {
      final board = Board();
      board.setupCustom({
        Square.algebraic('e4'): const Piece(PieceType.rook, Side.white),
        Square.algebraic('e6'): const Piece(PieceType.pawn, Side.black),
        Square.algebraic('d8'): const Piece(PieceType.king, Side.white),
        Square.algebraic('e1'): const Piece(PieceType.king, Side.black),
      });
      final rook = board.pieceAt(Square.algebraic('e4'));
      final captured = board.pieceAt(Square.algebraic('e6'));
      expect(captured?.type, PieceType.pawn);

      board.makeMove(
        Move(from: Square.algebraic('e4'), to: Square.algebraic('e6')),
      );
      expect(board.pieceAt(Square.algebraic('e4')), isNull);
      expect(board.pieceAt(Square.algebraic('e6')), rook);

      board.undoMove();
      expect(board.pieceAt(Square.algebraic('e4')), rook);
      expect(board.pieceAt(Square.algebraic('e6')), captured);
    });

    test('promotion replaces pawn on make, restores pawn on undo', () {
      final board = Board();
      board.setupCustom({
        Square.algebraic('a2'): const Piece(PieceType.pawn, Side.white),
        Square.algebraic('d8'): const Piece(PieceType.king, Side.white),
        Square.algebraic('e1'): const Piece(PieceType.king, Side.black),
      });

      board.makeMove(
        Move(
          from: Square.algebraic('a2'),
          to: Square.algebraic('a1'),
          promotion: PieceType.rook,
        ),
      );
      final promoted = board.pieceAt(Square.algebraic('a1'));
      expect(promoted?.type, PieceType.rook);
      expect(promoted?.side, Side.white);

      board.undoMove();
      final restored = board.pieceAt(Square.algebraic('a2'));
      expect(restored?.type, PieceType.pawn);
      expect(restored?.side, Side.white);
      expect(board.pieceAt(Square.algebraic('a1')), isNull);
    });

    test("king's normal step does NOT consume the knight-move flag", () {
      final board = Board();
      board.setupCustom({
        Square.algebraic('d8'): const Piece(PieceType.king, Side.white),
        Square.algebraic('e1'): const Piece(PieceType.king, Side.black),
      });

      board.makeMove(
        Move(from: Square.algebraic('d8'), to: Square.algebraic('d7')),
      );
      expect(board.kingKnightMoveUsed(Side.white), isFalse);
    });

    test("king's knight-leap sets the per-side flag; undo restores it", () {
      final board = Board();
      board.setupCustom({
        Square.algebraic('d8'): const Piece(PieceType.king, Side.white),
        Square.algebraic('e1'): const Piece(PieceType.king, Side.black),
      });

      board.makeMove(
        Move(from: Square.algebraic('d8'), to: Square.algebraic('e6')),
      );
      expect(board.kingKnightMoveUsed(Side.white), isTrue);
      expect(board.kingKnightMoveUsed(Side.black), isFalse);

      board.undoMove();
      expect(board.kingKnightMoveUsed(Side.white), isFalse);
    });

    test('per-side knight-leap flag is independent', () {
      final board = Board();
      board.setupCustom({
        Square.algebraic('d8'): const Piece(PieceType.king, Side.white),
        Square.algebraic('e1'): const Piece(PieceType.king, Side.black),
      });

      board.makeMove(
        Move(from: Square.algebraic('d8'), to: Square.algebraic('e6')),
      );
      board.makeMove(
        Move(from: Square.algebraic('e1'), to: Square.algebraic('d3')),
      );
      expect(board.kingKnightMoveUsed(Side.white), isTrue);
      expect(board.kingKnightMoveUsed(Side.black), isTrue);

      board.undoMove();
      expect(board.kingKnightMoveUsed(Side.white), isTrue);
      expect(board.kingKnightMoveUsed(Side.black), isFalse);

      board.undoMove();
      expect(board.kingKnightMoveUsed(Side.white), isFalse);
      expect(board.kingKnightMoveUsed(Side.black), isFalse);
    });

    test('undo with empty history throws', () {
      final board = Board();
      expect(board.undoMove, throwsStateError);
    });
  });
}
