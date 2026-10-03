import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/game_state.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/square.dart';
// flutter_test exports its own `Timeout` for test-duration limits; hide it so
// our engine's `Timeout` GameResult variant resolves unambiguously here.
import 'package:flutter_test/flutter_test.dart' hide Timeout;

Square sq(String s) => Square.algebraic(s);

void main() {
  group('GameResult.of', () {
    test('initial position is Ongoing, not check', () {
      expect(GameResult.of(Board()), equals(const Ongoing(inCheck: false)));
    });

    test('classic back-rank checkmate: black wins when white is mated', () {
      // White king at a8, white pawns at a7/b7/c7 wall it in.
      // Black rook at h8 delivers check along rank 8. No escape, no block,
      // no capture available — checkmate.
      final board = Board()
        ..setupCustom(
          {
            sq('a8'): const Piece(PieceType.king, Side.white),
            sq('a7'): const Piece(PieceType.pawn, Side.white),
            sq('b7'): const Piece(PieceType.pawn, Side.white),
            sq('c7'): const Piece(PieceType.pawn, Side.white),
            sq('h8'): const Piece(PieceType.rook, Side.black),
            sq('h1'): const Piece(PieceType.king, Side.black),
          },
          sideToMove: Side.white,
          // White's knight-leap is already spent — otherwise the king could
          // leap to a square the rook doesn't cover and survive.
          whiteKingKnightUsed: true,
        );
      expect(GameResult.of(board), equals(const Checkmate(winner: Side.black)));
    });

    test('stalemate: white to move, no legal moves, not in check', () {
      // White king at a8, white pawn at a7 (blocks king's a7 escape and has
      // its forward push to a6 blocked by the black pawn on a6).
      // Black king at c7 covers b7 and b8.
      // Black rook at b1 covers b-file (b7, b8 attacked again — redundant).
      // White king at a8 is not under attack itself.
      final board = Board()
        ..setupCustom(
          {
            sq('a8'): const Piece(PieceType.king, Side.white),
            sq('a7'): const Piece(PieceType.pawn, Side.white),
            sq('a6'): const Piece(PieceType.pawn, Side.black),
            sq('c7'): const Piece(PieceType.king, Side.black),
            sq('b1'): const Piece(PieceType.rook, Side.black),
          },
          sideToMove: Side.white,
          whiteKingKnightUsed: true,
        );
      expect(GameResult.of(board), equals(const Stalemate()));
    });

    test(
      'check WITH a legal escape is Ongoing(inCheck: true), not terminal',
      () {
        // White king at e5, black rook at e1 — check on e-file.
        // King can step off the file to safe squares. Game continues.
        final board = Board()
          ..setupCustom({
            sq('e5'): const Piece(PieceType.king, Side.white),
            sq('e1'): const Piece(PieceType.rook, Side.black),
            sq('a1'): const Piece(PieceType.king, Side.black),
          }, sideToMove: Side.white);
        final result = GameResult.of(board);
        expect(result, equals(const Ongoing(inCheck: true)));
        expect(result.isTerminal, isFalse);
      },
    );

    test("knight-leap rescue prevents mate (game stays Ongoing)", () {
      // The 3-rook position from move_generator_test that DOES allow the
      // king to escape via knight-leap to f7 or b7. Even though every
      // normal king move is attacked, the still-unspent knight-leap means
      // this is NOT mate.
      final board = Board()
        ..setupCustom({
          sq('d8'): const Piece(PieceType.king, Side.white),
          sq('d1'): const Piece(PieceType.rook, Side.black),
          sq('c1'): const Piece(PieceType.rook, Side.black),
          sq('e1'): const Piece(PieceType.rook, Side.black),
          sq('a1'): const Piece(PieceType.king, Side.black),
        }, sideToMove: Side.white);
      expect(GameResult.of(board), equals(const Ongoing(inCheck: true)));
    });

    test('isTerminal: false for Ongoing, true for Checkmate and Stalemate', () {
      expect(const Ongoing(inCheck: false).isTerminal, isFalse);
      expect(const Ongoing(inCheck: true).isTerminal, isFalse);
      expect(const Checkmate(winner: Side.white).isTerminal, isTrue);
      expect(const Stalemate().isTerminal, isTrue);
    });

    test('equality and toString are well-behaved', () {
      expect(
        const Ongoing(inCheck: false),
        equals(const Ongoing(inCheck: false)),
      );
      expect(
        const Ongoing(inCheck: true),
        isNot(equals(const Ongoing(inCheck: false))),
      );
      expect(
        const Checkmate(winner: Side.white),
        equals(const Checkmate(winner: Side.white)),
      );
      expect(
        const Checkmate(winner: Side.white),
        isNot(equals(const Checkmate(winner: Side.black))),
      );
      expect(const Stalemate(), equals(const Stalemate()));
      expect(const Ongoing(inCheck: true).toString(), 'Ongoing(in check)');
      expect(
        const Checkmate(winner: Side.black).toString(),
        'Checkmate(winner: Side.black)',
      );
    });

    test('Timeout is terminal, winner-tagged, and equality-aware', () {
      const t = Timeout(winner: Side.white);
      expect(t.isTerminal, isTrue);
      expect(t.winner, Side.white);
      expect(t, equals(const Timeout(winner: Side.white)));
      expect(t, isNot(equals(const Timeout(winner: Side.black))));
      // Timeout is distinct from Forfeit even with the same winner — stats
      // track them separately.
      expect(t == const Forfeit(winner: Side.white), isFalse);
      expect(t.toString(), 'Timeout(winner: Side.white)');
    });
  });
}
