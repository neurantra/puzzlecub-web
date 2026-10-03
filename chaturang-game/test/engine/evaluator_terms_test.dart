import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/eval_params.dart';
import 'package:chaturang/engine/evaluator.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

Square sq(String s) => Square.algebraic(s);

/// The Chaturang-specific evaluation terms. Each test pins the direction
/// and the gating, not the magnitude — magnitudes belong to the tuner.
void main() {
  // Kings apart, leaps spent, so the leap and king-safety terms are equal
  // on both sides and drop out of every comparison below.
  Board position(Map<Square, Piece> pieces) => Board()
    ..setupCustom(
      {
        sq('a8'): const Piece(PieceType.king, Side.white),
        sq('h1'): const Piece(PieceType.king, Side.black),
        ...pieces,
      },
      whiteKingKnightUsed: true,
      blackKingKnightUsed: true,
    );

  group('passed padati', () {
    // White moves toward rank 0 (algebraic rank 1). A white padati on the
    // h-file at h3 is two steps from promoting to a ratha.
    test('a passer is worth more than the same padati with an enemy ahead', () {
      final passed = position({
        sq('h3'): const Piece(PieceType.pawn, Side.white),
        sq('a2'): const Piece(PieceType.pawn, Side.black),
      });
      final blocked = position({
        sq('h3'): const Piece(PieceType.pawn, Side.white),
        sq('g2'): const Piece(PieceType.pawn, Side.black),
      });
      expect(
        Evaluator.evaluate(passed),
        greaterThan(Evaluator.evaluate(blocked)),
      );
    });

    test('a ratha-file passer outranks a mantri-file one', () {
      // Same rank, same distance, different destiny: h-file becomes a
      // ratha, d-file a mantri (black's back rank has the mantri on d).
      final rookFile = position({
        sq('h3'): const Piece(PieceType.pawn, Side.white),
        sq('a2'): const Piece(PieceType.pawn, Side.black),
      });
      final counsellorFile = position({
        sq('d3'): const Piece(PieceType.pawn, Side.white),
        sq('a2'): const Piece(PieceType.pawn, Side.black),
      });
      final noTerm = EvalParams.handTuned().withoutTerm('passedPawn');
      final pstOnly =
          Evaluator.evaluate(rookFile, noTerm) -
          Evaluator.evaluate(counsellorFile, noTerm);
      final withTerm =
          Evaluator.evaluate(rookFile) - Evaluator.evaluate(counsellorFile);
      expect(withTerm, greaterThan(pstOnly));
    });

    test('closer to promotion is worth more', () {
      final far = position({
        sq('h5'): const Piece(PieceType.pawn, Side.white),
        sq('a2'): const Piece(PieceType.pawn, Side.black),
      });
      final near = position({
        sq('h2'): const Piece(PieceType.pawn, Side.white),
        sq('a2'): const Piece(PieceType.pawn, Side.black),
      });
      final noTerm = EvalParams.handTuned().withoutTerm('passedPawn');
      final pstOnly =
          Evaluator.evaluate(near, noTerm) - Evaluator.evaluate(far, noTerm);
      final withTerm = Evaluator.evaluate(near) - Evaluator.evaluate(far);
      expect(withTerm, greaterThan(pstOnly));
    });

    test('a black passer counts the same way', () {
      // Black moves toward rank 7 (algebraic 8). a6 is two steps from a8,
      // where white's back rank has the ratha.
      final passed = position({
        sq('a6'): const Piece(PieceType.pawn, Side.black),
        sq('h7'): const Piece(PieceType.pawn, Side.white),
      });
      final blocked = position({
        sq('a6'): const Piece(PieceType.pawn, Side.black),
        sq('b7'): const Piece(PieceType.pawn, Side.white),
      });
      expect(Evaluator.evaluate(passed), lessThan(Evaluator.evaluate(blocked)));
    });
  });

  group('ratha files', () {
    test('an open file beats a semi-open one beats a closed one', () {
      Board withPawns(Map<Square, Piece> pawns) => position({
        sq('e5'): const Piece(PieceType.rook, Side.white),
        sq('a2'): const Piece(PieceType.pawn, Side.white),
        sq('h7'): const Piece(PieceType.pawn, Side.black),
        ...pawns,
      });
      final open = withPawns({});
      final semiOpen = withPawns({
        sq('e2'): const Piece(PieceType.pawn, Side.black),
      });
      final closed = withPawns({
        sq('e7'): const Piece(PieceType.pawn, Side.white),
      });
      final p = EvalParams.handTuned();
      final noTerm = p.withoutTerm('rookFiles');
      int gain(Board b) =>
          Evaluator.evaluate(b) - Evaluator.evaluate(b, noTerm);
      expect(gain(open), p.rookOpenFileBonus);
      expect(gain(semiOpen), p.rookSemiOpenFileBonus);
      expect(gain(closed), 0);
    });
  });

  group('convertibility', () {
    test('a lone minor against a bare king is worth nothing', () {
      final b = position({sq('d4'): const Piece(PieceType.knight, Side.white)});
      expect(Evaluator.evaluate(b), 0);
      // The rule is exactly the game's own.
      expect(
        Evaluator.evaluate(
          b,
          EvalParams.handTuned().withoutTerm('insufficientMaterial'),
        ),
        isNot(0),
      );
    });

    test('an edge held in minors alone is scaled down, not erased', () {
      final minorsOnly = position({
        sq('d4'): const Piece(PieceType.knight, Side.white),
        sq('e4'): const Piece(PieceType.elephant, Side.white),
        sq('a2'): const Piece(PieceType.pawn, Side.black),
      });
      final full = Evaluator.evaluate(
        minorsOnly,
        EvalParams.handTuned().withoutTerm('minorsOnly'),
      );
      final scaled = Evaluator.evaluate(minorsOnly);
      expect(full, greaterThan(0));
      expect(scaled, greaterThan(0));
      expect(scaled, lessThan(full));
    });

    test('a padati makes the edge convertible again', () {
      final b = position({
        sq('d4'): const Piece(PieceType.knight, Side.white),
        sq('h5'): const Piece(PieceType.pawn, Side.white),
        sq('a2'): const Piece(PieceType.pawn, Side.black),
      });
      expect(
        Evaluator.evaluate(b),
        Evaluator.evaluate(b, EvalParams.handTuned().withoutTerm('minorsOnly')),
      );
    });
  });
}
