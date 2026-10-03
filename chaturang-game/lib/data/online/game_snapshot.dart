// Network-side game state stored at `/games/<roomCode>` in Firebase.
//
// This is the wire format — what flies over the network — not the
// in-app game-state object. The board screen converts a GameSnapshot
// into the existing Board + GameResult types at the boundary. Keeping
// a dedicated network type means we can change the Firebase schema
// without touching the engine, and vice versa.

/// Lifecycle of a multiplayer game.
enum GameStatus {
  /// Host has created the room. No joiner yet. Joiner can claim by
  /// writing their uid into [GameSnapshot.joinerUid].
  waiting,

  /// Both players are in. Moves can be submitted. The `seq` counter
  /// advances on each move.
  active,

  /// Game has reached a terminal state. [GameSnapshot.terminalResult]
  /// describes how it ended.
  ended,
}

/// All possible ways a multiplayer game can finish. Translated to/from
/// the in-app `GameResult` at the boundary.
enum TerminalResult {
  hostWin,
  joinerWin,
  draw,
  hostForfeit,
  joinerForfeit,
  hostTimeout,
  joinerTimeout,

  /// Local engine validation rejected a move written by the opponent.
  /// Either a genuine protocol bug or tampering — both rare; we just
  /// end the game and let players start a new room.
  protocolError,
}

/// Which side of the network conversation the local player is on.
/// Distinct from `Side.white`/`Side.black` — color is assigned by the
/// server on join, so a player's *role* (host/joiner) is stable across
/// reconnects while their *color* is decided once at game start.
enum PlayerRole { host, joiner }

/// One full game-state snapshot. Snapshots are written **per move**,
/// fully replacing the prior snapshot at `/games/<code>`.
///
/// **v1 schema reality**: a reconnecting client cannot yet rebuild the
/// position from this snapshot alone — [fen] is the opening position
/// for the lifetime of the room, and there is no move-log path. Live
/// gameplay relies on each client tracking the engine locally and
/// applying [lastMoveAlgebraic] as deltas. Mid-game resume / future
/// server-side validation will require shipping a real Board↔FEN
/// serializer and writing the current FEN per move; see BACKLOG.md.
///
/// The schema is deliberately small (~150 bytes) to keep Firebase
/// bandwidth and quota near-free at our scale.
class GameSnapshot {
  const GameSnapshot({
    required this.hostUid,
    this.joinerUid,
    required this.fen,
    this.lastMoveAlgebraic,
    required this.seq,
    this.hostClockMs,
    this.joinerClockMs,
    required this.status,
    this.terminalResult,
    required this.createdAt,
    this.hostColorIsWhite,
    this.hostLastHeartbeat,
    this.joinerLastHeartbeat,
  });

  /// Anonymous Firebase Auth uid of the player who created the room.
  /// Stable across reconnects.
  final String hostUid;

  /// Anonymous uid of the joiner. Null while [status] is [GameStatus.waiting].
  final String? joinerUid;

  /// Position in Forsyth-Edwards Notation. In v1 this is always the
  /// opening position — the wire format is move-stream based, and
  /// there is no Board↔FEN serializer yet. The field is kept on the
  /// wire to reserve the slot for a future reconnect/resume path
  /// (tracked in BACKLOG.md). Receivers should treat it as opaque.
  final String fen;

  /// The move that produced [fen], encoded as a from-to string (e.g.
  /// `"e2e4"`) plus optional promotion suffix. Null on the very first
  /// snapshot (no move yet — opening position).
  final String? lastMoveAlgebraic;

  /// Monotonic move counter, starting at 0 for the opening snapshot
  /// and incrementing by 1 on every move. Writes must include
  /// `seq = priorSeq + 1`; otherwise the write is rejected
  /// (optimistic concurrency).
  final int seq;

  /// Remaining clock time for the host in milliseconds. Null when the
  /// game is untimed.
  final int? hostClockMs;
  final int? joinerClockMs;

  final GameStatus status;

  /// Set only when [status] is [GameStatus.ended].
  final TerminalResult? terminalResult;

  /// Server timestamp (ms since epoch) when the host created the room.
  /// Used for the 24-hour TTL cleanup.
  final int createdAt;

  /// True if the host plays white. Assigned server-randomly when the
  /// joiner first writes their uid. Null while [status] is
  /// [GameStatus.waiting].
  final bool? hostColorIsWhite;

  /// Server-timestamp (ms since epoch) of the host's most recent
  /// heartbeat. The opponent reads this to detect disconnects — if it
  /// stops advancing for >60s, the opponent declares a timeout. Null
  /// before the first heartbeat is written.
  final int? hostLastHeartbeat;
  final int? joinerLastHeartbeat;

  /// Convenience: which uid is whose role.
  PlayerRole? roleOf(String uid) {
    if (uid == hostUid) return PlayerRole.host;
    if (uid == joinerUid) return PlayerRole.joiner;
    return null;
  }

  /// The opponent's heartbeat timestamp from the caller's perspective.
  /// Pass [myRole] (the local player's role) and get back the field
  /// the *opponent* is responsible for writing. Used in the staleness
  /// check that drives disconnect detection.
  int? opponentHeartbeatFor(PlayerRole myRole) =>
      myRole == PlayerRole.host ? joinerLastHeartbeat : hostLastHeartbeat;

  /// Serializes for `set`/`update` against Firebase RTDB. Null fields
  /// are omitted so they don't overwrite existing data with null.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'hostUid': hostUid,
    if (joinerUid != null) 'joinerUid': joinerUid,
    'fen': fen,
    if (lastMoveAlgebraic != null) 'lastMoveAlgebraic': lastMoveAlgebraic,
    'seq': seq,
    if (hostClockMs != null) 'hostClockMs': hostClockMs,
    if (joinerClockMs != null) 'joinerClockMs': joinerClockMs,
    'status': status.name,
    if (terminalResult != null) 'terminalResult': terminalResult!.name,
    'createdAt': createdAt,
    if (hostColorIsWhite != null) 'hostColorIsWhite': hostColorIsWhite,
    if (hostLastHeartbeat != null) 'hostLastHeartbeat': hostLastHeartbeat,
    if (joinerLastHeartbeat != null) 'joinerLastHeartbeat': joinerLastHeartbeat,
  };

  /// Parses a Firebase snapshot value. Tolerates missing optional
  /// fields and unknown enum cases (treats them as null / waiting).
  /// Throws [FormatException] on missing required fields, which would
  /// indicate a corrupted document or a schema migration bug.
  factory GameSnapshot.fromJson(Map<dynamic, dynamic> json) {
    String require(String key) {
      final v = json[key];
      if (v == null) {
        throw FormatException('GameSnapshot missing required field: $key');
      }
      return v.toString();
    }

    return GameSnapshot(
      hostUid: require('hostUid'),
      joinerUid: json['joinerUid']?.toString(),
      fen: require('fen'),
      lastMoveAlgebraic: json['lastMoveAlgebraic']?.toString(),
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      hostClockMs: (json['hostClockMs'] as num?)?.toInt(),
      joinerClockMs: (json['joinerClockMs'] as num?)?.toInt(),
      status: GameStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => GameStatus.waiting,
      ),
      terminalResult: json['terminalResult'] == null
          ? null
          : TerminalResult.values.firstWhere(
              (r) => r.name == json['terminalResult'],
              orElse: () => TerminalResult.protocolError,
            ),
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      hostColorIsWhite: json['hostColorIsWhite'] as bool?,
      hostLastHeartbeat: (json['hostLastHeartbeat'] as num?)?.toInt(),
      joinerLastHeartbeat: (json['joinerLastHeartbeat'] as num?)?.toInt(),
    );
  }
}
