import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/move.dart';
import 'package:chaturang/engine/move_generator.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/searcher.dart';
import 'package:chaturang/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

/// SEE drives which captures quiescence bothers to search. A wrong sign
/// silently discards winning captures, so it is asserted directly.
///
/// Values: padati 92, mantri 142, gaja 192, ashva 292, ratha 492.
void main() {
  const wk = Piece(PieceType.king, Side.white);
  const bk = Piece(PieceType.king, Side.black);
  const wPawn = Piece(PieceType.pawn, Side.white);
  const bPawn = Piece(PieceType.pawn, Side.black);
  const wRook = Piece(PieceType.rook, Side.white);
  const bRook = Piece(PieceType.rook, Side.black);

  Board pos(Map<Square, Piece> p, {Side stm = Side.white}) {
    final b = Board();
    b.setupCustom(p, sideToMove: stm);
    return b;
  }

  int see(Board b, Move m) => Searcher().debugSee(b, m);

  test('an undefended piece is worth its full value', () {
    final b = pos({
      const Square(0, 7): wk,
      const Square(0, 0): bk,
      const Square(3, 4): wPawn,
      const Square(4, 3): bRook,
    });
    expect(see(b, const Move(from: Square(3, 4), to: Square(4, 3))), 492);
  });

  test('a defended piece costs the attacker back', () {
    // Padati takes ratha, padati recaptures: +492 - 92 = +400.
    final b = pos({
      const Square(0, 7): wk,
      const Square(0, 0): bk,
      const Square(3, 4): wPawn,
      const Square(4, 3): bRook,
      const Square(5, 2): bPawn, // defends e4 from f6
    });
    expect(see(b, const Move(from: Square(3, 4), to: Square(4, 3))), 400);
  });

  test('a losing capture is negative', () {
    // Ratha takes a padati defended by a padati: 92 - 492 = -400.
    final b = pos({
      const Square(0, 7): wk,
      const Square(0, 0): bk,
      const Square(4, 6): wRook,
      const Square(4, 3): bPawn,
      const Square(5, 2): bPawn, // defends e4
    });
    final m = const Move(from: Square(4, 6), to: Square(4, 3));
    expect(MoveGenerator.legalMoves(b), contains(m));
    expect(see(b, m), -400);
  });

  test('an x-ray behind a ratha joins the exchange', () {
    // Two white rathas stacked on the e-file; one black ratha defends the
    // padati. Taking is only sound because the second ratha is behind the
    // first — it recaptures the defender once the first is traded off.
    //
    //   ratha takes padati  +92
    //   ratha recaptures    -492  (running total -400)
    //   ratha #2 recaptures +492  (running total  +92)
    Map<Square, Piece> base(bool stacked) => {
      const Square(0, 7): wk,
      const Square(0, 0): bk,
      const Square(4, 6): wRook,
      if (stacked) const Square(4, 7): wRook,
      const Square(4, 3): bPawn,
      const Square(4, 1): bRook,
    };
    const m = Move(from: Square(4, 6), to: Square(4, 3));
    expect(
      see(pos(base(true)), m),
      92,
      reason: 'the ratha behind was not counted',
    );
    expect(
      see(pos(base(false)), m),
      -400,
      reason: 'without the second ratha the capture simply loses',
    );
  });

  test('the raja is not treated as the cheapest attacker', () {
    // Regression: the raja is worth 0 to the evaluator. A SEE reusing that
    // value picks it as the least valuable attacker and prices exchanges as
    // if the king could safely go in first.
    //
    // Black padati on e4, defended by a padati and by the black raja. White
    // takes with a padati. If the raja were "cheapest", the recapture would
    // be priced at 0 instead of a padati's 92.
    final b = pos({
      const Square(0, 7): wk,
      const Square(4, 2): bk, // adjacent to e4
      const Square(3, 4): wPawn,
      const Square(4, 3): bPawn,
    });
    // Padati takes padati; the raja recaptures. Winning a padati and losing
    // one is a wash, not a free padati.
    expect(see(b, const Move(from: Square(3, 4), to: Square(4, 3))), 0);
  });

  test('a quiet move has no exchange', () {
    final b = pos({
      const Square(0, 7): wk,
      const Square(0, 0): bk,
      const Square(3, 4): wPawn,
    });
    expect(see(b, const Move(from: Square(3, 4), to: Square(3, 3))), 0);
  });
}
