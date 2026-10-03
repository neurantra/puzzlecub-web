import 'dart:async';
import 'dart:math';

import 'board.dart';
import 'move.dart';
import 'move_generator.dart';
import 'nnue.dart';
import 'opening_book.dart';
import 'pieces.dart';
import 'worker_client.dart';
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

// The mobile searcher runs in a persistent browser worker, preserving its TT.
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
  final int Function() depthSelector;
  final Duration? Function()? budgetSelector;
  final double Function()? blunderChanceSelector;
  final Tablebase? Function()? tablebaseSelector;
  final OpeningBook? Function()? bookSelector;
  final NnueEvaluator? Function()? nnueSelector;
  final Duration? searchTimeout;
  final Random _random;
  var _worker = WorkerSearch();
  @override
  Future<Move?> selectMove(Board board) async {
    final legal = MoveGenerator.legalMoves(board);
    if (legal.isEmpty) return null;
    if (_random.nextDouble() < (blunderChanceSelector?.call() ?? 0)) {
      return legal[_random.nextInt(legal.length)];
    }
    final result = await _worker.search(
      board,
      depth: depthSelector(),
      budget: budgetSelector?.call(),
    );
    // Failed workers recover with a legal move instead of stranding the board.
    return legal.contains(result.move)
        ? result.move
        : legal[_random.nextInt(legal.length)];
  }

  Future<void> dispose() async {
    _worker.dispose();
    _worker = WorkerSearch();
  }
}
