import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/move.dart';
import 'package:chaturang/engine/move_generator.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

Square sq(String s) => Square.algebraic(s);
Piece wK = const Piece(PieceType.king, Side.white);
Piece bK = const Piece(PieceType.king, Side.black);

/// Build a board with kings parked far apart and additional pieces placed.
Board scenario(
  Map<Square, Piece> extras, {
  Side sideToMove = Side.white,
  Square whiteKing = const Square(0, 7), // a8
  Square blackKing = const Square(7, 0), // h1
  bool whiteKingKnightUsed = false,
  bool blackKingKnightUsed = false,
}) {
  return Board()..setupCustom(
    {whiteKing: wK, blackKing: bK, ...extras},
    sideToMove: sideToMove,
    whiteKingKnightUsed: whiteKingKnightUsed,
    blackKingKnightUsed: blackKingKnightUsed,
  );
}

Set<String> destsFrom(Board board, String from) => MoveGenerator.legalMovesFrom(
  board,
  sq(from),
).map((m) => m.to.algebraic).toSet();

void main() {
  group('Initial position', () {
    test('white has exactly 18 legal moves', () {
      final board = Board();
      expect(MoveGenerator.legalMoves(board).length, 18);
    });

    test('each pawn has exactly one forward move; no double-step', () {
      final board = Board();
      for (final f in 'abcdefgh'.split('')) {
        final pawnDests = destsFrom(board, '${f}7');
        expect(
          pawnDests,
          equals({'${f}6'}),
          reason: '$f pawn should only move to ${f}6',
        );
      }
    });

    test('initial position is not check for either side', () {
      final board = Board();
      expect(MoveGenerator.isInCheck(board, Side.white), isFalse);
      expect(MoveGenerator.isInCheck(board, Side.black), isFalse);
    });

    test("knight on b8 can reach a6 and c6 (jumps over c7 pawn)", () {
      final board = Board();
      expect(destsFrom(board, 'b8'), equals({'a6', 'c6'}));
    });

    test("king on d8 has no normal moves but 2 knight-leap moves", () {
      final board = Board();
      expect(destsFrom(board, 'd8'), equals({'c6', 'e6'}));
    });
  });

  group('Counsellor', () {
    test('moves 4 diagonals on open board, blocked by own, captures enemy', () {
      final board = scenario({
        sq('e5'): const Piece(PieceType.counsellor, Side.white),
        sq('d6'): const Piece(PieceType.pawn, Side.white), // own — blocks d6
        sq('f4'): const Piece(PieceType.pawn, Side.black), // enemy — capturable
      });
      expect(destsFrom(board, 'e5'), equals({'f6', 'd4', 'f4'}));
    });

    test('cannot move orthogonally', () {
      final board = scenario({
        sq('e5'): const Piece(PieceType.counsellor, Side.white),
      });
      final dests = destsFrom(board, 'e5');
      for (final orth in ['e4', 'e6', 'd5', 'f5']) {
        expect(dests.contains(orth), isFalse, reason: 'must not include $orth');
      }
    });
  });

  group('Elephant', () {
    test('jumps to 4 ±2,±2 squares, IGNORING intervening occupancy', () {
      // Surround e5 with pieces on every adjacent diagonal — elephant still
      // reaches each ±2,±2 destination because it jumps.
      final board = scenario({
        sq('e5'): const Piece(PieceType.elephant, Side.white),
        sq('d6'): const Piece(PieceType.pawn, Side.white), // intervening
        sq('f6'): const Piece(PieceType.pawn, Side.black), // intervening
        sq('d4'): const Piece(PieceType.pawn, Side.white), // intervening
        sq('f4'): const Piece(PieceType.pawn, Side.black), // intervening
      });
      expect(destsFrom(board, 'e5'), equals({'c7', 'g7', 'c3', 'g3'}));
    });

    test('captures at destination, blocked by own piece at destination', () {
      final board = scenario({
        sq('e5'): const Piece(PieceType.elephant, Side.white),
        sq('c7'): const Piece(
          PieceType.pawn,
          Side.white,
        ), // own at dest — blocks
        sq('g7'): const Piece(
          PieceType.pawn,
          Side.black,
        ), // enemy at dest — capturable
      });
      final dests = destsFrom(board, 'e5');
      expect(dests.contains('c7'), isFalse);
      expect(dests.contains('g7'), isTrue);
    });
  });

  group('Knight', () {
    test('8 L-shape moves on open board, jumps over intervening pieces', () {
      final board = scenario({
        sq('d5'): const Piece(PieceType.knight, Side.white),
        // surround it with pawns; knight should still reach all 8 L-targets
        for (final s in ['c5', 'd6', 'd4', 'e5'])
          sq(s): const Piece(PieceType.pawn, Side.white),
      });
      expect(
        destsFrom(board, 'd5'),
        equals({'b6', 'b4', 'c7', 'c3', 'e7', 'e3', 'f6', 'f4'}),
      );
    });
  });

  group('Rook', () {
    test('slides four directions, stops at first blocker, captures enemy', () {
      final board = scenario({
        sq('d4'): const Piece(PieceType.rook, Side.white),
        sq('d6'): const Piece(
          PieceType.pawn,
          Side.white,
        ), // own — stops before d6
        sq('g4'): const Piece(PieceType.pawn, Side.black), // enemy — capturable
      });
      final dests = destsFrom(board, 'd4');
      // Up (toward rank 7): d5 only (d6 own blocks).
      expect(dests.contains('d5'), isTrue);
      expect(dests.contains('d6'), isFalse);
      expect(dests.contains('d7'), isFalse);
      // Right (toward h): e4, f4, g4 (capture). Not h4.
      expect(dests.contains('e4'), isTrue);
      expect(dests.contains('f4'), isTrue);
      expect(dests.contains('g4'), isTrue);
      expect(dests.contains('h4'), isFalse);
      // Down (toward rank 0): d3, d2, d1 — but d1 is where the black king lives by default. Move scenario.
    });
  });

  group('Pawn movement', () {
    test('white pawn moves forward one (toward rank 0), no double-step', () {
      final board = scenario({
        sq('e6'): const Piece(PieceType.pawn, Side.white),
      });
      // Even though e6 happens to mirror a "starting"-feeling rank, there's no
      // double-step in this game — only e5 should be reachable.
      expect(destsFrom(board, 'e6'), equals({'e5'}));
    });

    test('black pawn moves toward rank 7', () {
      final board = scenario({
        sq('e3'): const Piece(PieceType.pawn, Side.black),
      }, sideToMove: Side.black);
      expect(destsFrom(board, 'e3'), equals({'e4'}));
    });

    test('pawn cannot push onto an occupied square', () {
      final board = scenario({
        sq('e6'): const Piece(PieceType.pawn, Side.white),
        sq('e5'): const Piece(PieceType.pawn, Side.black), // directly in front
      });
      expect(destsFrom(board, 'e6'), isEmpty);
    });

    test('pawn captures diagonally but never straight forward', () {
      final board = scenario({
        sq('e5'): const Piece(PieceType.pawn, Side.white),
        sq('e4'): const Piece(PieceType.pawn, Side.black), // blocks push
        sq('d4'): const Piece(PieceType.pawn, Side.black), // capturable
        sq('f4'): const Piece(PieceType.pawn, Side.black), // capturable
      });
      expect(destsFrom(board, 'e5'), equals({'d4', 'f4'}));
    });

    test('pawn cannot capture forward', () {
      final board = scenario({
        sq('e5'): const Piece(PieceType.pawn, Side.white),
        sq('e4'): const Piece(PieceType.pawn, Side.black),
      });
      final dests = destsFrom(board, 'e5');
      expect(dests.contains('e4'), isFalse);
    });
  });

  group('Pawn promotion', () {
    test('white pawn → a1 promotes to rook', () {
      final board = scenario({
        sq('a2'): const Piece(PieceType.pawn, Side.white),
      });
      final moves = MoveGenerator.legalMovesFrom(board, sq('a2'));
      expect(moves.length, 1);
      expect(moves.first.promotion, PieceType.rook);
    });

    test('white pawn promotions for b/c/d files', () {
      for (final (file, expected) in [
        ('b', PieceType.knight),
        ('c', PieceType.elephant),
        ('d', PieceType.counsellor),
      ]) {
        final board = scenario({
          sq('${file}2'): const Piece(PieceType.pawn, Side.white),
        });
        final moves = MoveGenerator.legalMovesFrom(board, sq('${file}2'));
        expect(moves.length, 1, reason: '$file file');
        expect(moves.first.promotion, expected, reason: '$file file');
      }
    });

    test('white pawn promotion on e1 is FORBIDDEN (no move generated)', () {
      // Move black king out of e1 first so the pawn could potentially move there.
      final board = scenario({
        sq('e2'): const Piece(PieceType.pawn, Side.white),
      }, blackKing: sq('a1'));
      // Push to e1 is forbidden because e1 is black's home-king file → no
      // promotion piece exists. No legal moves.
      expect(MoveGenerator.legalMovesFrom(board, sq('e2')), isEmpty);
    });

    test('black pawn promotion on d8 is FORBIDDEN', () {
      final board = scenario(
        {sq('d7'): const Piece(PieceType.pawn, Side.black)},
        sideToMove: Side.black,
        whiteKing: sq('a8'),
      );
      expect(MoveGenerator.legalMovesFrom(board, sq('d7')), isEmpty);
    });

    test('black pawn promotion on e8 → counsellor', () {
      final board = scenario(
        {sq('e7'): const Piece(PieceType.pawn, Side.black)},
        sideToMove: Side.black,
        whiteKing: sq('a8'),
      );
      final moves = MoveGenerator.legalMovesFrom(board, sq('e7'));
      expect(moves.length, 1);
      expect(moves.first.promotion, PieceType.counsellor);
    });
  });

  group('King normal moves', () {
    test('king on open square has 8 adjacent moves (plus knight-leap)', () {
      final board = scenario({}, whiteKing: sq('d5'));
      // 8 adjacent + 8 knight-leap = 16
      expect(destsFrom(board, 'd5').length, 16);
    });

    test('king cannot move onto own piece', () {
      final board = scenario({
        sq('d4'): const Piece(PieceType.pawn, Side.white),
      }, whiteKing: sq('d5'));
      expect(destsFrom(board, 'd5').contains('d4'), isFalse);
    });

    test('king cannot move into an attacked square', () {
      // Black rook on a4 attacks all of rank 3 (clear path). King at d5 cannot
      // step to d4 (attacked).
      final board = scenario({
        sq('a4'): const Piece(PieceType.rook, Side.black),
      }, whiteKing: sq('d5'));
      expect(destsFrom(board, 'd5').contains('d4'), isFalse);
      expect(destsFrom(board, 'd5').contains('c4'), isFalse);
      expect(destsFrom(board, 'd5').contains('e4'), isFalse);
    });
  });

  group("King's knight-leap (once per game)", () {
    test(
      'on open board, generated alongside 8 normal moves when flag unused',
      () {
        final board = scenario({}, whiteKing: sq('d5'));
        // 8 normal + 8 knight-leap
        expect(destsFrom(board, 'd5').length, 16);
      },
    );

    test('NOT generated once the flag has been spent', () {
      final board = scenario(
        {},
        whiteKing: sq('d5'),
        whiteKingKnightUsed: true,
      );
      // Just the 8 normal moves now.
      expect(destsFrom(board, 'd5').length, 8);
    });

    test(
      'flag is automatically set when a knight-geometry king move is made',
      () {
        final board = scenario({}, whiteKing: sq('d5'));
        expect(board.kingKnightMoveUsed(Side.white), isFalse);
        board.makeMove(
          Move(from: sq('d5'), to: sq('e3')),
        ); // 2-rank, 1-file leap
        expect(board.kingKnightMoveUsed(Side.white), isTrue);
        board.undoMove();
        expect(board.kingKnightMoveUsed(Side.white), isFalse);
      },
    );

    test('knight-leap CAN be used to escape check (Option B)', () {
      // White king at d8 is checked by black rook at d1 along the d-file.
      // Two additional black rooks on c-file and e-file ensure ALL normal
      // king escapes are also attacked. Only knight-leaps off the c/d/e
      // files can save the king.
      final board = scenario(
        {
          sq('d1'): const Piece(PieceType.rook, Side.black),
          sq('c1'): const Piece(PieceType.rook, Side.black),
          sq('e1'): const Piece(PieceType.rook, Side.black),
        },
        whiteKing: sq('d8'),
        blackKing: sq('a1'),
      );
      expect(MoveGenerator.isInCheck(board, Side.white), isTrue);
      final dests = destsFrom(board, 'd8');
      // Knight-leap targets from d8: (4,9)off, (4,5)=e6 attacked by e-rook,
      // (2,9)off, (2,5)=c6 attacked by c-rook, (5,8)off, (5,6)=f7 SAFE,
      // (1,8)off, (1,6)=b7 SAFE.
      expect(dests, equals({'f7', 'b7'}));
    });
  });

  group('Attack queries and check detection', () {
    test('rook attack respects clear-path (blocker stops attack)', () {
      final board = scenario({
        sq('e1'): const Piece(PieceType.rook, Side.black),
        sq('e3'): const Piece(PieceType.pawn, Side.white), // blocks rook
        sq('e5'): const Piece(PieceType.pawn, Side.white),
      }, whiteKing: sq('a8'));
      // e1 rook attacks e2 (empty path), e3 (the blocker itself), but not e4/e5/onwards.
      expect(
        MoveGenerator.isSquareAttacked(board, sq('e2'), Side.black),
        isTrue,
      );
      expect(
        MoveGenerator.isSquareAttacked(board, sq('e3'), Side.black),
        isTrue,
      );
      expect(
        MoveGenerator.isSquareAttacked(board, sq('e4'), Side.black),
        isFalse,
      );
      expect(
        MoveGenerator.isSquareAttacked(board, sq('e5'), Side.black),
        isFalse,
      );
    });

    test("pawn attacks diagonals only, not the forward-push square", () {
      // Black pawn at e3 attacks d4 and f4 (toward rank 7), NOT e4.
      final board = scenario({
        sq('e3'): const Piece(PieceType.pawn, Side.black),
      }, whiteKing: sq('a8'));
      expect(
        MoveGenerator.isSquareAttacked(board, sq('d4'), Side.black),
        isTrue,
      );
      expect(
        MoveGenerator.isSquareAttacked(board, sq('f4'), Side.black),
        isTrue,
      );
      expect(
        MoveGenerator.isSquareAttacked(board, sq('e4'), Side.black),
        isFalse,
      );
    });

    test("king's knight-leap geometry is NOT a passive attack", () {
      // Black king at e1; the squares 2-and-1 away (knight pattern) should not
      // be considered "attacked" by the king.
      final board = scenario({}, whiteKing: sq('a8'), blackKing: sq('e1'));
      expect(
        MoveGenerator.isSquareAttacked(board, sq('d3'), Side.black),
        isFalse,
      );
      expect(
        MoveGenerator.isSquareAttacked(board, sq('c2'), Side.black),
        isFalse,
      );
      // But adjacent squares ARE attacked.
      expect(
        MoveGenerator.isSquareAttacked(board, sq('d1'), Side.black),
        isTrue,
      );
      expect(
        MoveGenerator.isSquareAttacked(board, sq('e2'), Side.black),
        isTrue,
      );
    });

    test('elephant attacks all four ±2,±2 squares regardless of blockers', () {
      final board = scenario({
        sq('e5'): const Piece(PieceType.elephant, Side.black),
        sq('d6'): const Piece(PieceType.pawn, Side.white),
        sq('f4'): const Piece(PieceType.pawn, Side.white),
      }, whiteKing: sq('a8'));
      for (final target in ['c7', 'g7', 'c3', 'g3']) {
        expect(
          MoveGenerator.isSquareAttacked(board, sq(target), Side.black),
          isTrue,
          reason: 'elephant should attack $target',
        );
      }
    });
  });

  group('Legal-move filter (pin / check evasion)', () {
    test('pinned piece cannot abandon the pin line', () {
      // White king at d8, white rook at d4, black rook at d1.
      // The white rook is pinned along the d-file. It can move along d-file
      // (capture d1, or move to d5/d6/d7) but not off the file.
      final board = scenario(
        {
          sq('d4'): const Piece(PieceType.rook, Side.white),
          sq('d1'): const Piece(PieceType.rook, Side.black),
        },
        whiteKing: sq('d8'),
        blackKing: sq('a1'),
      );
      final dests = destsFrom(board, 'd4');
      // Legal: stay on the d-file
      expect(dests, containsAll({'d5', 'd6', 'd7', 'd3', 'd2', 'd1'}));
      // Illegal: any horizontal move (would unpin and expose king)
      for (final off in ['c4', 'b4', 'a4', 'e4', 'f4', 'g4', 'h4']) {
        expect(
          dests.contains(off),
          isFalse,
          reason: 'pinned rook must not move to $off',
        );
      }
    });

    test('when in check, only moves that resolve check are legal', () {
      // White king at e5, black rook at e1 giving check on e-file. White has
      // a knight on c3. From c3 the only knight moves that resolve the check
      // are blocks between rook and king on the e-file: c3→e2 and c3→e4
      // (both valid 2-and-1 jumps). All other knight moves leave the king
      // exposed and are illegal.
      final board = scenario(
        {
          sq('e1'): const Piece(PieceType.rook, Side.black),
          sq('c3'): const Piece(PieceType.knight, Side.white),
        },
        whiteKing: sq('e5'),
        blackKing: sq('a1'),
      );
      expect(MoveGenerator.isInCheck(board, Side.white), isTrue);
      expect(destsFrom(board, 'c3'), equals({'e2', 'e4'}));
    });

    test('king moving into a check is rejected', () {
      // King at d5, black rook at e1. King moving to e5 would expose itself.
      final board = scenario(
        {sq('e1'): const Piece(PieceType.rook, Side.black)},
        whiteKing: sq('d5'),
        blackKing: sq('a1'),
      );
      expect(destsFrom(board, 'd5').contains('e5'), isFalse);
      expect(destsFrom(board, 'd5').contains('d6'), isTrue); // safe square
    });
  });
}
