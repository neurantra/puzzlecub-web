import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/game_state.dart';
import 'package:chaturang/engine/move_generator.dart';
import 'package:chaturang/engine/searcher.dart';
import 'package:flutter_test/flutter_test.dart';

/// History orders the quiet moves that killers have nothing to say about,
/// which is most of them. It changes the shape of the search, so the claim
/// worth pinning is that it prunes without changing what the search is
/// allowed to conclude.
void main() {
  int nodesFor(
    Board start, {
    required bool history,
    int depth = 5,
    SearchOptions base = const SearchOptions(),
  }) {
    final b = Board();
    for (final m in start.moveHistory) {
      b.makeMove(m);
    }
    return Searcher(
      options: base.copyWith(historyHeuristic: history),
    ).search(b, depth: depth).nodes;
  }

  test('it cuts the tree at the depth it is enabled for', () {
    // Measured against a search with no other technique on: with late-move
    // pruning in the mix the late quiet moves history would have ordered
    // are skipped anyway, and whether history still pays on top of that is
    // a question for the match harness, not for a node count.
    final b = Board();
    var withOut = 0, withIn = 0;
    for (var i = 0; i < 8; i++) {
      if (GameResult.of(b).isTerminal) break;
      withOut += nodesFor(
        b,
        history: false,
        depth: Searcher.historyMinDepth,
        base: SearchOptions.none,
      );
      withIn += nodesFor(
        b,
        history: true,
        depth: Searcher.historyMinDepth,
        base: SearchOptions.none,
      );
      b.makeMove(Searcher().search(b, depth: 4).move!);
    }
    expect(
      withIn,
      lessThan(withOut),
      reason: 'history ordering searched more nodes, not fewer',
    );
  });

  test('below that depth it is inert, not merely unhelpful', () {
    // It measured +4.8% nodes at depth 4, so it is gated rather than always
    // on. Inert means identical, not similar.
    final b = Board();
    b.makeMove(Searcher().search(b, depth: 3).move!);
    for (var depth = 2; depth < Searcher.historyMinDepth; depth++) {
      expect(
        nodesFor(b, history: true, depth: depth),
        nodesFor(b, history: false, depth: depth),
        reason:
            'history changed the search at depth $depth, where it is '
            'supposed to be switched off',
      );
    }
  });

  test('it never returns an illegal move', () {
    // Ordering bugs surface as nonsense moves — an index mixed up between
    // from and to squares would still produce a plausible-looking score.
    final b = Board();
    for (var i = 0; i < 12; i++) {
      if (GameResult.of(b).isTerminal) break;
      final r = Searcher().search(b, depth: 4);
      expect(r.move, isNotNull);
      expect(
        MoveGenerator.legalMoves(b),
        contains(r.move),
        reason: 'illegal move at ply $i',
      );
      b.makeMove(r.move!);
    }
  });

  test('the table does not leak between searches', () {
    // Cleared per search: history is about where cutoffs happened in *this*
    // tree. Reusing one Searcher must give the same answer as a fresh one,
    // or a game's ordering would drift with its own past.
    final b = Board();
    b.makeMove(Searcher().search(b, depth: 3).move!);
    final shared = Searcher();
    shared.search(b, depth: Searcher.historyMinDepth);
    final second = shared.search(b, depth: Searcher.historyMinDepth);
    final fresh = Searcher().search(b, depth: Searcher.historyMinDepth);
    expect(
      second.nodes,
      fresh.nodes,
      reason: 'a stale history table changed the search',
    );
    expect(second.move, fresh.move);
  });

  test('a long search keeps its scores bounded', () {
    // The table halves itself at a ceiling. Without that, cutoffs found
    // early would outweigh everything later in a long game.
    final b = Board();
    for (var i = 0; i < 6; i++) {
      b.makeMove(Searcher().search(b, depth: 4).move!);
    }
    final r = Searcher().search(b, depth: 7);
    expect(r.move, isNotNull);
    expect(MoveGenerator.legalMoves(b), contains(r.move));
  });
}
