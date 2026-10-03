import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/game_state.dart';
import 'package:chaturang/engine/move.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/searcher.dart';
import 'package:chaturang/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

Board position(
  Map<Square, Piece> pieces, {
  Side stm = Side.white,
  bool blackLeapSpent = false,
}) {
  final b = Board();
  b.setupCustom(pieces, sideToMove: stm, blackKingKnightUsed: blackLeapSpent);
  return b;
}

const _wk = Piece(PieceType.king, Side.white);
const _bk = Piece(PieceType.king, Side.black);

void main() {
  group('insufficient material', () {
    test('bare kings is a draw immediately', () {
      final b = position({const Square(4, 7): _wk, const Square(4, 0): _bk});
      expect(GameResult.of(b), const InsufficientMaterial());
      expect(GameResult.of(b).isTerminal, isTrue);
    });

    test('a lone minor cannot mate', () {
      for (final t in [
        PieceType.knight,
        PieceType.elephant,
        PieceType.counsellor,
      ]) {
        final b = position({
          const Square(4, 7): _wk,
          const Square(4, 0): _bk,
          const Square(2, 5): Piece(t, Side.white),
        });
        expect(
          GameResult.of(b),
          const InsufficientMaterial(),
          reason: '$t alone should not be enough',
        );
      }
    });

    test('a rook or a pawn keeps the game alive', () {
      for (final t in [PieceType.rook, PieceType.pawn]) {
        final b = position({
          const Square(4, 7): _wk,
          const Square(4, 0): _bk,
          const Square(2, 5): Piece(t, Side.white),
        });
        expect(GameResult.of(b).isTerminal, isFalse, reason: '$t can win');
      }
    });

    test('a minor each is still playable', () {
      // Two minors can construct mates in some positions, so they are left
      // alone rather than claimed as dead.
      final b = position({
        const Square(4, 7): _wk,
        const Square(4, 0): _bk,
        const Square(2, 5): const Piece(PieceType.knight, Side.white),
        const Square(2, 2): const Piece(PieceType.knight, Side.black),
      });
      expect(GameResult.of(b).isTerminal, isFalse);
    });
  });

  group('repetition', () {
    test('the third occurrence ends the game', () {
      final b = Board();
      const cycle = [
        Move(from: Square(1, 7), to: Square(2, 5)),
        Move(from: Square(1, 0), to: Square(2, 2)),
        Move(from: Square(2, 5), to: Square(1, 7)),
        Move(from: Square(2, 2), to: Square(1, 0)),
      ];
      for (final m in cycle) {
        b.makeMove(m);
      }
      expect(GameResult.of(b).isTerminal, isFalse, reason: 'twofold plays on');
      for (final m in cycle) {
        b.makeMove(m);
      }
      expect(GameResult.of(b), const RepetitionDraw());
    });

    test('the new checks did not displace mate', () {
      // The repetition and material tests run after mate/stalemate, so a
      // decisive position still has to come back decisive. Ladder mate:
      // black king boxed on a8, one rook checking along the back rank and
      // the other covering the rank below.
      // The leap has to be spent: a Chaturang king may make one knight
      // move per game, and with it available this "mate" is not one — the
      // king simply jumps out of the box.
      final b = position(
        {
          const Square(0, 0): _bk,
          const Square(7, 0): const Piece(PieceType.rook, Side.white),
          const Square(7, 1): const Piece(PieceType.rook, Side.white),
          const Square(4, 7): _wk,
        },
        stm: Side.black,
        blackLeapSpent: true,
      );
      expect(GameResult.of(b), const Checkmate(winner: Side.white));
    });
  });

  test('the search converts rather than shuffling', () {
    // Two rooks against a bare king: with repetitions scored as draws the
    // engine has to make progress instead of circling.
    final b = position({
      const Square(4, 7): _wk,
      const Square(0, 7): const Piece(PieceType.rook, Side.white),
      const Square(1, 7): const Piece(PieceType.rook, Side.white),
      const Square(4, 0): _bk,
    });
    var plies = 0;
    for (; plies < 40; plies++) {
      if (GameResult.of(b).isTerminal) break;
      final r = Searcher().search(
        b,
        depth: b.sideToMove == Side.white ? 6 : 4,
        budget: const Duration(seconds: 5),
      );
      if (r.move == null) break;
      b.makeMove(r.move!);
    }
    expect(
      GameResult.of(b),
      isA<Checkmate>(),
      reason: 'AI failed to convert two rooks vs a bare king',
    );
  });
}
