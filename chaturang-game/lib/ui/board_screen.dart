import 'dart:async';
import '../engine/hint.dart';
import '../web_bridge.dart';

import 'package:flutter/material.dart';

import '../audio/audio_service.dart';
import '../data/ads_service.dart';
import '../data/game_preferences.dart';
import '../data/online/game_snapshot.dart';
import '../data/online/online_config.dart';
import '../data/online/online_player.dart';
import '../data/rate_service.dart';
import '../data/stats_service.dart';
import 'move_list_modal.dart';
import '../engine/board.dart';
import '../data/difficulty_preference.dart';
import '../engine/difficulty.dart';
import '../engine/game_state.dart';
import '../engine/move.dart';
import '../engine/move_generator.dart';
import '../engine/move_limit.dart';
import '../engine/pieces.dart';
import '../engine/player.dart';
import '../engine/searcher.dart';
import '../engine/square.dart';
import '../main.dart' show openingBookNotifier, tablebaseNotifier;
import 'about_modal.dart';
import 'board_widget.dart';
import 'court_home.dart';
import 'full_game_sheet.dart';
import '../data/game_access.dart';
import 'confirmation_modal.dart';
import 'game_over_modal.dart';
import 'ornamented_board.dart';
import 'rules_screen.dart';
import 'settings_modal.dart';
import 'stats_modal.dart';
import 'store_modal.dart';
import 'theme.dart';
import 'more_games.dart';

/// Hosts a single game's board state and the tap-based interaction handler.
/// The human plays [humanSide]; the AI plays the opposite side. Defaults
/// to White-for-human when no side is passed (useful for tests and
/// stand-alone use).
class BoardScreen extends StatefulWidget {
  const BoardScreen({
    super.key,
    this.humanSide = Side.white,
    this.onlineConfig,
  });

  final Side humanSide;

  /// When non-null, BoardScreen runs in online multiplayer mode: the
  /// opponent is an [OnlinePlayer] driven by the snapshot stream, local
  /// moves are submitted to Firebase, and terminal states come from the
  /// network (opponent forfeit, etc.). Local-only behavior — AI search,
  /// difficulty selection, move-limit draws, single-device stats — is
  /// either bypassed or deferred to a future polish commit.
  final OnlineConfig? onlineConfig;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final Board _board = Board();
  Square? _selected;
  List<Move> _candidates = const [];

  /// The move that was just played, used to trigger the slide animation in
  /// [OrnamentedBoard]/[BoardWidget]. Compared by instance identity, so
  /// every makeMove must produce a fresh reference (which it does — moves
  /// come from a regenerated candidates list each tap).
  Move? _justMoved;

  /// Set when the game ends by player action (forfeit / draw by agreement),
  /// since those outcomes aren't derivable from the board itself. When
  /// non-null, overrides whatever [GameResult.of] would compute.
  GameResult? _terminalOverride;

  /// True when this screen is hosting an online multiplayer game (i.e.
  /// [BoardScreen.onlineConfig] is non-null). Cached for terse use at
  /// callsites; the source of truth is still `widget.onlineConfig`.
  bool get _isOnline => widget.onlineConfig != null;

  /// The side the local human plays. In AI mode this is whatever the
  /// caller passed; in online mode it's derived from the host-color
  /// assignment in the initial snapshot.
  late final Side _localSide = widget.onlineConfig?.myColor ?? widget.humanSide;

  /// Human plays [_localSide]; the opponent slot is either the local
  /// [AiPlayer] (offline) or an [OnlinePlayer] driven by the snapshot
  /// stream (online). Exactly one of the two is non-null.
  late final HumanPlayer _humanPlayer = HumanPlayer(side: _localSide);
  late final AiPlayer? _aiPlayer = _isOnline
      ? null
      : AiPlayer(
          side: _localSide.opposite,
          depthSelector: () => _difficulty.value.searchDepth,
          budgetSelector: () => _difficulty.value.searchBudget,
          blunderChanceSelector: () => _difficulty.value.blunderChance,
          tablebaseSelector: () => tablebaseNotifier.value,
          bookSelector: () => openingBookNotifier.value,
        );
  OnlinePlayer? _onlinePlayer;

  /// Live snapshot stream for the online room. Same broadcast instance
  /// is read by both [_onlinePlayer] (for opponent moves) and
  /// [_statusSub] (for terminal-state propagation). Null in AI mode.
  Stream<GameSnapshot>? _snapshotStream;
  StreamSubscription<GameSnapshot>? _statusSub;

  /// Local copy of the room's seq counter — what the next outgoing
  /// `submitMove` will set. Both opponent moves (via [_onlinePlayer])
  /// and our own moves (via [_submitOnlineMove]) advance it in lockstep.
  int _currentSeq = 0;

  /// Server-timestamp (ms since epoch) of the opponent's most recent
  /// heartbeat. Updated whenever a snapshot delivers a fresh value.
  /// The staleness check compares this against local now() — local
  /// clock skew is small relative to our 60s grace window, so the
  /// approximation is good enough.
  int? _opponentLastHeartbeatMs;

  /// Periodic write of our own heartbeat field (every 15s while
  /// active). Cancelled in dispose and on terminal state.
  Timer? _heartbeatTimer;

  /// Periodic check of the opponent's heartbeat staleness (every 5s
  /// while active). When the gap crosses 60s, declares an opponent
  /// timeout via the service.
  Timer? _opponentStaleTimer;

  /// Set true once we've declared an opponent timeout, so the staleness
  /// timer doesn't keep retrying or the UI from showing a misleading
  /// disconnect strip after the game-over modal opens.
  bool _opponentTimeoutDeclared = false;

  static const Duration _heartbeatInterval = Duration(seconds: 15);
  // 1s so the status-strip countdown ticks visibly (was 5s, which made
  // the 'Opponent silent — Xs' label appear frozen between ticks).
  static const Duration _staleCheckInterval = Duration(seconds: 1);
  static const Duration _opponentGrace = Duration(seconds: 60);

  Player _playerFor(Side side) {
    if (side == _humanPlayer.side) return _humanPlayer;
    return _onlinePlayer ?? _aiPlayer!;
  }

  /// True while [AiPlayer.selectMove] is awaiting a result. Drives the
  /// "Black is thinking" status and disables user controls.
  bool _isAiThinking = false;
  bool _isAiAnimating = false;
  bool _latestHumanMoveCanBeUndone = false;

  // A take-back belongs to the human: remove their last move and its reply.
  // In particular, an AI-White opening is not a human move to take back.
  bool get _canUndo =>
      _latestHumanMoveCanBeUndone &&
      !_isOnline &&
      !_isAiThinking &&
      !_isAiAnimating &&
      !_currentResult.isTerminal &&
      _board.sideToMove == _humanPlayer.side &&
      _board.plyCount >= 2;

  void _onMoveAnimationComplete(Move move) {
    if (mounted && _isAiAnimating && identical(move, _justMoved)) {
      setState(() => _isAiAnimating = false);
    }
  }

  /// Used to invalidate in-flight player requests when the game is reset /
  /// forfeit / etc. — incremented on every state-disrupting action so
  /// stale [_advanceTurn] calls can detect they should drop their result.
  int _turnGeneration = 0;

  // Preferences belong to the app, so home-screen choices apply to games.
  final ValueNotifier<Difficulty> _difficulty = DifficultyPreference.instance;
  final ValueNotifier<bool> _soundEnabled = GamePreferences.soundEnabled;
  final ValueNotifier<bool> _timedMode = GamePreferences.timedMode;
  final ValueNotifier<MoveLimit> _moveLimit = GamePreferences.moveLimit;

  // ----- Clock state (used only when _timedMode is true). -----
  /// Per-side time control. 5 minutes is a casual blitz feel; future work
  /// may make this configurable.
  static const Duration _initialTime = Duration(minutes: 5);
  Duration _whiteTime = _initialTime;
  Duration _blackTime = _initialTime;

  /// One-second ticker that drains the active side's clock. Null when the
  /// clock isn't running (timed mode off, game terminal, etc.).
  Timer? _clockTicker;

  /// True once the current game has been recorded to StatsService. Reset
  /// on game restart. Prevents double-counting when terminal state is
  /// reached from multiple code paths (game loop, forfeit, timeout, etc.).
  bool _statsRecorded = false;
  bool _hasPlayed = false;

  /// Wall-clock start of the current game, for the elapsed-time readout
  /// in the game-over modal. Reset on every restart.
  DateTime _gameStartedAt = DateTime.now();

  /// Elapsed game time, frozen when the game first reaches a terminal
  /// state. Null until then.
  Duration? _gameElapsed;

  /// True once the game-over modal has been shown (or deliberately
  /// suppressed) for the current game. Reset on restart.
  bool _gameOverShown = false;

  bool _hintAdCredit = false;
  bool _hintBusy = false;
  bool _admitted = false;
  bool _admitting = false;

  Future<bool> _admitMatch() async {
    if (_admitting) return false;
    _admitting = true;
    try {
      if (_isOnline) {
        await GameAccess.instance.acknowledgeOnlineAdmission();
        return true;
      }
      GameAccess.instance.endMatch();
      if (!await checkGameAccess(context) || !mounted) return false;
      return await GameAccess.instance.startMatch();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start this game. Please try again.'),
          ),
        );
      }
      return false;
    } finally {
      _admitting = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final allowed = await _admitMatch();
      if (!mounted) return;
      if (!allowed) {
        if (_isOnline) {
          unawaited(
            widget.onlineConfig!.service.submitForfeit(
              widget.onlineConfig!.roomCode,
            ),
          );
        }
        _goToCardPick();
        return;
      }
      setState(() => _admitted = true);
      _initializeMatch();
    });
  }

  void _initializeMatch() {
    // Toggle clock infrastructure on/off when the user flips timed mode.
    _timedMode.addListener(_onTimedModeChanged);
    if (_timedMode.value) _startClockTicker();

    // Online setup: subscribe to the room's snapshot stream once and
    // share it between [_onlinePlayer] (consumes opponent moves) and
    // [_statusSub] (watches for terminal status). Both attach to the
    // same broadcast stream so we don't open two listeners on Firebase.
    if (_isOnline) {
      final cfg = widget.onlineConfig!;
      _currentSeq = cfg.initialSnapshot.seq;
      _snapshotStream = cfg.service.watchGame(cfg.roomCode).asBroadcastStream();
      _onlinePlayer = OnlinePlayer(
        side: _localSide.opposite,
        snapshotStream: _snapshotStream!,
        initialSeq: _currentSeq,
      );
      _statusSub = _snapshotStream!.listen(_onOnlineSnapshot);
      // Heartbeat + staleness detection. Write our own pulse every
      // 15s; check the opponent's pulse every 5s. Fire one heartbeat
      // immediately so the opponent sees us alive without waiting a
      // full interval.
      unawaited(cfg.service.heartbeat(cfg.roomCode, cfg.myRole));
      _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
        if (!mounted) return;
        if (_currentResult.isTerminal) return;
        unawaited(cfg.service.heartbeat(cfg.roomCode, cfg.myRole));
      });
      _opponentStaleTimer = Timer.periodic(_staleCheckInterval, (_) {
        if (!mounted) return;
        _checkOpponentStaleness();
      });
      // Once the screen is mounted, show the courtesy "here's your
      // color" dialog. Blocking (barrierDismissible: false) so the
      // player has to acknowledge before the board becomes interactive.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showOnlineStartDialog();
      });
    }

    // Kick off the game loop after the first frame. White is up first;
    // whoever plays white (could be the local human, the AI, or the
    // remote opponent) is the player whose selectMove fires first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _advanceTurn());

    // Shared-vault housekeeping, once per launch, and never during an
    // online game — a modal sheet over a live board would stall a match
    // the opponent is still playing.
    if (!_isOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _settleVault());
    }
  }

  /// Finishes any transfer left half-done, then offers whatever is waiting.
  ///
  /// Order matters: settle first, ask second. Replaying a pending bank can
  /// change what the vault holds, so prompting before that could offer a
  /// figure that is already wrong by the time the player taps.
  ///
  /// Every step here is failure-tolerant by design. None of it refunds,
  /// none of it withdraws without a tap, and anything that does not
  /// resolve is simply left for the next launch.
  Future<void> _settleVault() async {}

  @override
  void dispose() {
    GameAccess.instance.endMatch();
    _stopClockTicker();
    _timedMode.removeListener(_onTimedModeChanged);
    _humanPlayer.cancel();
    // Releases the long-lived search isolate. Without this it outlives the
    // screen, holding its transposition table for a game nobody is playing.
    unawaited(_aiPlayer?.dispose() ?? Future.value());
    _heartbeatTimer?.cancel();
    _opponentStaleTimer?.cancel();
    unawaited(_statusSub?.cancel() ?? Future.value());
    unawaited(_onlinePlayer?.dispose() ?? Future.value());
    // _difficulty is the app-wide preference, not ours to dispose.
    // Shared game preferences outlive this board.
    super.dispose();
  }

  void _onTimedModeChanged() {
    if (_timedMode.value) {
      // Turning timed mode on mid-game resets the clocks and starts the
      // active side draining immediately. Documented in the Settings
      // toggle so users don't get surprised.
      setState(() {
        _whiteTime = _initialTime;
        _blackTime = _initialTime;
      });
      if (!_currentResult.isTerminal) _startClockTicker();
    } else {
      _stopClockTicker();
    }
  }

  void _startClockTicker() {
    _clockTicker?.cancel();
    _clockTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickClock(),
    );
  }

  void _stopClockTicker() {
    _clockTicker?.cancel();
    _clockTicker = null;
  }

  void _tickClock() {
    if (!mounted) return;
    if (_currentResult.isTerminal) {
      _stopClockTicker();
      return;
    }
    var newlyTerminal = false;
    setState(() {
      final side = _board.sideToMove;
      if (side == Side.white) {
        _whiteTime -= const Duration(seconds: 1);
        if (_whiteTime <= Duration.zero) {
          _whiteTime = Duration.zero;
          _terminalOverride = const Timeout(winner: Side.black);
          _stopClockTicker();
          _humanPlayer.cancel();
          // Releases the long-lived search isolate. Without this it outlives the
          // screen, holding its transposition table for a game nobody is playing.
          unawaited(_aiPlayer?.dispose() ?? Future.value());
          _turnGeneration++;
          newlyTerminal = true;
        }
      } else {
        _blackTime -= const Duration(seconds: 1);
        if (_blackTime <= Duration.zero) {
          _blackTime = Duration.zero;
          _terminalOverride = const Timeout(winner: Side.white);
          _stopClockTicker();
          _humanPlayer.cancel();
          // Releases the long-lived search isolate. Without this it outlives the
          // screen, holding its transposition table for a game nobody is playing.
          unawaited(_aiPlayer?.dispose() ?? Future.value());
          _turnGeneration++;
          newlyTerminal = true;
        }
      }
    });
    if (newlyTerminal) _maybeRecordGame();
  }

  GameResult get _currentResult => _terminalOverride ?? GameResult.of(_board);

  /// Records the current terminal result to [StatsService] exactly once
  /// per game. Safe to call from any terminal-setting code path (natural
  /// checkmate, forfeit, draw-by-agreement, timeout, restart-mid-game).
  void _maybeRecordGame() {
    if (_statsRecorded) return;
    final result = _currentResult;
    if (!result.isTerminal) return;
    _statsRecorded = true;
    if (_hasPlayed) reportGameAction(true);
    // Freeze the elapsed-time readout at the moment play actually ended,
    // so the game-over modal shows the duration of the game, not how
    // long the modal sat open.
    _gameElapsed ??= DateTime.now().difference(_gameStartedAt);
    // Single funnel for every terminal path (checkmate, stalemate, forfeit,
    // draw, timeout, move-limit). Checkmate already played its own dramatic
    // tone via _playMoveOutcomeSound; everything else gets the gameEnd tone.
    if (result is! Checkmate) {
      AudioService.instance.play(Sound.gameEnd);
    }
    if (_isOnline) {
      // Online games go into the dedicated W-L-D counters only — no
      // coins, no streak bump, no difficulty-unlock progression
      // (online wins against random humans aren't comparable to AI
      // wins). The rate-prompt also isn't fired on online wins for
      // now; it lives on the AI-mode flow where we have a more
      // controlled definition of "the player just had a satisfying
      // moment."
      unawaited(
        StatsService.instance.recordOnlineGame(
          result: result,
          localSide: _localSide,
        ),
      );
    } else {
      // recordGame is async (it awaits load() before mutating), so chain
      // the rate-prompt onto it — gamesWon must be incremented before
      // RateService reads it.
      final humanWon = switch (result) {
        Checkmate(:final winner) => winner == _localSide,
        Forfeit(:final winner) => winner == _localSide,
        Timeout(:final winner) => winner == _localSide,
        _ => false,
      };
      unawaited(() async {
        await StatsService.instance.recordGame(
          result: result,
          humanSide: _localSide,
          difficulty: _difficulty.value,
        );
        if (humanWon) {
          await RateService.instance.maybeRequestAfterWin();
        }
      }());
    }
    _maybeShowGameOver();
  }

  /// Shows the end-of-game modal exactly once per game, on the frame
  /// after the game reaches a terminal state. "Rematch" routes through
  /// the same access-checked restart path as the Reset button.
  /// Reset / Quit suppress the modal by pre-setting [_gameOverShown],
  /// since those flows navigate away rather than dwell on the result.
  void _maybeShowGameOver() {
    if (_gameOverShown) return;
    final result = _currentResult;
    if (!result.isTerminal) return;
    _gameOverShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final rematch = await showGameOverModal(
        context,
        result: result,
        humanSide: _localSide,
        fullMoves: (_board.plyCount + 1) ~/ 2,
        elapsed: _gameElapsed ?? DateTime.now().difference(_gameStartedAt),
        opponentLabel: _isOnline ? 'your opponent' : 'the AI',
        // Rematch isn't supported online in v1 (would need a
        // coordinated fresh-room flow). The modal hides the Rematch
        // button and shows just 'Done' instead of 'View board'.
        allowRematch: !_isOnline,
        // When the opponent is a real human (online play), wins via
        // their disconnect OR explicit forfeit get muted 'Game ended'
        // framing rather than the celebratory 'Victory' — the player
        // didn't out-play them, they just stayed connected.
        opponentIsHuman: _isOnline,
        // End-of-game move history viewer. Stacks above the game-over
        // dialog so dismissing the move list returns to the outcome
        // dialog rather than the board behind it.
        onViewMoves: () =>
            showMoveListModal(context, moves: _board.moveHistory),
      );
      if (!mounted || !rematch) return;
      if (!mounted) return;
      _restartBoard();
    });
  }

  /// One-time "you play X" courtesy dialog shown when both players
  /// first land on the board. Blocking (barrier non-dismissible) so the
  /// player has to acknowledge before the board accepts taps — useful
  /// for surfacing the random color assignment, since otherwise the
  /// joiner would just see "your pieces are on this side" and have to
  /// figure it out from the board layout.
  Future<void> _showOnlineStartDialog() async {
    final myColorName = _localSide == Side.white ? 'White' : 'Black';
    final oppColorName = _localSide == Side.white ? 'Black' : 'White';
    final whiteMovesFirst = _localSide == Side.white
        ? "You move first."
        : "$oppColorName moves first.";
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChaturangTheme.deepMaroon,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: ChaturangTheme.saffronLight.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        title: Text(
          'Room ready',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'RoyalSans',
            color: ChaturangTheme.saffronLight,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'You play $myColorName',
              style: TextStyle(
                fontFamily: 'RoyalSans',
                color: ChaturangTheme.parchment,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Opponent plays $oppColorName',
              style: TextStyle(
                fontFamily: 'RoyalSans',
                color: ChaturangTheme.secondaryText,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              whiteMovesFirst,
              style: TextStyle(
                fontFamily: 'RoyalSans',
                color: ChaturangTheme.saffronLight,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              backgroundColor: ChaturangTheme.saffronLight.withValues(
                alpha: 0.15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: ChaturangTheme.saffronLight.withValues(alpha: 0.7),
                ),
              ),
            ),
            child: Text(
              'Begin',
              style: TextStyle(
                fontFamily: 'RoyalSans',
                color: ChaturangTheme.parchment,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles snapshot updates from the room while we're playing online.
  /// Tracks the seq for outgoing submitMove, refreshes the opponent's
  /// heartbeat timestamp for the staleness check, and converts a
  /// remote terminal status into the matching local [GameResult] so
  /// the rest of the screen (game-over modal, stats funnel) reacts
  /// uniformly.
  void _onOnlineSnapshot(GameSnapshot snap) {
    if (snap.seq > _currentSeq) _currentSeq = snap.seq;

    // Track opponent's heartbeat. Only advance if it actually moved
    // forward — our own writes to the doc echo back as snapshots, and
    // those don't change the opponent's field. Triggers a rebuild so
    // the status strip can recompute freshness.
    final cfg = widget.onlineConfig;
    if (cfg != null) {
      final opponentHb = snap.opponentHeartbeatFor(cfg.myRole);
      if (opponentHb != null &&
          (_opponentLastHeartbeatMs == null ||
              opponentHb > _opponentLastHeartbeatMs!)) {
        if (mounted) {
          setState(() => _opponentLastHeartbeatMs = opponentHb);
        }
      }
    }

    if (snap.status == GameStatus.ended && _terminalOverride == null) {
      _humanPlayer.cancel();
      // Releases the long-lived search isolate. Without this it outlives the
      // screen, holding its transposition table for a game nobody is playing.
      unawaited(_aiPlayer?.dispose() ?? Future.value());
      _onlinePlayer?.cancel();
      _heartbeatTimer?.cancel();
      _opponentStaleTimer?.cancel();
      _turnGeneration++;
      if (!mounted) return;
      setState(() {
        _terminalOverride = _mapTerminalResult(snap.terminalResult);
        _selected = null;
        _candidates = const [];
      });
      _maybeRecordGame();
    }
  }

  /// Checks how long it's been since the opponent's last heartbeat.
  /// If it exceeds [_opponentGrace] (60s), writes the matching timeout
  /// terminal result so both clients converge on game-over. Otherwise
  /// just calls setState to rebuild the status strip's countdown.
  void _checkOpponentStaleness() {
    if (_opponentTimeoutDeclared) return;
    if (_currentResult.isTerminal) return;
    final cfg = widget.onlineConfig;
    if (cfg == null) return;
    final lastHb = _opponentLastHeartbeatMs;
    // No heartbeat yet means the opponent hasn't pinged once — they
    // may have just joined and haven't fired their first pulse. Don't
    // panic until the grace window has elapsed since *game start*; for
    // simplicity we treat 'no heartbeat at all' as not stale.
    if (lastHb == null) return;
    final ageMs = DateTime.now().millisecondsSinceEpoch - lastHb;
    if (ageMs > _opponentGrace.inMilliseconds) {
      _opponentTimeoutDeclared = true;
      final opponentRole = cfg.myRole == PlayerRole.host
          ? PlayerRole.joiner
          : PlayerRole.host;
      unawaited(cfg.service.declareOpponentTimeout(cfg.roomCode, opponentRole));
      _opponentStaleTimer?.cancel();
      // Don't apply terminal state locally — wait for the snapshot
      // listener to pick up the status:ended write we just made. That
      // keeps both clients on a single code path for end-of-game.
    } else {
      // Rebuild so the status strip's countdown ticks down visually.
      if (mounted) setState(() {});
    }
  }

  /// Maps the wire-level [TerminalResult] to one of the existing
  /// in-app [GameResult] subtypes so the game-over UI doesn't need to
  /// know online play exists. Protocol-error and the "draw" sentinel
  /// land on `DrawByAgreement` for v1 — refine once we have richer
  /// terminal-result rendering.
  GameResult _mapTerminalResult(TerminalResult? tr) {
    final cfg = widget.onlineConfig!;
    final hostSide = (cfg.initialSnapshot.hostColorIsWhite ?? true)
        ? Side.white
        : Side.black;
    final joinerSide = hostSide.opposite;
    return switch (tr) {
      TerminalResult.hostWin => Forfeit(winner: hostSide),
      TerminalResult.joinerWin => Forfeit(winner: joinerSide),
      TerminalResult.draw => const DrawByAgreement(),
      TerminalResult.hostForfeit => Forfeit(winner: joinerSide),
      TerminalResult.joinerForfeit => Forfeit(winner: hostSide),
      TerminalResult.hostTimeout => Timeout(winner: joinerSide),
      TerminalResult.joinerTimeout => Timeout(winner: hostSide),
      TerminalResult.protocolError => const DrawByAgreement(),
      null => const DrawByAgreement(),
    };
  }

  /// Pushes a freshly-applied local move into Firebase so the opponent
  /// sees it. Bumps [_currentSeq] and acks the new seq on the
  /// [OnlinePlayer] *before* awaiting the network write — the Firebase
  /// echo could land before submitMove's await returns, and we don't
  /// want to mistake our own move's snapshot for an opponent move.
  Future<void> _submitOnlineMove(Move move) async {
    final cfg = widget.onlineConfig!;
    final newSeq = _currentSeq + 1;
    _currentSeq = newSeq;
    _onlinePlayer?.ackLocalMove(newSeq);
    try {
      await cfg.service.submitMove(
        cfg.roomCode,
        GameSnapshot(
          hostUid: cfg.initialSnapshot.hostUid,
          joinerUid: cfg.initialSnapshot.joinerUid,
          // v1: `fen` stays pinned to the opening position. The wire
          // protocol drives state via `lastMoveAlgebraic`; receivers
          // do not parse this field. Reserved for future reconnect
          // support — see BACKLOG.md.
          fen: cfg.initialSnapshot.fen,
          lastMoveAlgebraic: encodeUciMove(move),
          seq: newSeq,
          status: GameStatus.active,
          createdAt: cfg.initialSnapshot.createdAt,
          hostColorIsWhite: cfg.initialSnapshot.hostColorIsWhite,
        ),
      );
    } catch (e) {
      debugPrint('Online submitMove failed: $e');
      // For v1 we don't retry. If the divergence is permanent the
      // opponent's local validation will fail and the game ends via
      // the protocol_error path.
    }
  }

  /// Single step of the game loop: ask the side-to-move's player for a
  /// move, then apply it and recurse. Tolerates being called multiple
  /// times — uses [_turnGeneration] to bail out if the state was disrupted
  /// while we were awaiting a player.
  Future<void> _advanceTurn() async {
    if (!mounted) return;
    if (_currentResult.isTerminal) {
      _maybeRecordGame();
      return;
    }

    final currentSide = _board.sideToMove;
    final player = _playerFor(currentSide);
    final myGen = _turnGeneration;
    final isAi = player is AiPlayer;

    if (isAi) {
      setState(() => _isAiThinking = true);
    }

    // AI gets a hard timeout so a stuck isolate can't strand the UI.
    // The human player MUST NOT have one — humans can take as long as
    // they want to make a move (reading the board, opening Settings,
    // watching a rewarded ad, etc.), and a timeout here would silently
    // drop their tap into an orphaned Completer. The cancel paths
    // (forfeit / restart / quit / undo) are what abort a pending
    // human move.
    // Let the previous piece finish its flight even when an opening-book
    // or shallow AI reply is instant. Search runs during this interval.
    final motionReady =
        isAi && _justMoved != null && !MediaQuery.disableAnimationsOf(context)
        ? Future<void>.delayed(const Duration(milliseconds: 450))
        : Future<void>.value();
    Move? move;
    try {
      if (isAi) {
        move = await player
            .selectMove(_board)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                debugPrint('AI selectMove exceeded 30s budget — recovering.');
                return null;
              },
            );
        await motionReady;
      } else {
        move = await player.selectMove(_board);
      }
    } finally {
      // Make sure the "thinking…" indicator is cleared once selectMove
      // resolves (or times out) no matter what. The actual move
      // application below is guarded by the standard cancellation
      // checks.
      if (mounted && isAi && myGen == _turnGeneration) {
        setState(() => _isAiThinking = false);
      }
    }

    // Bail out if we were cancelled, the screen is gone, or the board
    // state has moved on since we started waiting.
    if (!mounted) return;
    if (myGen != _turnGeneration) return;
    final chosen = move;
    if (chosen == null || _board.sideToMove != currentSide) return;

    setState(() {
      _board.makeMove(chosen);
      if (!isAi) {
        _hasPlayed = true;
        reportGameAction(false);
      }
      if (!isAi) _latestHumanMoveCanBeUndone = true;
      _justMoved = chosen;
      _isAiAnimating = isAi && !MediaQuery.disableAnimationsOf(context);
      _selected = null;
      _candidates = const [];
      _isAiThinking = false;
      // Move-limit enforcement. Checks here (after a move increments
      // plyCount) before _advanceTurn evaluates terminal state, so the
      // status text flips to "Move limit reached" immediately and the
      // result is recorded in stats as a draw.
      final limit = _moveLimit.value;
      if (limit != MoveLimit.unlimited &&
          _board.plyCount >= limit.maxPlies &&
          _terminalOverride == null) {
        _terminalOverride = const MoveLimitDraw();
      }
    });
    _playMoveOutcomeSound();

    // Online: if the move we just applied came from the local human,
    // push it to Firebase so the opponent's [OnlinePlayer] sees it.
    // Echoes (snapshots Firebase sends back to us) are filtered by the
    // ackLocalMove(newSeq) call inside [_submitOnlineMove].
    if (_isOnline && currentSide == _humanPlayer.side) {
      unawaited(_submitOnlineMove(chosen));
    }

    // Natural-end check (checkmate / stalemate / move-limit). Forfeit /
    // Draw / Timeout sites call _maybeRecordGame directly.
    _maybeRecordGame();

    // Continue to the next turn (no-op if we just ended on move limit).
    unawaited(_advanceTurn());
  }

  void _handleTap(Square square) {
    if (_currentResult.isTerminal) return;
    if (_isAiThinking || _isAiAnimating) return; // Wait for the full AI turn.
    if (_board.sideToMove != _humanPlayer.side) return;

    if (_selected != null) {
      final move = _candidates.where((m) => m.to == square).firstOrNull;
      if (move != null) {
        // Hand the move off to the game loop via the HumanPlayer's pending
        // future; _advanceTurn picks it up, applies it, and continues.
        setState(() {
          _selected = null;
          _candidates = const [];
        });
        _humanPlayer.submitMove(move);
        return;
      }
    }

    final piece = _board.pieceAt(square);
    if (piece != null && piece.side == _board.sideToMove) {
      setState(() {
        _selected = square;
        _candidates = MoveGenerator.legalMovesFrom(_board, square);
      });
    } else if (_selected != null) {
      // A piece was selected and the tap landed on a square that is neither
      // a legal destination nor another of the player's own pieces — an
      // invalid target. Give audible feedback and clear the selection.
      AudioService.instance.play(Sound.illegal);
      setState(() {
        _selected = null;
        _candidates = const [];
      });
    }
  }

  /// Picks the right sound based on the position AFTER the just-played move:
  /// - Checkmate → dramatic checkmate tone
  /// - Check (game ongoing but king attacked) → temple-bell alarm
  /// - Otherwise → ordinary move click
  void _playMoveOutcomeSound() {
    final result = GameResult.of(_board);
    // Stalemate (the only terminal GameResult.of can return besides
    // Checkmate) is intentionally left to _maybeRecordGame's gameEnd tone,
    // so a drawing move doesn't play an ordinary move click.
    final sound = switch (result) {
      Checkmate() => Sound.checkmate,
      Ongoing(inCheck: true) => Sound.check,
      Ongoing(inCheck: false) => Sound.move,
      _ => null,
    };
    if (sound != null) AudioService.instance.play(sound);
  }

  void _undo() {
    if (!_canUndo) return;
    AudioService.instance.play(Sound.undo);
    _turnGeneration++;
    _humanPlayer.cancel();
    setState(() {
      _latestHumanMoveCanBeUndone = false;
      // Eligibility guarantees a completed human move and AI reply.
      // Leave the AI's first White move intact when the human plays Black.
      _board.undoMove();
      _board.undoMove();
      _justMoved = null;
      _isAiAnimating = false;
      _selected = null;
      _candidates = const [];
    });
    unawaited(_advanceTurn());
  }

  /// Forfeit the current game. [loser] is the side conceding; they lose.
  /// Called by the Forfeit action button and by Reset/Quit when the game is
  /// still active.
  void _forfeit(Side loser) {
    _turnGeneration++;
    _humanPlayer.cancel();
    // Releases the long-lived search isolate. Without this it outlives the
    // screen, holding its transposition table for a game nobody is playing.
    unawaited(_aiPlayer?.dispose() ?? Future.value());
    _onlinePlayer?.cancel();
    setState(() {
      _terminalOverride = Forfeit(winner: loser.opposite);
      _selected = null;
      _candidates = const [];
      _isAiThinking = false;
    });
    // Online: tell the room we forfeited. The opponent's snapshot
    // listener picks up the resulting status:ended write and ends
    // their game with the matching Forfeit terminal state.
    if (_isOnline && loser == _humanPlayer.side) {
      final cfg = widget.onlineConfig!;
      unawaited(cfg.service.submitForfeit(cfg.roomCode));
    }
    _maybeRecordGame();
  }

  /// Offer a draw — auto-accepted as a placeholder until the AI accepts /
  /// rejects based on its eval in step 4.
  void _offerDraw() {
    _turnGeneration++;
    _humanPlayer.cancel();
    // Releases the long-lived search isolate. Without this it outlives the
    // screen, holding its transposition table for a game nobody is playing.
    unawaited(_aiPlayer?.dispose() ?? Future.value());
    setState(() {
      _terminalOverride = const DrawByAgreement();
      _selected = null;
      _candidates = const [];
      _isAiThinking = false;
    });
    _maybeRecordGame();
  }

  /// Restart the board to the opening position and kick off a fresh game
  /// loop.
  Future<void> _restartBoard() async {
    _clockTicker?.cancel();
    _humanPlayer.cancel();
    _turnGeneration++;
    await _aiPlayer?.dispose();
    final sound = AudioService.instance.enabled;
    AudioService.instance.enabled = false;
    try {
      await betweenGames();
    } finally {
      AudioService.instance.enabled = sound;
    }
    if (!await _admitMatch() || !mounted) return;
    _turnGeneration++;
    _humanPlayer.cancel();
    // Releases the long-lived search isolate. Without this it outlives the
    // screen, holding its transposition table for a game nobody is playing.
    unawaited(_aiPlayer?.dispose() ?? Future.value());
    setState(() {
      _board.setupInitial();
      _latestHumanMoveCanBeUndone = false;
      _selected = null;
      _candidates = const [];
      _terminalOverride = null;
      _justMoved = null;
      _isAiAnimating = false;
      _isAiThinking = false;
      _whiteTime = _initialTime;
      _blackTime = _initialTime;
      _statsRecorded = false;
      _hasPlayed = false;
      _gameStartedAt = DateTime.now();
      _gameElapsed = null;
      _gameOverShown = false;
      _hintAdCredit = false;
    });
    if (_timedMode.value) _startClockTicker();
    unawaited(_advanceTurn());
  }

  /// Called by the Forfeit action button.
  Future<void> _onForfeitPressed() async {
    if (_currentResult.isTerminal) return;
    // The hot-seat side that's about to move is the one forfeiting (whoever
    // is at the controls when the button is hit). When AI lands, this becomes
    // "the human player forfeits", regardless of side to move.
    final loser = _localSide;
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Forfeit the game?',
      message:
          '${_sideName(loser)} will lose. This will count as a loss in your '
          'stats when stat tracking lands.',
      cancelLabel: 'Keep playing',
      confirmLabel: 'Forfeit',
      destructive: true,
    );
    if (confirmed) _forfeit(loser);
  }

  /// Called by the Offer Draw action button.
  Future<void> _onOfferDrawPressed() async {
    if (_currentResult.isTerminal) return;
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Offer a draw?',
      message:
          'The AI will weigh the position and accept or decline. '
          '(Until that judgement lands, offers are auto-accepted.)',
      cancelLabel: 'Cancel',
      confirmLabel: 'Offer Draw',
    );
    if (confirmed) _offerDraw();
  }

  /// Reset to a fresh opening position. If the game is active, requires
  /// forfeit confirmation first (counts as a loss). After a naturally
  /// completed game, the next match goes through the access gate.
  Future<void> _onResetPressed() async {
    if (_currentResult.isTerminal) {
      if (!mounted) return;
      _restartBoard();
      return;
    }
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Restart the game?',
      message:
          'You are still playing. Restarting now will count as a forfeit '
          '(loss) for ${_sideName(_localSide)}.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Restart',
      destructive: true,
    );
    if (!mounted || !confirmed) return;
    // Reset navigates away from the result, so suppress the game-over
    // modal that the forfeit would otherwise trigger.
    _gameOverShown = true;
    _forfeit(_localSide);
    if (!mounted) return;
    _restartBoard();
  }

  /// Exit the current game and return to the card-pick screen so the
  /// player can choose a side for a fresh game. Forfeits if the game is
  /// still active. Different from Reset, which restarts on the same
  /// screen keeping the current colors.
  Future<void> _onQuitPressed() async {
    if (_currentResult.isTerminal) {
      if (!mounted) return;
      _goToCardPick();
      return;
    }
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Quit to start screen?',
      message:
          'You are still playing. Quitting now will count as a forfeit '
          '(loss) for ${_sideName(_localSide)}, and you will be '
          'taken back to the side-pick screen.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Quit',
      destructive: true,
    );
    if (!mounted || !confirmed) return;
    // Quit navigates away from the result, so suppress the game-over modal.
    _gameOverShown = true;
    _forfeit(_localSide);
    if (!mounted) return;
    _goToCardPick();
  }

  /// Replaces the current BoardScreen with a fresh CardPickScreen so the
  /// player can choose colors again. Uses pushReplacement so we don't
  /// accumulate a navigation stack across quit/resume cycles.
  void _goToCardPick() {
    if (!mounted) return;
    GameAccess.instance.endMatch();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CourtHome()),
      (_) => false,
    );
  }

  /// Runs the searcher on a background isolate at a fixed Medium depth
  /// and visually selects the recommended piece + destination on the
  /// board. The user can tap the highlighted destination to play it, or
  /// pick a different move — the hint is advisory.
  Future<void> _onHintPressed() async {
    if (_hintBusy) return;
    _hintBusy = true;
    try {
      await _showHint();
    } finally {
      _hintBusy = false;
    }
  }

  Future<void> _showHint() async {
    if (_currentResult.isTerminal) return;
    if (_isAiThinking || _isAiAnimating) return;
    if (_board.sideToMove != _humanPlayer.side) return;

    // Paid matches include hints. Free/bonus matches can use loyalty coins
    // or explicitly watch an ad; a completed hint ad never mints store coins.
    const cost = CoinCosts.hint;
    var chargeCoins = false;
    if (!GameAccess.instance.freeHints && !_hintAdCredit) {
      final choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Get a hint'),
          children: [
            SimpleDialogOption(
              onPressed: StatsService.instance.coins >= cost
                  ? () => Navigator.pop(dialogContext, 'coins')
                  : null,
              child: Text(
                'Use $cost coins · ${StatsService.instance.coins} available',
              ),
            ),
            if (GameAccess.instance.adsAllowed)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, 'ad'),
                child: const Text('Watch an ad for 1 hint'),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Not now'),
            ),
          ],
        ),
      );
      if (!mounted || choice == null) return;
      if (choice == 'coins') {
        chargeCoins = true;
      } else {
        // Watching a requested hint ad must not use up the player's clock.
        // Hints exist only in AI games; online clocks are never paused here.
        final pauseClock =
            !_isOnline && _timedMode.value && _clockTicker != null;
        if (pauseClock) _stopClockTicker();
        try {
          _hintAdCredit = await AdsService.instance.requestRewarded(coins: 0);
        } finally {
          if (mounted && pauseClock && !_currentResult.isTerminal) {
            _startClockTicker();
          }
        }
        if (!mounted) return;
        if (!_hintAdCredit) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ad not completed or unavailable. No coins were spent.',
              ),
            ),
          );
          return;
        }
      }
    }
    // IMPORTANT: run the search first, then charge. If the search
    // returns null (timeout, terminal position, etc.) we don't want
    // the user to lose coins for nothing.
    //
    // Search dispatch goes through a top-level helper. We can't put
    // Isolate.run inline here because the async state machine for
    // _onHintPressed would capture `this` (so it can refer to
    // _selected / _candidates / _isAiThinking later), and `this`
    // contains _humanPlayer which holds an unsendable Completer.
    // Top-level helper isolates the closure's lexical scope from
    // _BoardScreenState entirely.
    setState(() => _isAiThinking = true);
    final board = _board;
    final myGen = _turnGeneration;
    var result = const SearchResult(move: null, score: 0, nodes: 0);
    try {
      result = await _runHintSearchInIsolate(board).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Hint search exceeded 15s budget; aborting.');
          return const SearchResult(move: null, score: 0, nodes: 0);
        },
      );
    } catch (e, st) {
      debugPrint('Hint search failed: $e\n$st');
    } finally {
      if (mounted && myGen == _turnGeneration) {
        setState(() => _isAiThinking = false);
      }
    }
    if (!mounted) return;
    if (myGen != _turnGeneration) return;

    final move = result.move;
    if (move == null) {
      // Search failed (timeout, terminal, or no legal moves). Don't
      // charge — the user got nothing. Tell them via a snackbar so
      // they aren't left wondering whether they did something wrong
      // or whether coins were taken.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ChaturangTheme.charcoal,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Hint unavailable — try again. No coins were charged.',
            style: TextStyle(
              fontFamily: 'RoyalSans',
              color: ChaturangTheme.parchment,
              fontSize: 14,
            ),
          ),
        ),
      );
      return;
    }
    if (_board.sideToMove != _humanPlayer.side) return;

    // Only now do we charge coins — we have a hint to show.
    final spent =
        !chargeCoins ||
        GameAccess.instance.freeHints ||
        await StatsService.instance.spendCoins(cost);
    if (!mounted || !spent) return;
    _hintAdCredit = false;

    setState(() {
      _selected = move.from;
      // Only the recommended destination is highlighted, so the hint
      // is unambiguous. The user can still tap a different square to
      // pick their own move — re-tapping the piece reopens the full
      // legal-destination set.
      _candidates = [move];
    });
  }

  String _statusText(GameResult result) {
    if (_isAiThinking) {
      return '${_sideName(_board.sideToMove)} is thinking…';
    }
    return switch (result) {
      Checkmate(:final winner) => 'Checkmate — ${_sideName(winner)} wins',
      Stalemate() => 'Stalemate — Draw',
      Forfeit(:final winner) => 'Forfeit — ${_sideName(winner)} wins',
      Timeout(:final winner) => 'Out of time — ${_sideName(winner)} wins',
      DrawByAgreement() => 'Draw by agreement',
      MoveLimitDraw() => 'Move limit reached — Draw',
      RepetitionDraw() => 'Threefold repetition — Draw',
      InsufficientMaterial() => 'Not enough material — Draw',
      Ongoing(inCheck: true) =>
        '${_sideName(_board.sideToMove)} to move — Check',
      Ongoing(inCheck: false) => '${_sideName(_board.sideToMove)} to move',
    };
  }

  String _sideName(Side side) => side == Side.white ? 'White' : 'Black';

  /// The pedestal's last-move readout, e.g. "last move: a7 → a6". Null at
  /// game start and after an undo (when there is no move to show).

  @override
  Widget build(BuildContext context) {
    if (!_admitted) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final result = _currentResult;
    final destinations = _candidates.map((m) => m.to).toSet();
    final gameActive = !result.isTerminal;

    Widget playerBar(Side side) => _PlayerInfoBar(
      side: side,
      label: side == _localSide ? 'You' : (_isOnline ? 'Opponent' : 'Court AI'),
      captured: _board.capturedBy(side),
      remainingTime: _timedMode.value
          ? (side == Side.white ? _whiteTime : _blackTime)
          : null,
      active: gameActive && _board.sideToMove == side,
    );
    final actions = <String, VoidCallback?>{
      'Moves': () => showMoveListModal(context, moves: _board.moveHistory),
      'Rules': () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RulesScreen())),
      'Settings': () => showSettingsSheet(
        context,
        difficulty: _difficulty,
        soundEnabled: _soundEnabled,
        timedMode: _timedMode,
        moveLimit: _moveLimit,
      ),
      'Stats': () => showStatsSheet(context),
      'Restart': _isOnline ? null : _onResetPressed,
      'Draw': (!_isOnline && gameActive && !_isAiThinking)
          ? _onOfferDrawPressed
          : null,
      'Forfeit': gameActive && !_isAiThinking ? _onForfeitPressed : null,
      'More games': () => showMoreGames(context),
      'About': () => showAboutSheet(context),
    };
    return Scaffold(
      backgroundColor: const Color(0xFF102526),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: viewport.maxHeight,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 52,
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Quit',
                              onPressed: _onQuitPressed,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const Expanded(
                              child: Text(
                                'CHATURANG',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'RoyalSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  color: ChaturangTheme.primaryText,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Game options',
                              icon: const Icon(Icons.more_horiz_rounded),
                              onSelected: (value) => actions[value]?.call(),
                              itemBuilder: (_) => [
                                for (final entry in actions.entries)
                                  PopupMenuItem(
                                    value: entry.key,
                                    enabled: entry.value != null,
                                    child: Text(entry.key),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_isOnline)
                        _OnlineStatusStrip(
                          opponentHeartbeatMs: _opponentLastHeartbeatMs,
                          graceMs: _opponentGrace.inMilliseconds,
                          gameOver: result.isTerminal,
                          localSide: _localSide,
                        ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Keep the player rails attached to the board, centered as a group.
                            // On short displays the board yields height without clipping controls.
                            final stageHeight =
                                (constraints.maxHeight -
                                        98 -
                                        MediaQuery.textScalerOf(
                                          context,
                                        ).scale(20))
                                    .clamp(0.0, constraints.maxWidth * 1.04);
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  playerBar(_localSide.opposite),
                                  SizedBox(
                                    height: stageHeight,
                                    child: OrnamentedBoard(
                                      board: _board,
                                      justMoved: _justMoved,
                                      onMoveAnimationComplete:
                                          _onMoveAnimationComplete,
                                      selected: _selected,
                                      legalDestinations: destinations,
                                      onTapSquare: _handleTap,
                                      flipped: _localSide == Side.black,
                                    ),
                                  ),
                                  playerBar(_localSide),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _statusText(result),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: ChaturangTheme.primaryText,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Move ${(_board.plyCount ~/ 2) + 1}'
                                          '${_moveLimit.value == MoveLimit.unlimited ? '' : ' / ${_moveLimit.value.fullMoves}'}',
                                          style: const TextStyle(
                                            color: ChaturangTheme.secondaryText,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Row(
                          children: [
                            _ActionTile(
                              icon: Icons.undo,
                              label: 'Undo',
                              onPressed: _canUndo ? _undo : null,
                            ),
                            _ActionTile(
                              icon: Icons.lightbulb_outline,
                              label: 'Hint',
                              onPressed:
                                  !_isOnline &&
                                      gameActive &&
                                      !_isAiThinking &&
                                      !_isAiAnimating &&
                                      _board.sideToMove == _humanPlayer.side
                                  ? _onHintPressed
                                  : null,
                            ),
                            _ActionTile(
                              icon: Icons.storefront,
                              label: 'Store',
                              onPressed: () => showStoreSheet(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const MoreGamesSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact player identity, captured material, and an optional live clock.
class _PlayerInfoBar extends StatelessWidget {
  const _PlayerInfoBar({
    required this.side,
    required this.label,
    required this.captured,
    this.remainingTime,
    required this.active,
  });
  final Side side;
  final String label;
  final List<Piece> captured;
  final Duration? remainingTime;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final seconds = (remainingTime?.inSeconds ?? 0).clamp(0, 86400);
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: side == Side.white
                    ? const Color(0xFFF4E8CD)
                    : const Color(0xFF253331),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB5AA91)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: ChaturangTheme.primaryText,
                fontFamily: 'RoyalSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _CapturedRow(pieces: captured),
              ),
            ),
            if (active)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.circle,
                  size: 7,
                  color: ChaturangTheme.saffronLight,
                ),
              ),
            if (remainingTime != null)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: active
                        ? ChaturangTheme.saffronLight
                        : ChaturangTheme.primaryText,
                    fontFamily: 'RoyalSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Grouped row of captured-piece icons with multiplier badges.
/// Ordered by descending material value (rook → pawn) for predictable layout.
class _CapturedRow extends StatelessWidget {
  const _CapturedRow({required this.pieces});

  final List<Piece> pieces;

  static const List<PieceType> _order = [
    PieceType.rook,
    PieceType.knight,
    PieceType.elephant,
    PieceType.counsellor,
    PieceType.pawn,
    PieceType.king,
  ];

  @override
  Widget build(BuildContext context) {
    final counts = <PieceType, int>{};
    for (final piece in pieces) {
      counts[piece.type] = (counts[piece.type] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    final pieceSide = pieces.first.side;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        for (final type in _order)
          if (counts.containsKey(type))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                pieceCapturedIcon(Piece(type, pieceSide), size: 28),
                if (counts[type]! > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 1),
                    child: Text(
                      '×${counts[type]}',
                      style: TextStyle(
                        fontFamily: 'RoyalSans',
                        color: ChaturangTheme.parchment,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
      ],
    );
  }
}

/// Primary game action with a full-width share of the three-control row.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled
        ? ChaturangTheme.parchment
        : ChaturangTheme.parchment.withValues(alpha: 0.40);
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'RoyalSans',
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top-level wrapper for the hint search dispatch.
///
/// Must NOT live inside _BoardScreenState. Dart's async state-machine
/// compilation captures `this` for any closure in an async method (so
/// the body can resume reading instance fields after awaits). That
/// `this` transitively pulls in `_humanPlayer`, which holds an
/// unsendable `Completer _pending` — and Isolate.run rejects the
/// closure at runtime with "Illegal argument in isolate message".
///
/// By extracting to a top-level function, the only thing the inner
/// closure can capture is the `board` parameter, which is sendable.
/// AiPlayer.selectMove works for the same reason — its `this`
/// (AiPlayer) has no unsendable fields.
Future<SearchResult> _runHintSearchInIsolate(Board board) => webHint(board);

/// Slim connection-state pill rendered above the board in online
/// games. Three states driven by the time since the opponent's last
/// heartbeat:
///   * green — opponent fresh (< 30s)
///   * amber — opponent silent, grace countdown ticking (30..60s)
///   * red — opponent timed out / never sent a heartbeat after grace
///
/// Hidden when [gameOver] is true: the game-over modal carries the
/// terminal-state messaging from that point on; the strip would just
/// add noise.
class _OnlineStatusStrip extends StatelessWidget {
  const _OnlineStatusStrip({
    required this.opponentHeartbeatMs,
    required this.graceMs,
    required this.gameOver,
    required this.localSide,
  });

  final int? opponentHeartbeatMs;
  final int graceMs;
  final bool gameOver;
  final Side localSide;

  @override
  Widget build(BuildContext context) {
    if (gameOver) return const SizedBox.shrink();

    final Color dot;
    final String connState;
    final hb = opponentHeartbeatMs;
    if (hb == null) {
      dot = const Color(0xFFD9A441); // amber-ish saffron
      connState = 'Connecting…';
    } else {
      final ageMs = DateTime.now().millisecondsSinceEpoch - hb;
      if (ageMs < graceMs ~/ 2) {
        dot = const Color(0xFF6BB26B); // green
        connState = 'Opponent online';
      } else if (ageMs < graceMs) {
        final remaining = ((graceMs - ageMs) / 1000).ceil();
        dot = const Color(0xFFD9A441); // amber
        connState = 'Opponent silent — ${remaining}s';
      } else {
        dot = const Color(0xFFD96B6B); // red
        connState = 'Opponent timed out';
      }
    }
    // Persistent "you are playing X" reminder so the player doesn't
    // have to remember from the opening dialog. A small colored square
    // (white or black) is more glanceable than the word; the label
    // before it just reads 'You are playing:'.
    final isWhite = localSide == Side.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ChaturangTheme.deepMaroon.withValues(alpha: 0.55),
          border: Border.all(color: dot.withValues(alpha: 0.7), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              connState,
              style: TextStyle(
                color: ChaturangTheme.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '·',
              style: TextStyle(
                color: ChaturangTheme.secondaryText,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'You are playing:',
              style: TextStyle(
                color: ChaturangTheme.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            // Small filled square in the player's actual color. Borders
            // are picked so each square stays clearly visible against
            // the dark deepMaroon strip background.
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isWhite ? Colors.white : Colors.black,
                border: Border.all(
                  color: isWhite
                      ? Colors.black.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.55),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
