import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../engine/board.dart';
import '../../engine/move.dart';
import '../../engine/move_generator.dart';
import '../../engine/pieces.dart';
import '../../engine/player.dart';
import '../../engine/square.dart';
import 'game_snapshot.dart';

/// Network-driven [Player]. Plugs into [BoardScreen]'s existing game
/// loop in the same slot an [AiPlayer] would, but instead of running a
/// search, [selectMove] waits for the opponent's move to arrive over
/// the [GameSnapshot] stream and returns it.
///
/// **Key responsibility:** distinguish opponent moves from echoes of
/// our own moves. Firebase's realtime listener replays every write —
/// including ours — back to us. The seq counter is what disambiguates:
/// the local-move site bumps `_lastSeqAcked` immediately after writing,
/// so the echo (same seq) is filtered. The next genuine opponent
/// snapshot has a strictly greater seq and gets returned.
class OnlinePlayer implements Player {
  OnlinePlayer({
    required this.side,
    required Stream<GameSnapshot> snapshotStream,
    required int initialSeq,
  }) : _lastSeqAcked = initialSeq {
    _subscription = snapshotStream.listen(
      _onSnapshot,
      onError: (Object e) {
        debugPrint('OnlinePlayer stream error: $e');
        _resolvePending(null);
      },
    );
  }

  @override
  final Side side;

  late final StreamSubscription<GameSnapshot> _subscription;

  /// Highest seq the local board has incorporated. Updated either by
  /// receiving an opponent's move OR by [ackLocalMove] after the local
  /// human plays. Both paths converge on the same seq counter so the
  /// echo of a local move (same seq) never tricks selectMove.
  int _lastSeqAcked;

  /// The latest unconsumed snapshot containing an opponent move we
  /// haven't yet delivered to the game loop. Cleared in selectMove.
  GameSnapshot? _stashedMoveSnapshot;

  /// Pending future from a selectMove call. Resolved either by a new
  /// opponent-move snapshot or by terminal-status / cancellation.
  Completer<GameSnapshot?>? _pending;

  /// Whether the game has ended via a terminal snapshot status. Once
  /// true, all selectMove calls resolve to null immediately so the
  /// game loop can record the terminal state and exit.
  bool _ended = false;

  /// Most recent snapshot observed — surfaced via [latestSnapshot] for
  /// the UI to read (e.g. opponent connection status, terminal result).
  GameSnapshot? _latest;
  GameSnapshot? get latestSnapshot => _latest;

  void _onSnapshot(GameSnapshot snap) {
    _latest = snap;

    if (snap.status == GameStatus.ended) {
      _ended = true;
      _resolvePending(snap);
      return;
    }

    // Filter out echoes of our own move (same seq) and old snapshots
    // we've already incorporated.
    if (snap.seq <= _lastSeqAcked) return;
    if (snap.lastMoveAlgebraic == null) return;

    // Genuine opponent move. Resolve any pending selectMove, or stash
    // for the next call.
    if (_pending != null && !_pending!.isCompleted) {
      _resolvePending(snap);
    } else {
      _stashedMoveSnapshot = snap;
    }
  }

  void _resolvePending(GameSnapshot? snap) {
    final p = _pending;
    if (p != null && !p.isCompleted) {
      _pending = null;
      p.complete(snap);
    }
  }

  /// Called by the local game loop after a move that originated from
  /// our side has been applied and submitted to Firebase. Bumps the
  /// seq counter so the inevitable Firebase echo isn't mistaken for an
  /// opponent move.
  void ackLocalMove(int newSeq) {
    if (newSeq > _lastSeqAcked) _lastSeqAcked = newSeq;
    // Drop any stash that's been superseded (shouldn't normally
    // happen, but defensive against races).
    final stash = _stashedMoveSnapshot;
    if (stash != null && stash.seq <= _lastSeqAcked) {
      _stashedMoveSnapshot = null;
    }
  }

  @override
  Future<Move?> selectMove(Board board) async {
    if (_ended) return null;

    // If we already have an opponent move waiting, return it now.
    final stash = _stashedMoveSnapshot;
    if (stash != null && stash.seq > _lastSeqAcked) {
      _lastSeqAcked = stash.seq;
      _stashedMoveSnapshot = null;
      return parseUciMove(stash.lastMoveAlgebraic!, board);
    }

    // Otherwise wait for the next opponent-move snapshot (or terminal).
    _pending = Completer<GameSnapshot?>();
    final snap = await _pending!.future;
    if (snap == null) return null;
    if (snap.status == GameStatus.ended) return null;

    _lastSeqAcked = snap.seq;
    return parseUciMove(snap.lastMoveAlgebraic!, board);
  }

  /// Cancels any pending selectMove. Called by BoardScreen on screen
  /// teardown / forfeit / disconnect.
  void cancel() {
    _resolvePending(null);
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    cancel();
  }
}

/// Parses a UCI-style move string ("e2e4", "a7a8q") against [board] and
/// returns the matching legal [Move]. Returns null on any malformed or
/// illegal input — the caller (game loop) treats null as "opponent did
/// something we can't replicate locally" and ends the game with a
/// protocol-error terminal state.
///
/// Promotion handling is currently best-effort — we look at the
/// trailing letter (q/r/b/n) and match against [PieceType] by first
/// letter. If we can't match, we drop the promotion and trust the
/// legal-move list to pick a sane default (typically queen).
@visibleForTesting
Move? parseUciMove(String uci, Board board) {
  if (uci.length < 4 || uci.length > 5) return null;
  Square from;
  Square to;
  try {
    from = Square.algebraic(uci.substring(0, 2));
    to = Square.algebraic(uci.substring(2, 4));
  } catch (_) {
    return null;
  }
  final promoChar = uci.length == 5 ? uci[4].toLowerCase() : null;

  // Resolve to one of the engine's legal moves so we get the exact
  // instance (with promotion/capture flags) the engine recognizes.
  final candidates = MoveGenerator.legalMovesFrom(
    board,
    from,
  ).where((m) => m.to == to);
  if (candidates.isEmpty) return null;

  if (promoChar != null) {
    final byPromo = candidates.where(
      (m) => m.promotion != null && _pieceLetter(m.promotion!) == promoChar,
    );
    if (byPromo.isNotEmpty) return byPromo.first;
  }

  return candidates.first;
}

/// Encodes [move] as a UCI-style string for transport over the wire.
/// Inverse of [parseUciMove]; round-trip stable for non-promotion moves.
String encodeUciMove(Move move) {
  final base = '${move.from.algebraic}${move.to.algebraic}';
  final promo = move.promotion;
  if (promo == null) return base;
  return '$base${_pieceLetter(promo)}';
}

String _pieceLetter(PieceType type) {
  // First character of the enum name, lowercased — works for the
  // standard promotion targets (queen, rook, bishop, knight) and is
  // forgiving on the parse side.
  return type.name.substring(0, 1).toLowerCase();
}
