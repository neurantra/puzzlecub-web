import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:math';

import 'board.dart';
import 'move.dart';
import 'move_generator.dart';
import 'nnue.dart';
import 'opening_book.dart';
import 'pieces.dart';
import 'searcher.dart';
import 'tablebase.dart';

/// Generalized "thing that produces a move when asked." Lets the game loop
/// in BoardScreen treat humans and AIs identically — both implement
/// [selectMove], which completes with the player's chosen move (or null if
/// the position is terminal / has no legal moves).
abstract class Player {
  /// The side this player controls.
  Side get side;

  /// Returns the player's choice of move for [board]. May complete
  /// synchronously (AI) or wait for user input (Human).
  ///
  /// Implementations can return null to signal "no legal move available."
  Future<Move?> selectMove(Board board);
}

/// A human player whose moves arrive from UI taps. The game loop calls
/// [selectMove], which returns a future that completes when the UI calls
/// [submitMove] (typically after the user taps source then destination).
///
/// Only one selectMove call is pending at a time. Calling submitMove with
/// no pending request is a no-op.
class HumanPlayer implements Player {
  HumanPlayer({required this.side});

  @override
  final Side side;

  Completer<Move?>? _pending;

  @override
  Future<Move?> selectMove(Board board) {
    // Defensive: if a previous request is somehow still pending (no
    // cancel/submit between calls), resolve it with null rather than
    // abandoning its Completer — an orphaned Completer would leave the
    // awaiting game-loop frame hung forever.
    final stale = _pending;
    if (stale != null && !stale.isCompleted) stale.complete(null);
    _pending = Completer<Move?>();
    return _pending!.future;
  }

  /// UI calls this when the user has chosen a move. Resolves any pending
  /// selectMove future. No-op if there's no pending request.
  void submitMove(Move move) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    _pending = null;
    pending.complete(move);
  }

  /// Cancels any pending request (e.g. when the game ends or the player
  /// switches sides). Completes the future with null.
  void cancel() {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    _pending = null;
    pending.complete(null);
  }
}

/// AI player driven by [Searcher]. Search runs on a fresh background
/// isolate via [Isolate.run] so the UI thread isn't blocked while the
/// engine thinks. Board / Move / Piece / Square are all plain data and
/// cross the isolate boundary by copy.
///
/// Optionally accepts a [blunderChanceSelector] callback: when it returns
/// a probability > 0, the player rolls a die before each search and, on
/// success, plays a uniformly-random legal move instead. Used to make Easy
/// difficulty actually beatable for casual / younger players.
class AiPlayer implements Player {
  AiPlayer({
    required this.side,
    required this.depthSelector,
    this.budgetSelector,
    this.blunderChanceSelector,
    this.tablebaseSelector,
    this.bookSelector,
    this.nnueSelector,
    this.searchTimeout = const Duration(seconds: 30),
    Random? random,
  }) : _random = random ?? Random();

  @override
  final Side side;

  /// Called at search time to fetch the current ply depth. Wrapping this in
  /// a callback (rather than a fixed int) lets the user change difficulty
  /// in Settings and have the next AI move pick up the new depth without
  /// rebuilding the player.
  final int Function() depthSelector;

  /// Wall-clock ceiling for one search, read fresh each turn like
  /// [depthSelector]. Null lets the search run to full depth however long
  /// that takes — fine in tests, not on a player's turn.
  final Duration? Function()? budgetSelector;

  /// Optional: probability (0..1) of playing a random legal move instead of
  /// the searcher's best move. Sampled fresh per turn.
  final double Function()? blunderChanceSelector;

  /// Optional endgame tablebase provider. Read fresh on every move so the
  /// player picks up the tablebase as soon as background generation
  /// finishes — without rebuilding the player or restarting the game.
  /// Returns null until the TB is ready; in that case the searcher falls
  /// back to normal alpha-beta.
  final Tablebase? Function()? tablebaseSelector;

  /// Optional opening-book provider, read fresh each move so the book can
  /// arrive after the game has started.
  final OpeningBook? Function()? bookSelector;

  /// Optional learned-evaluator provider (Phase 3). Same lifecycle pattern
  /// as [tablebaseSelector]: returns null until the TFLite model finishes
  /// loading, at which point subsequent moves use the NN at leaf nodes.
  final NnueEvaluator? Function()? nnueSelector;

  /// Hard wall-clock cap on a single search. When exceeded, the search
  /// isolate is killed (a true stop — not just an abandoned Future) and
  /// [selectMove] resolves to null so the game loop can recover. Null
  /// disables the cap; primarily useful in tests.
  final Duration? searchTimeout;

  final Random _random;

  /// The long-lived search isolate, and the port it listens on.
  ///
  /// Kept alive between moves so the searcher — and with it the
  /// transposition table — survives. Measured over 24 plies at depth 6:
  /// 1,928,828 nodes and 432ms per move with a fresh table each time
  /// against 1,350,282 nodes and 329ms with one carried across. The
  /// opponent's reply almost always lands inside a subtree the previous
  /// search already explored, so starting empty throws that away.
  Isolate? _isolate;
  SendPort? _toIsolate;
  ReceivePort? _fromIsolate;
  Completer<Move?>? _pendingSearch;

  /// The tablebase already sent across. Compared by identity: it is 2MB, it
  /// arrives once when background generation finishes, and re-sending it on
  /// every move would undo part of what keeping the isolate alive buys.
  Tablebase? _sentTablebase;
  NnueEvaluator? _sentNnue;
  OpeningBook? _sentBook;

  Future<bool> _ensureIsolate() async {
    if (_toIsolate != null) return true;
    final handshake = ReceivePort();
    try {
      _isolate = await Isolate.spawn<SendPort>(
        _searchIsolateMain,
        handshake.sendPort,
        debugName: 'chaturang-ai-search',
      );
    } catch (e) {
      developer.log('AI search isolate failed to spawn: $e', name: 'AiPlayer');
      handshake.close();
      return false;
    }
    final ready = ReceivePort();
    _fromIsolate = ready;
    _toIsolate = await handshake.first as SendPort;
    handshake.close();
    ready.listen((message) {
      final pending = _pendingSearch;
      if (pending != null && !pending.isCompleted) {
        pending.complete(message as Move?);
      }
    });
    _toIsolate!.send(ready.sendPort);
    return true;
  }

  /// Tears the isolate down. Called on timeout — a search that overran has
  /// left the isolate busy, and the table it was building is not worth
  /// waiting for — and from [dispose].
  void _teardown() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _toIsolate = null;
    _fromIsolate?.close();
    _fromIsolate = null;
    _sentTablebase = null;
    _sentNnue = null;
    _sentBook = null;
  }

  /// Releases the search isolate. Safe to call more than once.
  Future<void> dispose() async {
    final pending = _pendingSearch;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    _pendingSearch = null;
    _teardown();
  }

  @override
  Future<Move?> selectMove(Board board) async {
    final blunderChance = blunderChanceSelector?.call() ?? 0.0;
    if (blunderChance > 0 && _random.nextDouble() < blunderChance) {
      final moves = MoveGenerator.legalMoves(board);
      if (moves.isEmpty) return null;
      return moves[_random.nextInt(moves.length)];
    }
    if (!await _ensureIsolate()) return null;

    final tb = tablebaseSelector?.call();
    final nnue = nnueSelector?.call();
    final bk = bookSelector?.call();
    final sendBook = !identical(bk, _sentBook);
    _sentBook = bk;
    final sendTb = !identical(tb, _sentTablebase);
    final sendNnue = !identical(nnue, _sentNnue);
    _sentTablebase = tb;
    _sentNnue = nnue;

    final completer = Completer<Move?>();
    _pendingSearch = completer;
    _toIsolate!.send(
      _SearchRequest(
        board,
        depthSelector(),
        budgetSelector?.call(),
        sendTb ? tb : null,
        sendNnue ? nnue : null,
        sendBook ? bk : null,
        updateTablebase: sendTb,
        updateNnue: sendNnue,
        updateBook: sendBook,
      ),
    );

    Timer? timeoutTimer;
    if (searchTimeout != null) {
      timeoutTimer = Timer(searchTimeout!, () {
        if (completer.isCompleted) return;
        developer.log(
          'AI search exceeded ${searchTimeout!.inSeconds}s — killing isolate.',
          name: 'AiPlayer',
        );
        // The isolate is wedged in a search; it cannot answer, so take it
        // down and start clean next move.
        _teardown();
        completer.complete(null);
      });
    }

    try {
      return await completer.future;
    } finally {
      timeoutTimer?.cancel();
      if (identical(_pendingSearch, completer)) _pendingSearch = null;
    }
  }
}

/// Payload handed to the search isolate. Board / Move / Piece / Square /
/// Tablebase / NnueEvaluator are all plain data and cross by copy.
///
/// [tablebase] and [nnue] are sent only when they change — the tablebase is
/// 2MB and arrives exactly once, so copying it every move would give back
/// part of what the persistent isolate buys.
class _SearchRequest {
  const _SearchRequest(
    this.board,
    this.depth,
    this.budget,
    this.tablebase,
    this.nnue,
    this.book, {
    required this.updateTablebase,
    required this.updateNnue,
    required this.updateBook,
  });

  final Board board;
  final int depth;
  final Duration? budget;
  final Tablebase? tablebase;
  final NnueEvaluator? nnue;
  final OpeningBook? book;
  final bool updateTablebase;
  final bool updateNnue;
  final bool updateBook;
}

/// Search-isolate entrypoint. Lives for as long as the player does, holding
/// one [Searcher] so its transposition table carries across moves.
void _searchIsolateMain(SendPort handshake) {
  final requests = ReceivePort();
  handshake.send(requests.sendPort);

  SendPort? replyTo;
  Tablebase? tablebase;
  NnueEvaluator? nnue;
  OpeningBook? book;
  Searcher? searcher;

  requests.listen((message) {
    if (message is SendPort) {
      replyTo = message;
      return;
    }
    final req = message as _SearchRequest;
    // A changed tablebase or evaluator means a new Searcher, and so a new
    // table: entries scored under a different evaluation are not comparable.
    if (req.updateTablebase || req.updateNnue || req.updateBook) {
      if (req.updateTablebase) tablebase = req.tablebase;
      if (req.updateNnue) nnue = req.nnue;
      if (req.updateBook) book = req.book;
      searcher = null;
    }
    searcher ??= Searcher(
      tablebase: tablebase,
      nnue: nnue,
      book: book,
      options: const SearchOptions(reuseTable: true),
    );
    final result = searcher!.search(
      req.board,
      depth: req.depth,
      budget: req.budget,
    );
    replyTo?.send(result.move);
  });
}
