import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'board.dart';
import 'eval_params.dart';
import 'evaluator.dart';
import 'move.dart';
import 'move_generator.dart';
import 'nnue.dart';
import 'opening_book.dart';
import 'pieces.dart';
import 'square.dart';
import 'tablebase.dart';
import 'transposition_table.dart';

/// Which search techniques are enabled.
///
/// Exists so `tool/match.dart` can play a build with a feature against the
/// same build without it. Every flag here was added with a measured result;
/// a flag whose default is false is one that did not pay.
class SearchOptions {
  const SearchOptions({
    this.seePruning = true,
    this.deltaPruning = true,
    this.reuseTable = false,
    this.nullMove = true,
    this.nullMoveAtPv = true,
    this.lateMoveReductions = true,
    this.historyHeuristic = true,
    this.pvs = true,
    this.checkExtension = false,
    this.historyMalus = true,
    this.seeOrdering = true,
    this.counterMove = false,
    this.reverseFutility = true,
    this.futilityPruning = true,
    this.lateMovePruning = true,
  });

  /// At a shallow non-PV node, if the static evaluation beats beta by a
  /// margin that grows with depth, trust it and cut without searching. The
  /// mirror image of null move: that one asks "am I fine even after
  /// passing?", this one "am I so far ahead that no reply matters?".
  ///
  /// Measured at 300ms/move over 400 games: +40 Elo [+15, +66], with the
  /// average completed depth up from 7.39 to 7.67.
  final bool reverseFutility;

  /// At a frontier node, skip quiet moves when the static evaluation plus a
  /// margin still cannot reach alpha: a quiet move gains at most positional
  /// value, and the margin covers that.
  ///
  /// Measured at 300ms/move over 400 games: +9 Elo [-17, +34]. Kept on as
  /// positive but not proven; it is cheap, and standard.
  final bool futilityPruning;

  /// At shallow non-PV nodes, stop searching quiet moves past a count that
  /// grows with depth. Ordering has put the promising ones first; the tail
  /// at depth 1 or 2 is almost never where the score comes from.
  ///
  /// Measured at 300ms/move over 400 games: +37 Elo [+12, +63], depth
  /// 7.19 → 7.77. At a fixed depth 6 it halves the node count.
  final bool lateMovePruning;

  /// Order captures that static exchange evaluation says lose material
  /// *below* the quiet moves, instead of above the killers with every other
  /// capture. MVV-LVA alone puts a ratha-takes-defended-padati ahead of the
  /// quiet refutation that would have cut the node at once. Only captures
  /// whose attacker is dearer than the victim are asked — the rest cannot
  /// lose material, and SEE is not free.
  ///
  /// Measured at 300ms/move over 400 games: +56 Elo [+31, +82] — the
  /// largest single gain of the 2026-09 pass, and with the depth reached
  /// unchanged (7.60 → 7.62): it does not buy plies, it stops each ply
  /// being spent on the wrong moves first.
  final bool seeOrdering;

  /// Remember, per opponent move, the quiet reply that last refuted it, and
  /// try that reply right after the killers. Killers are indexed by ply and
  /// history by the move alone; this is the one keyed on what the opponent
  /// just did, which is often exactly what decides the refutation.
  ///
  /// Off: measured at 300ms/move over 400 games at -14 Elo [-40, +12], with
  /// no change in depth reached. Not proven harmful, but it did not pay,
  /// and with killers and history already ordering the quiets it seems to
  /// have nothing left to add.
  final bool counterMove;

  /// Principal variation search. Only the first move at a node is searched
  /// with the full window; every later one gets a zero-width window that
  /// can only prove it is *not* better, which is far cheaper. A move that
  /// fails that test unexpectedly is re-searched properly. Pays because
  /// ordering is good enough that the first move usually is the best one.
  ///
  /// Measured at 300ms/move over 400 games: +11 Elo [-13, +36], depth
  /// 7.50 → 7.79. Modest on its own, and kept on for what depends on it:
  /// the null-window nodes it creates are where reverse futility, late
  /// move pruning and null move do their work.
  final bool pvs;

  /// Search one ply further from a position where the side to move is in
  /// check. Checks are forcing — the reply set is tiny — so the extra ply is
  /// cheap, and it is what stops a horizon-edge check sequence from being
  /// misjudged by a static evaluation that cannot see the mate behind it.
  ///
  /// Off: measured at 300ms/move over 400 games at -1 Elo [-26, +24] while
  /// costing a third of a ply of nominal depth (8.08 → 7.75). Quiescence
  /// already searches every evasion when in check, which is most of what
  /// the extension would have added.
  final bool checkExtension;

  /// When a quiet move causes a cutoff, also *debit* the quiet moves that
  /// were tried before it at that node. Rewarding only the winner leaves a
  /// move that keeps getting tried first and keeps failing with the same
  /// high score it earned somewhere else; the debit is what lets ordering
  /// unlearn it.
  ///
  /// Measured at 300ms/move over 400 games: +42 Elo [+16, +68], with the
  /// depth reached unchanged — like SEE ordering, a better order rather
  /// than a deeper search.
  final bool historyMalus;

  /// Whether null-move pruning may also run at PV nodes. Off means non-PV
  /// nodes only — the textbook choice, on the argument that a PV node is
  /// one where the score is going to matter exactly and a null-move cut
  /// there is a bet on a heuristic where precision was the point.
  ///
  /// On: the textbook lost. Measured at 300ms/move over 400 games, allowing
  /// it at PV nodes is +30 Elo [+5, +56] with the depth reached unchanged.
  /// The PV is re-searched every iteration anyway, which is most of the
  /// safety the restriction was buying.
  final bool nullMoveAtPv;

  /// The same options with the named fields replaced.
  SearchOptions copyWith({
    bool? seePruning,
    bool? deltaPruning,
    bool? reuseTable,
    bool? nullMove,
    bool? nullMoveAtPv,
    bool? lateMoveReductions,
    bool? historyHeuristic,
    bool? pvs,
    bool? checkExtension,
    bool? historyMalus,
    bool? seeOrdering,
    bool? counterMove,
    bool? reverseFutility,
    bool? futilityPruning,
    bool? lateMovePruning,
  }) {
    return SearchOptions(
      seePruning: seePruning ?? this.seePruning,
      deltaPruning: deltaPruning ?? this.deltaPruning,
      reuseTable: reuseTable ?? this.reuseTable,
      nullMove: nullMove ?? this.nullMove,
      nullMoveAtPv: nullMoveAtPv ?? this.nullMoveAtPv,
      lateMoveReductions: lateMoveReductions ?? this.lateMoveReductions,
      historyHeuristic: historyHeuristic ?? this.historyHeuristic,
      pvs: pvs ?? this.pvs,
      checkExtension: checkExtension ?? this.checkExtension,
      historyMalus: historyMalus ?? this.historyMalus,
      seeOrdering: seeOrdering ?? this.seeOrdering,
      counterMove: counterMove ?? this.counterMove,
      reverseFutility: reverseFutility ?? this.reverseFutility,
      futilityPruning: futilityPruning ?? this.futilityPruning,
      lateMovePruning: lateMovePruning ?? this.lateMovePruning,
    );
  }

  /// [copyWith] by flag name, for a harness that takes the flag on the
  /// command line. Throws [ArgumentError] on an unknown name.
  SearchOptions withFlag(String name, bool value) {
    return switch (name) {
      'seePruning' => copyWith(seePruning: value),
      'deltaPruning' => copyWith(deltaPruning: value),
      'reuseTable' => copyWith(reuseTable: value),
      'nullMove' => copyWith(nullMove: value),
      'nullMoveAtPv' => copyWith(nullMoveAtPv: value),
      'lateMoveReductions' => copyWith(lateMoveReductions: value),
      'historyHeuristic' => copyWith(historyHeuristic: value),
      'pvs' => copyWith(pvs: value),
      'checkExtension' => copyWith(checkExtension: value),
      'historyMalus' => copyWith(historyMalus: value),
      'seeOrdering' => copyWith(seeOrdering: value),
      'counterMove' => copyWith(counterMove: value),
      'reverseFutility' => copyWith(reverseFutility: value),
      'futilityPruning' => copyWith(futilityPruning: value),
      'lateMovePruning' => copyWith(lateMovePruning: value),
      _ => throw ArgumentError.value(name, 'name', 'unknown search flag'),
    };
  }

  /// Skip captures in quiescence that static exchange evaluation says lose
  /// material outright.
  final bool seePruning;

  /// Skip captures in quiescence that cannot bring the score back to alpha
  /// even if they win the target for free.
  final bool deltaPruning;

  /// Keep the transposition table between calls to [Searcher.search] instead
  /// of starting each one empty. Only useful if the same Searcher survives
  /// across moves — which in the app it does: AiPlayer holds one Searcher in
  /// a long-lived isolate and sets this. Measured there at 30% fewer nodes
  /// per move, since the opponent's reply almost always lands inside a
  /// subtree the previous search already explored.
  final bool reuseTable;

  /// Try passing the turn before searching properly. If the position still
  /// beats beta after handing the opponent a free move, the real moves are
  /// better still and the subtree can be cut.
  final bool nullMove;

  /// Search the later, less promising moves shallower, re-searching at full
  /// depth only when one of them unexpectedly beats alpha.
  final bool lateMoveReductions;

  /// Order quiet moves by how often they have caused a cutoff anywhere in
  /// this search, not just at sibling nodes the way killers do.
  ///
  /// Only takes effect from [Searcher.historyMinDepth] up. The table needs
  /// a tree big enough to learn something from: measured over 14 plies,
  /// nodes moved -0.2% at depth 3, +4.8% at depth 4, +0.3% at depth 5, then
  /// -29.4% at depth 6 and -34.6% at depth 7. Enabling it everywhere would
  /// hand Medium a 5% regression to buy Hard a 29% gain.
  ///
  /// With late-move and futility pruning in the search it matters far more
  /// than node counts suggest: measured at 300ms/move over 400 games at
  /// +105 Elo [+79, +132], the largest of any flag. The prunings skip the
  /// late quiet moves outright, so the order history imposes now decides
  /// which quiet moves are searched at all, not merely which come first.
  final bool historyHeuristic;

  static const SearchOptions none = SearchOptions(
    seePruning: false,
    deltaPruning: false,
    nullMove: false,
    lateMoveReductions: false,
    historyHeuristic: false,
    pvs: false,
    checkExtension: false,
    historyMalus: false,
    seeOrdering: false,
    counterMove: false,
    reverseFutility: false,
    futilityPruning: false,
    lateMovePruning: false,
  );
}

/// Best-move search result for the AI.
class SearchResult {
  const SearchResult({
    required this.move,
    required this.score,
    required this.nodes,
    this.depth = 0,
  });

  /// The move the searcher recommends for [Board.sideToMove].
  /// Null only if there are no legal moves (terminal position).
  final Move? move;

  /// Score from the searching side's perspective. Higher = better for the
  /// side to move. Mate scores are large (close to ±[Evaluator.mateScore]).
  final int score;

  /// Number of nodes visited — useful for tuning and debugging.
  final int nodes;

  /// Deepest iteration that ran to completion — the depth [move] actually
  /// comes from. Zero for a book hit or a terminal position. Under a time
  /// budget this is the number that says how strong the search was, since
  /// the requested depth is only a ceiling.
  final int depth;
}

/// Iterative-deepening alpha-beta search with quiescence extension,
/// transposition table, MVV-LVA ordering, and killer-move heuristic.
///
/// Slice 4b stacks three classical improvements on top of 4a:
///
/// **Iterative deepening** — instead of searching directly to depth N, we
/// search depth 1, then 2, ..., then N. The best move from depth d-1
/// becomes the first move tried at depth d, dramatically improving alpha-
/// beta cutoffs. Counterintuitively, ID+TT is usually *faster* than direct
/// depth-N because shallow searches populate the TT and provide ordering
/// hints that pay off at deeper iterations.
///
/// **Transposition table (TT)** — Zobrist-keyed hash table of search
/// results. When we revisit a position via a different move order, the
/// cached score and bound type let us skip the work (or at least tighten
/// alpha-beta windows). The cached best move is also a strong first
/// candidate for move ordering even when the cached score isn't usable.
///
/// **Killer moves** — quiet (non-capture) moves that caused beta cutoffs at
/// sibling nodes at the same ply depth tend to be tactical refutations
/// that recur. We keep 2 killers per ply and try them after captures.
class Searcher {
  Searcher({
    this.tablebase,
    this.evalParams,
    this.nnue,
    this.book,
    this.options = const SearchOptions(),
  });

  /// Optional opening book. A hit returns immediately without searching —
  /// the move is one this engine chose at greater depth than it could afford
  /// at the board, and the time saved goes to the middlegame instead.
  final OpeningBook? book;

  /// Which techniques this searcher uses. See [SearchOptions].
  final SearchOptions options;

  /// Optional endgame tablebase. When provided, the searcher probes it
  /// before generating moves; a TB hit replaces normal search with the
  /// perfect-play result.
  final Tablebase? tablebase;

  /// Optional eval-parameter override. When null, [Evaluator] uses its
  /// hand-tuned defaults. The Phase 2 Texel tuner passes a candidate
  /// [EvalParams] here to evaluate positions with alternate weights.
  final EvalParams? evalParams;

  /// Optional learned evaluator (Phase 3). When non-null, leaf positions
  /// are scored by the NN instead of the classical [Evaluator] —
  /// [evalParams] is ignored in that case. Tablebase probes still
  /// short-circuit first, so endgame play stays perfect regardless.
  final NnueEvaluator? nnue;

  /// Max plies the quiescence search can extend past the main horizon.
  static const int _maxQuiescenceDepth = 8;

  /// History score at which the whole table is halved, keeping the numbers
  /// bounded and letting later evidence outweigh earlier.
  static const int _historyCeiling = 1 << 20;

  /// Shallowest search depth at which the history table earns its keep.
  /// See [SearchOptions.historyHeuristic] for the measurements.
  static const int historyMinDepth = 6;

  /// Slack allowed to delta pruning, in centipawns. Roughly a padati's worth
  /// on top of the captured piece, so a capture that merely looks hopeless
  /// on a static count still gets searched if it is close.
  static const int _deltaMargin = 120;

  /// Mate scores beyond this threshold are stored without depth-adjustment.
  /// Positions within this band aren't TT-cached for the score (only the
  /// best move), to dodge the mate-distance correction issue cleanly.
  static const int _mateThreshold = Evaluator.mateScore - 1000;

  /// Static-pruning margins and depth limits. The margins are in
  /// centipawns against a padati of 92 and a mantri of 142: a quiet move
  /// rarely swings the static picture by more than a minor piece, and
  /// [_reverseFutilityMargin] per ply of remaining depth is what a search
  /// that deep can typically find.
  static const int _reverseFutilityMaxDepth = 3;
  static const int _reverseFutilityMargin = 120;
  static const int _futilityMaxDepth = 2;
  static const int _futilityMargin = 150;
  static const int _lateMovePruningMaxDepth = 3;
  static const int _lateMovePruningBase = 3;

  /// Ordering score written over a move that static pruning skipped, so the
  /// history malus can tell it from one that was actually searched.
  static const int _prunedScore = -(1 << 30);

  /// How often to consult the clock, in nodes. Reading a Stopwatch on every
  /// node is measurable overhead; 2047 keeps the check under a millisecond
  /// of granularity even on the slowest position measured.
  static const int _clockCheckMask = 2047;

  /// Cutoff counts per quiet move, indexed [side][from][to].
  ///
  /// Killers only remember the last two cutoffs at one ply, so a move that
  /// refutes things all over the tree is forgotten as soon as a sibling
  /// overwrites it. History keeps a running score across the whole search
  /// and orders the quiet moves that killers have nothing to say about —
  /// which is most of them.
  late List<List<List<int>>> _history;

  /// The quiet move that last refuted each opponent move, indexed
  /// [side][_moveIndex(opponent move)]. See [SearchOptions.counterMove].
  late List<List<Move?>> _counterMoves;

  /// Whether history ordering is in play for the search now running.
  bool _historyActive = false;

  int _nodes = 0;
  late TranspositionTable _tt;
  TranspositionTable? _ttOrNull;
  late List<List<Move?>> _killers; // [ply][slot 0|1]

  /// Wall-clock guard for the current search. Null when unbudgeted.
  Stopwatch? _clock;
  Duration? _budget;

  /// Set once the budget is spent. Every frame in flight then unwinds
  /// without storing anything, and the partial iteration is discarded.
  bool _aborted = false;

  /// True when the last [search] returned before finishing the depth it was
  /// asked for. The move is still sound — it comes from the last iteration
  /// that *did* finish — just shallower than requested.
  bool get lastSearchWasCutShort => _aborted;

  /// Search to [depth] plies and return the best move + score.
  /// Score is from [Board.sideToMove]'s perspective at call time.
  ///
  /// [budget] caps wall-clock time. Iterative deepening makes this safe:
  /// each depth completes before the next begins, so an overrun discards
  /// only the unfinished iteration and returns the best move from the last
  /// finished one. Without it, depth is the only bound — and depth is a
  /// terrible predictor of time. Measured on one tactical position: depth 6
  /// took 46 seconds where the same depth averages under a second in normal
  /// play. That overran the caller's own 30s kill-switch, which returns no
  /// move at all and leaves the game unable to continue.
  ///
  /// The budget is also what drives depth when [depth] is set high: a new
  /// iteration only starts if it looks likely to finish inside the budget
  /// (see [_canAffordNextIteration]), so a caller that wants "as deep as N
  /// seconds allows" passes a depth it does not expect to reach.
  SearchResult search(Board board, {required int depth, Duration? budget}) {
    final bookMove = book?.lookup(board.zobrist);
    if (bookMove != null) {
      // Trust but verify: a book built against different move generation, or
      // simply corrupted, must not be able to play an illegal move.
      if (MoveGenerator.legalMoves(board).contains(bookMove)) {
        _aborted = false;
        return SearchResult(move: bookMove, score: 0, nodes: 0);
      }
    }
    _nodes = 0;
    _aborted = false;
    _budget = budget;
    _clock = budget == null ? null : (Stopwatch()..start());
    if (!options.reuseTable || _ttOrNull == null) {
      _ttOrNull = TranspositionTable(sizeBits: 18);
    }
    _tt = _ttOrNull!;
    // Check extensions can add up to one ply per two, so the tree may run
    // to twice the nominal depth before quiescence.
    final maxPly = 2 * depth + _maxQuiescenceDepth + 2;
    _killers = List.generate(maxPly, (_) => <Move?>[null, null]);
    // Cleared per search rather than carried with the table: history is
    // about where cutoffs happened in *this* tree, and a stale table from
    // two moves ago would order by a shape of position that is gone.
    _historyActive = options.historyHeuristic && depth >= historyMinDepth;
    _history = List.generate(
      2,
      (_) => List.generate(64, (_) => List.filled(64, 0)),
    );
    _counterMoves = List.generate(2, (_) => List<Move?>.filled(64 * 64, null));

    Move? bestMove;
    int bestScore = 0;
    var completedDepth = 0;
    // Wall-clock cost of the last two finished iterations, for predicting
    // whether the next one fits. Zero until measured.
    var lastIterationMicros = 0;
    var prevIterationMicros = 0;

    // Iterative deepening: each iteration's best move seeds the next.
    for (var d = 1; d <= depth; d++) {
      final startMicros = _clock?.elapsedMicroseconds ?? 0;
      final result = _rootSearch(board, d, bestMove);
      // An aborted iteration searched only some of the root moves, so its
      // "best" is meaningless — keep the previous depth's answer instead.
      //
      // Unless there is no previous depth. A budget can be spent inside the
      // very first iteration: depth 1 still runs a full quiescence at every
      // root move, and quiescence is exactly what runs away in the positions
      // this guard exists for. Falling back to null there would reproduce
      // the bug — the caller cannot continue the game without a move. The
      // partial iteration's best is a real, legal move, and at worst it is
      // the first move after ordering, which is the TT/PV move or the best
      // capture by MVV-LVA rather than an arbitrary one.
      if (_aborted) {
        bestMove ??= result.move;
        break;
      }
      if (result.move == null) {
        return SearchResult(move: null, score: result.score, nodes: _nodes);
      }
      bestMove = result.move;
      bestScore = result.score;
      completedDepth = d;
      // If we found a forced mate, no point searching deeper.
      if (bestScore.abs() >= _mateThreshold) break;

      prevIterationMicros = lastIterationMicros;
      lastIterationMicros = (_clock?.elapsedMicroseconds ?? 0) - startMicros;
      if (!_canAffordNextIteration(lastIterationMicros, prevIterationMicros)) {
        break;
      }
    }

    return SearchResult(
      move: bestMove,
      score: bestScore,
      nodes: _nodes,
      depth: completedDepth,
    );
  }

  /// Whether to start another iteration, given how long the last two took.
  ///
  /// The hard budget only stops a search that has already overrun, and an
  /// iteration cut off by it is thrown away — so starting one that cannot
  /// finish spends the rest of the budget for nothing. Each iteration costs
  /// roughly a constant multiple of the one before (the effective branching
  /// factor), so the next is predicted from the growth just observed and
  /// started only if that prediction fits in what is left.
  ///
  /// The growth ratio is clamped: below [_minIterationGrowth] the previous
  /// iteration was probably a cheap TT-served one and the next will not be;
  /// above [_maxIterationGrowth] a single tactical blow-up would otherwise
  /// convince the search that nothing ever fits again.
  bool _canAffordNextIteration(int lastMicros, int prevMicros) {
    final clock = _clock;
    if (clock == null) return true;
    final growth = prevMicros == 0
        ? _minIterationGrowth
        : (lastMicros / prevMicros).clamp(
            _minIterationGrowth,
            _maxIterationGrowth,
          );
    final predicted = lastMicros * growth;
    return clock.elapsedMicroseconds + predicted <= _budget!.inMicroseconds;
  }

  /// Bounds on the predicted cost ratio between successive iterations. See
  /// [_canAffordNextIteration].
  static const double _minIterationGrowth = 2.0;
  static const double _maxIterationGrowth = 6.0;

  /// True once the budget is spent. Cheap on the vast majority of calls:
  /// the clock is only read every [_clockCheckMask] + 1 nodes.
  bool _outOfTime() {
    if (_aborted) return true;
    final clock = _clock;
    if (clock == null) return false;
    if (_nodes & _clockCheckMask != 0) return false;
    if (clock.elapsed < _budget!) return false;
    _aborted = true;
    return true;
  }

  _RootResult _rootSearch(Board board, int depth, Move? prevBest) {
    final moves = MoveGenerator.legalMoves(board);
    if (moves.isEmpty) {
      final inCheck = MoveGenerator.isInCheck(board, board.sideToMove);
      return _RootResult(move: null, score: inCheck ? -Evaluator.mateScore : 0);
    }
    // Root ordering: prevBest first if available, then TT move, then MVV-LVA.
    final scores = _scoreMoves(board, moves, prevBest, 0);
    // Bring the top-ordered move forward now, so that an abort before any
    // move finishes still leaves the best-guess move in [bestMove].
    _pickBest(moves, scores, 0);

    Move bestMove = moves.first;
    var bestScore = -Evaluator.mateScore - 1;
    var alpha = -Evaluator.mateScore - 1;
    const beta = Evaluator.mateScore + 1;

    for (var i = 0; i < moves.length; i++) {
      _pickBest(moves, scores, i);
      final move = moves[i];
      board.makeMove(move);
      int score;
      if (options.pvs && i > 0) {
        score = -_negamax(board, depth - 1, -alpha - 1, -alpha, 1);
        if (!_aborted && score > alpha) {
          score = -_negamax(board, depth - 1, -beta, -alpha, 1);
        }
      } else {
        score = -_negamax(board, depth - 1, -beta, -alpha, 1);
      }
      board.undoMove();
      if (_aborted) break;
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
      if (score > alpha) alpha = score;
    }
    return _RootResult(move: bestMove, score: bestScore);
  }

  /// Negamax with alpha-beta, TT probe/store, and killer-move ordering.
  /// Returns score from [Board.sideToMove]'s perspective.
  int _negamax(Board board, int depth, int alpha, int beta, int ply) {
    _nodes++;
    if (_outOfTime()) return 0;

    // A position already seen is a draw by repetition, scored immediately
    // rather than at the third occurrence: once a line returns to a
    // position, either side can force the third. Scoring it here is what
    // stops the engine shuffling in a position it should be converting,
    // and what lets it find a perpetual when it is losing.
    if (ply > 0 && board.isRepetition) return 0;

    final inCheckHere = MoveGenerator.isInCheck(board, board.sideToMove);
    // Check extension. Done before the table is consulted so that the depth
    // stored and probed for this position is the depth actually searched.
    if (options.checkExtension && inCheckHere) depth++;

    final alphaOrig = alpha;
    final key = board.zobrist;
    final isPv = beta - alpha > 1;

    // Endgame tablebase probe. A TB hit gives perfect-play outcome,
    // bypassing normal search. We encode "side to move wins" / "loses"
    // as mate-adjacent scores so the rest of the search prefers them
    // appropriately; "draw" returns 0.
    final tb = tablebase;
    if (tb != null) {
      final tbResult = tb.probe(board);
      if (tbResult != null && tbResult != TbOutcome.invalid) {
        switch (tbResult) {
          case TbOutcome.sideToMoveWins:
            return Evaluator.mateScore - (1000 - depth);
          case TbOutcome.sideToMoveLoses:
            return -(Evaluator.mateScore - (1000 - depth));
          case TbOutcome.draw:
            return 0;
        }
      }
    }

    // TT probe: if we've searched this position at >= the depth we need
    // now, the cached bound can either give us the answer outright (EXACT)
    // or shrink our window (LOWER/UPPER bound).
    Move? ttMove;
    final ttEntry = _tt.probe(key);
    if (ttEntry != null) {
      ttMove = ttEntry.bestMove;
      if (ttEntry.depth >= depth) {
        switch (ttEntry.scoreType) {
          case ScoreType.exact:
            return ttEntry.score;
          case ScoreType.lowerBound:
            if (ttEntry.score > alpha) alpha = ttEntry.score;
          case ScoreType.upperBound:
            if (ttEntry.score < beta) beta = ttEntry.score;
        }
        if (alpha >= beta) return ttEntry.score;
      }
    }

    if (depth == 0) {
      return _quiescence(
        board,
        alpha,
        beta,
        _maxQuiescenceDepth,
        inCheck: inCheckHere,
      );
    }

    // Whether the static-evaluation prunings below may run here. All of
    // them bet that a quiet static picture predicts the search's answer,
    // which is false in check (the picture is about to change by force),
    // near mate scores (bounds are not centipawns there), at PV nodes (the
    // exact value is wanted), and in a bare-padati endgame (where a small
    // static edge and the actual result have little to do with each other).
    final canPruneStatically =
        !isPv &&
        !inCheckHere &&
        alpha > -_mateThreshold &&
        beta < _mateThreshold &&
        _hasNonPawnMaterial(board, board.sideToMove);
    int? staticEval;

    // Reverse futility pruning: so far ahead that even conceding a margin
    // per ply of depth still clears beta — cut without searching.
    if (options.reverseFutility &&
        canPruneStatically &&
        depth <= _reverseFutilityMaxDepth) {
      staticEval = _evalFor(board.sideToMove, board);
      if (staticEval - _reverseFutilityMargin * depth >= beta) return beta;
    }

    // Null-move pruning. Hand the opponent a free move; if the position
    // still beats beta after that, the real moves are better still and the
    // whole subtree can go.
    //
    // Withheld in three cases. In check, passing is not merely bad but
    // illegal-adjacent — the check must be answered. At a PV node the exact
    // score is wanted, not a bet (see [SearchOptions.nullMoveAtPv]). And in
    // a thin endgame the premise fails: zugzwang positions are exactly the
    // ones where having to move is the problem, so "passing was fine" says
    // nothing about actually moving. The material floor is what keeps it
    // out of those.
    if (options.nullMove &&
        !inCheckHere &&
        depth >= 3 &&
        (!isPv || options.nullMoveAtPv) &&
        board.nullMoveDepth == 0 &&
        _hasNonPawnMaterial(board, board.sideToMove)) {
      const reduction = 2;
      board.makeNullMove();
      final score = -_negamax(
        board,
        depth - 1 - reduction,
        -beta,
        -beta + 1,
        ply + 1,
      );
      board.undoNullMove();
      if (_aborted) return 0;
      if (score >= beta) return beta;
    }

    final moves = MoveGenerator.legalMoves(board);
    if (moves.isEmpty) {
      return inCheckHere ? -(Evaluator.mateScore - (1000 - depth)) : 0;
    }
    final scores = _scoreMoves(board, moves, ttMove, ply);

    // Quiet moves at a shallow node may be skipped on two static grounds,
    // once the first move has been searched so there is always a real
    // score to return. Neither skips a move that gives check — that is
    // known only after making it, so the test comes after makeMove.
    final futile =
        options.futilityPruning &&
        canPruneStatically &&
        depth <= _futilityMaxDepth;
    final lateMoveLimit =
        options.lateMovePruning &&
            canPruneStatically &&
            depth <= _lateMovePruningMaxDepth
        ? _lateMovePruningBase + depth * depth
        : moves.length;
    if (futile) staticEval ??= _evalFor(board.sideToMove, board);

    var bestScore = -Evaluator.mateScore - 1;
    Move? bestMove;
    for (var i = 0; i < moves.length; i++) {
      _pickBest(moves, scores, i);
      final move = moves[i];
      // We need to know if this was a quiet move BEFORE making it, in case
      // it produces a beta cutoff and becomes a killer candidate.
      final wasQuiet = board.pieceAt(move.to) == null;
      board.makeMove(move);
      final givesCheck = MoveGenerator.isInCheck(board, board.sideToMove);

      if (wasQuiet && i > 0 && !givesCheck) {
        final prune =
            i >= lateMoveLimit ||
            (futile && staticEval! + _futilityMargin * depth <= alpha);
        if (prune) {
          board.undoMove();
          // Mark it unsearched so the history malus below leaves it alone.
          scores[i] = _prunedScore;
          continue;
        }
      }

      // Late move reductions. Ordering already put the moves worth looking
      // at first, so the tail of the list is mostly noise — searched
      // shallower, and only re-searched in full if one of them surprises us
      // by beating alpha. Captures, checks and the first few moves are left
      // alone: those are where the ordering is actually confident.
      final reducible =
          options.lateMoveReductions &&
          depth >= 3 &&
          i >= 3 &&
          wasQuiet &&
          !inCheckHere &&
          !givesCheck;
      int score;
      if (options.pvs && i > 0) {
        // Principal variation search: a zero-width window can only show
        // that this move is *not* better than what we have, and that is
        // the answer for nearly every move. Reduced as well if LMR applies.
        // Fails high are rare, and get the search they deserve: first at
        // full depth on the same window, then — at a PV node, where the
        // exact value is wanted — on the full window.
        score = -_negamax(
          board,
          depth - (reducible ? 2 : 1),
          -alpha - 1,
          -alpha,
          ply + 1,
        );
        if (reducible && !_aborted && score > alpha) {
          score = -_negamax(board, depth - 1, -alpha - 1, -alpha, ply + 1);
        }
        if (!_aborted && score > alpha && score < beta) {
          score = -_negamax(board, depth - 1, -beta, -alpha, ply + 1);
        }
      } else if (reducible) {
        score = -_negamax(board, depth - 2, -alpha - 1, -alpha, ply + 1);
        if (!_aborted && score > alpha) {
          score = -_negamax(board, depth - 1, -beta, -alpha, ply + 1);
        }
      } else {
        score = -_negamax(board, depth - 1, -beta, -alpha, ply + 1);
      }
      board.undoMove();
      // A score from an aborted subtree is noise. Leave without letting it
      // reach bestScore, and without storing anything below.
      if (_aborted) return 0;
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
      if (bestScore > alpha) alpha = bestScore;
      if (alpha >= beta) {
        if (wasQuiet) {
          _recordKiller(ply, move);
          _recordHistory(board.sideToMove, move, depth);
          if (options.counterMove) {
            final last = board.lastMove;
            if (last != null) {
              _counterMoves[board.sideToMove.index][_moveIndex(last)] = move;
            }
          }
          if (options.historyMalus) {
            // The quiet moves tried ahead of this one were ordered above it
            // and turned out not to refute anything here.
            for (var j = 0; j < i; j++) {
              final earlier = moves[j];
              if (scores[j] != _prunedScore &&
                  board.pieceAt(earlier.to) == null) {
                _recordHistory(board.sideToMove, earlier, -depth);
              }
            }
          }
        }
        break;
      }
    }

    // TT store. Determine bound type from how the search ended:
    //   - bestScore <= alphaOrig : never beat the original alpha → UPPER
    //   - bestScore >= beta      : beta cutoff → LOWER
    //   - in between             : EXACT
    // Skip mate scores — those need a depth adjustment we're not doing yet.
    if (!_aborted && bestScore.abs() < _mateThreshold) {
      final ScoreType type;
      if (bestScore <= alphaOrig) {
        type = ScoreType.upperBound;
      } else if (bestScore >= beta) {
        type = ScoreType.lowerBound;
      } else {
        type = ScoreType.exact;
      }
      _tt.store(
        key: key,
        depth: depth,
        score: bestScore,
        scoreType: type,
        bestMove: bestMove,
      );
    }

    return bestScore;
  }

  /// Quiescence search: follow only capture sequences past the main
  /// horizon until quiet, or [_maxQuiescenceDepth] is reached.
  ///
  /// In-check special case: stand-pat is unsound when the side to move is
  /// in check (they can't "pass" — they must address the check), and
  /// capture-only would miss non-capture evasions like blocking or king
  /// stepping aside. So when in check we skip stand-pat and consider all
  /// legal moves.
  int _quiescence(
    Board board,
    int alpha,
    int beta,
    int qDepth, {
    bool? inCheck,
  }) {
    _nodes++;
    if (_outOfTime()) return 0;
    inCheck ??= MoveGenerator.isInCheck(board, board.sideToMove);

    // Evaluated once and reused: stand-pat, the horizon return and delta
    // pruning all want the same number, and the evaluation is the single
    // most-called thing in the search.
    final standPat = inCheck ? 0 : _evalFor(board.sideToMove, board);
    if (!inCheck) {
      if (standPat >= beta) return beta;
      if (standPat > alpha) alpha = standPat;
    }
    if (qDepth == 0) {
      return inCheck ? _evalFor(board.sideToMove, board) : standPat;
    }

    final List<Move> movesToTry;
    if (inCheck) {
      // Evasions are never pruned — the side to move has to answer the
      // check, so there is no "declining" any of these.
      movesToTry = MoveGenerator.legalMoves(board);
      if (movesToTry.isEmpty) {
        // Mated at the quiescence horizon. Same mate-distance encoding as
        // the main search so the score interleaves correctly.
        return -(Evaluator.mateScore - (1000 - qDepth));
      }
    } else {
      // Only captures are generated here — the quiet moves would be thrown
      // away, and generating them was most of a quiet node's cost. The one
      // thing this cannot see is a stalemate, which the full generator
      // would have scored as a draw; quiescence stands pat instead, the
      // usual choice.
      movesToTry = <Move>[];
      for (final m in MoveGenerator.legalCaptures(board)) {
        final victim = board.pieceAt(m.to)!;

        // Delta pruning: even winning the target outright would not bring
        // the score back to alpha, so the whole line is hopeless. The
        // margin covers a promotion swing on the reply.
        if (options.deltaPruning &&
            standPat + Evaluator.pieceValue(victim.type) + _deltaMargin <
                alpha) {
          continue;
        }

        // SEE pruning: the capture gives the material straight back. These
        // are the bulk of the tree in a position with many contacts, and
        // searching them is what made quiescence run away.
        //
        // Only asked when the capture could plausibly lose material — a
        // cheaper piece taking a dearer one is winning on any sequence, and
        // SEE is far too expensive to run on captures whose answer is
        // already known. Skipping those cut the pruning's own cost from
        // most of its benefit to almost none.
        if (options.seePruning) {
          final attacker = board.pieceAt(m.from);
          if (attacker != null &&
              _seeValue(attacker.type) > _seeValue(victim.type) &&
              _see(board, m) < 0) {
            continue;
          }
        }

        movesToTry.add(m);
      }
      if (movesToTry.isEmpty) return alpha;
    }
    // No killers at a quiescence ply.
    final scores = _scoreMoves(board, movesToTry, null, -1);

    for (var i = 0; i < movesToTry.length; i++) {
      _pickBest(movesToTry, scores, i);
      final move = movesToTry[i];
      board.makeMove(move);
      final score = -_quiescence(board, -beta, -alpha, qDepth - 1);
      board.undoMove();
      if (_aborted) return 0;
      if (score >= beta) return beta;
      if (score > alpha) alpha = score;
    }
    return alpha;
  }

  /// Static exchange evaluation: the material [move] wins or loses if both
  /// sides keep capturing on its destination square with their cheapest
  /// piece available.
  ///
  /// Positive means the capture gains material, negative that it loses it.
  /// Used to skip the losing ones in quiescence, which is where the search
  /// used to run away — a position with clashing pawn walls took 46 seconds
  /// at depth 6 almost entirely on captures that give material back.
  /// Piece value as static exchange evaluation needs it.
  ///
  /// Differs from [Evaluator.pieceValue] in exactly one place: the raja is
  /// worth 0 there, because a side always has one and material counting
  /// would be meaningless otherwise. Here that would make it look like the
  /// *cheapest* attacker and volunteer it first into every exchange, so it
  /// is priced above everything instead — which is also the truth, since
  /// losing it ends the game.
  static int _seeValue(PieceType type) =>
      type == PieceType.king ? 30000 : Evaluator.pieceValue(type);

  /// [_see] for tests. The sign and magnitude are what the pruning acts on,
  /// and a wrong sign silently discards winning captures, so it is worth
  /// asserting directly rather than inferring from which move comes back.
  @visibleForTesting
  int debugSee(Board board, Move move) => _see(board, move);

  int _see(Board board, Move move) {
    final victim = board.pieceAt(move.to);
    if (victim == null) return 0;
    final attacker = board.pieceAt(move.from);
    if (attacker == null) return 0;

    // gains[d] is the material balance after d captures, from the point of
    // view of the side that made capture d.
    final gains = <int>[_seeValue(victim.type)];
    final vacated = <Square>{move.from};
    var onSquare = attacker.type;
    var side = board.sideToMove.opposite;
    var d = 0;

    while (true) {
      final next = MoveGenerator.leastValuableAttacker(
        board,
        move.to,
        side,
        vacated,
        _seeValue,
      );
      if (next == null) break;
      final nextPiece = board.pieceAt(next)!;
      // A king may not capture into an attacked square. If anything of the
      // other side still bears on it, the exchange simply stops here.
      if (nextPiece.type == PieceType.king) {
        final vacatedPlusKing = {...vacated, next};
        final reply = MoveGenerator.leastValuableAttacker(
          board,
          move.to,
          side.opposite,
          vacatedPlusKing,
          _seeValue,
        );
        if (reply != null) break;
      }
      d++;
      gains.add(_seeValue(onSquare) - gains[d - 1]);
      onSquare = nextPiece.type;
      vacated.add(next);
      side = side.opposite;
    }

    // Walk back: at every point the side to move could have declined the
    // capture, so each gain is capped by the option of standing pat.
    for (var i = d; i > 0; i--) {
      gains[i - 1] = -math.max(-gains[i - 1], gains[i]);
    }
    return gains[0];
  }

  /// True when [side] has a piece other than the raja and its padatis.
  ///
  /// The zugzwang guard for null-move pruning. In a bare-pawn endgame the
  /// premise behind the null move — that having a free move can only help —
  /// stops holding, because the whole difficulty of those positions is being
  /// forced to move at all.
  static bool _hasNonPawnMaterial(Board board, Side side) =>
      board.nonPawnPieceCount(side) > 0;

  /// Credits a quiet move for causing a cutoff — or, with a negative
  /// [depth], debits one that was tried first and did not.
  ///
  /// Weighted by depth squared: a cutoff found eight plies deep says far
  /// more about a move than one found at the horizon, where almost anything
  /// can look like a refutation.
  void _recordHistory(Side side, Move move, int depth) {
    if (!_historyActive) return;
    final from = move.from.file * 8 + move.from.rank;
    final to = move.to.file * 8 + move.to.rank;
    final table = _history[side.index];
    final delta = depth < 0 ? -(depth * depth) : depth * depth;
    final updated = table[from][to] + delta;
    // Halve everything when any entry gets large, so early cutoffs cannot
    // dominate ordering for the rest of the search. Arithmetic shift keeps
    // the sign, so debits decay the same way credits do.
    if (updated.abs() > _historyCeiling) {
      for (final row in table) {
        for (var i = 0; i < row.length; i++) {
          row[i] >>= 1;
        }
      }
    }
    table[from][to] = table[from][to] + delta;
  }

  void _recordKiller(int ply, Move move) {
    if (ply < 0 || ply >= _killers.length) return;
    final slot = _killers[ply];
    if (slot[0] == move) return; // already the primary — nothing to do
    slot[1] = slot[0];
    slot[0] = move;
  }

  /// Side-to-move-perspective leaf evaluation.
  ///
  /// Prefers the learned NNUE evaluator when one is wired in; falls back
  /// to the classical [Evaluator] otherwise. Both return white-perspective
  /// centipawns which we then flip for black-to-move nodes.
  int _evalFor(Side side, Board board) {
    final whiteScore = nnue != null
        ? nnue!.evaluateWhite(board)
        : Evaluator.evaluate(board, evalParams);
    return side == Side.white ? whiteScore : -whiteScore;
  }

  /// Ordering score for every move in [moves], index-aligned. Priority:
  ///   1. The TT / previous-iteration best move (pvMove)
  ///   2. Captures that do not lose material, by MVV-LVA score
  ///   3. Killer moves at this ply (first slot, then second slot)
  ///   4. The countermove to the opponent's last move
  ///   5. Quiet moves by history, where it is active
  ///   6. Captures that lose material (see [SearchOptions.seeOrdering])
  ///
  /// The list is not sorted here: [_pickBest] selects the best remaining
  /// move one at a time. Most nodes cut off after the first move or two, so
  /// sorting the whole list was paying for an order nobody read — and the
  /// old comparator recomputed both scores on every comparison besides.
  List<int> _scoreMoves(Board board, List<Move> moves, Move? pvMove, int ply) {
    final killers = (ply >= 0 && ply < _killers.length)
        ? _killers[ply]
        : const <Move?>[null, null];
    final side = board.sideToMove;
    Move? counter;
    if (options.counterMove && ply >= 0) {
      final last = board.lastMove;
      if (last != null) counter = _counterMoves[side.index][_moveIndex(last)];
    }
    final scores = List<int>.filled(moves.length, 0);
    for (var i = 0; i < moves.length; i++) {
      scores[i] = _moveScore(board, moves[i], pvMove, killers, counter, side);
    }
    return scores;
  }

  /// Index of a move's (from, to) pair in a 64×64 table.
  static int _moveIndex(Move m) =>
      (m.from.file * 8 + m.from.rank) * 64 + m.to.file * 8 + m.to.rank;

  /// Swaps the highest-scoring move in `moves[from..]` into position [from],
  /// keeping [scores] aligned.
  static void _pickBest(List<Move> moves, List<int> scores, int from) {
    var best = from;
    for (var i = from + 1; i < moves.length; i++) {
      if (scores[i] > scores[best]) best = i;
    }
    if (best == from) return;
    final m = moves[from];
    moves[from] = moves[best];
    moves[best] = m;
    final s = scores[from];
    scores[from] = scores[best];
    scores[best] = s;
  }

  int _moveScore(
    Board board,
    Move m,
    Move? pvMove,
    List<Move?> killers,
    Move? counter,
    Side side,
  ) {
    if (m == pvMove) return 1000000;
    final victim = board.pieceAt(m.to);
    if (victim != null) {
      final attacker = board.pieceAt(m.from);
      final vv = Evaluator.pieceValue(victim.type);
      final av = attacker == null ? 0 : Evaluator.pieceValue(attacker.type);
      // A dearer piece taking a cheaper one is the only capture that can
      // lose material; those get asked, and the losers go to the back,
      // below every quiet move.
      if (options.seeOrdering && av > vv && _see(board, m) < 0) {
        return -20000 + vv * 10 - av;
      }
      // Captures land in the 10000-15000 range so they beat killers.
      return 10000 + vv * 10 - av;
    }
    if (m == killers[0]) return 9000;
    if (m == killers[1]) return 8000;
    if (m == counter) return 7500;
    if (!_historyActive) return 0;
    // Below the killers, above the unordered remainder. Capped so a heavily
    // credited quiet move can never climb past a killer, which is backed by
    // evidence from this exact ply rather than the tree at large. Debited
    // moves go negative and so behind the never-tried ones.
    final h =
        _history[side.index][m.from.file * 8 + m.from.rank][m.to.file * 8 +
            m.to.rank];
    return h.clamp(-7000, 7000);
  }
}

class _RootResult {
  const _RootResult({required this.move, required this.score});

  final Move? move;
  final int score;
}
