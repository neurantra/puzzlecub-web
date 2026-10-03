import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/difficulty.dart';
import 'package:chaturang/engine/move_generator.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/searcher.dart';
import 'package:chaturang/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

/// A position where depth stops predicting time: clashing pawn walls give
/// quiescence an enormous capture tree to chase. Unbudgeted, this measured
/// 11s at Medium's depth 4 and 46s at Hard's depth 6 — past the caller's own
/// 30s kill-switch, which returns no move and leaves the game stuck.
Board tacticalMelee() {
  final b = Board();
  b.setupCustom({
    const Square(4, 7): const Piece(PieceType.king, Side.white),
    const Square(4, 0): const Piece(PieceType.king, Side.black),
    for (var f = 0; f < 8; f++)
      Square(f, 4): const Piece(PieceType.pawn, Side.white),
    for (var f = 0; f < 8; f++)
      Square(f, 3): const Piece(PieceType.pawn, Side.black),
    const Square(0, 6): const Piece(PieceType.rook, Side.white),
    const Square(7, 6): const Piece(PieceType.rook, Side.white),
    const Square(2, 5): const Piece(PieceType.knight, Side.white),
    const Square(5, 5): const Piece(PieceType.elephant, Side.white),
    const Square(3, 6): const Piece(PieceType.counsellor, Side.white),
    const Square(0, 1): const Piece(PieceType.rook, Side.black),
    const Square(7, 1): const Piece(PieceType.rook, Side.black),
    const Square(2, 2): const Piece(PieceType.knight, Side.black),
    const Square(5, 2): const Piece(PieceType.elephant, Side.black),
    const Square(3, 1): const Piece(PieceType.counsellor, Side.black),
  }, sideToMove: Side.white);
  return b;
}

void main() {
  test('the budget is honoured where depth alone runs away', () {
    for (final level in Difficulty.values) {
      final sw = Stopwatch()..start();
      final r = Searcher().search(
        tacticalMelee(),
        depth: level.searchDepth,
        budget: level.searchBudget,
      );
      sw.stop();

      // Generous slack: the abort is checked every 2048 nodes, and a single
      // quiescence frame can be slow. The point is bounded, not exact.
      expect(
        sw.elapsed,
        lessThan(level.searchBudget * 3),
        reason: '${level.name} overran its budget badly',
      );
      // Cut short or not, a legal move always comes back. Returning null
      // here is what leaves the game unable to continue.
      expect(r.move, isNotNull, reason: '${level.name} returned no move');
      expect(MoveGenerator.legalMoves(tacticalMelee()), contains(r.move));
    }
  });

  test('a budget that cannot bind changes nothing', () {
    // Normal play finishes full depth well inside the budget, so the result
    // must be identical to the unbudgeted search — the backstop is not
    // allowed to quietly weaken ordinary moves.
    final plain = Searcher().search(Board(), depth: 6);
    final budgeted = Searcher().search(
      Board(),
      depth: 6,
      budget: const Duration(minutes: 1),
    );
    expect(budgeted.move, plain.move);
    expect(budgeted.score, plain.score);
    expect(budgeted.nodes, plain.nodes);
  });

  test('an abort keeps the last completed depth, not a partial one', () {
    // A budget too small to finish even depth 1 still has to produce a legal
    // move rather than null.
    final searcher = Searcher();
    final r = searcher.search(
      tacticalMelee(),
      depth: 6,
      budget: const Duration(milliseconds: 1),
    );
    expect(r.move, isNotNull);
    expect(MoveGenerator.legalMoves(tacticalMelee()), contains(r.move));
    expect(searcher.lastSearchWasCutShort, isTrue);
  });

  test('a finished search does not report itself cut short', () {
    final searcher = Searcher();
    searcher.search(Board(), depth: 4, budget: const Duration(minutes: 1));
    expect(searcher.lastSearchWasCutShort, isFalse);
  });

  test('the result reports the depth it actually finished', () {
    expect(Searcher().search(Board(), depth: 4).depth, 4);
    expect(
      Searcher()
          .search(Board(), depth: 4, budget: const Duration(minutes: 1))
          .depth,
      4,
    );
  });

  test('with the ceiling out of reach, the clock decides the depth', () {
    // Hard's shape: a depth it cannot reach and a budget it must respect.
    // The search should stop itself before the budget rather than run into
    // it, by declining to start an iteration that will not fit.
    const budget = Duration(milliseconds: 300);
    final searcher = Searcher();
    final sw = Stopwatch()..start();
    final r = searcher.search(Board(), depth: 20, budget: budget);
    sw.stop();
    expect(r.move, isNotNull);
    expect(r.depth, greaterThanOrEqualTo(2));
    expect(r.depth, lessThan(20));
    expect(sw.elapsed, lessThan(budget * 3));
  });

  test('a mate found early stops the deepening', () {
    // Two rathas against a cornered raja: one already seals rank 1, the
    // other mates along rank 0. The white raja on (2,3) covers the knight
    // leap to (1,2) that would otherwise be the escape a chess back-rank
    // mate never has to think about. Once an iteration returns a mate score
    // there is nothing deeper to learn, and the search should not spend the
    // budget confirming it.
    final b = Board();
    b.setupCustom({
      const Square(0, 0): const Piece(PieceType.king, Side.black),
      const Square(2, 3): const Piece(PieceType.king, Side.white),
      const Square(7, 1): const Piece(PieceType.rook, Side.white),
      const Square(6, 7): const Piece(PieceType.rook, Side.white),
    }, sideToMove: Side.white);
    final r = Searcher().search(
      b,
      depth: 20,
      budget: const Duration(seconds: 5),
    );
    expect(r.move, isNotNull);
    expect(r.depth, lessThan(20));
  });
}
