import 'game_snapshot.dart';

/// Vendor-neutral contract for online multiplayer.
///
/// The Firebase implementation ([FirebaseOnlinePlayService], added in a
/// later commit) is the only piece that touches `firebase_*` packages.
/// The rest of the app — board UI, lobby screens, stats wiring — talks
/// exclusively to this interface. That separation is the entire point:
/// if we ever swap to Supabase, a custom WebSocket server, or WebRTC,
/// only the impl changes. See [[chaturang-online-play]] for the
/// architecture rationale.
///
/// Lifecycle from the caller's perspective:
///   1. Call [ensureAuthenticated] once at app start. Returns the
///      anonymous Firebase Auth uid; persistent across launches.
///   2. Host: [createGame] returns a [GameSnapshot] with a fresh
///      [GameSnapshot.fen] in [GameStatus.waiting]. The room code is
///      derivable from the listener path the caller subscribes to —
///      see the impl for how it surfaces it (likely via a wrapper
///      record `(String code, GameSnapshot snapshot)`).
///   3. Joiner: [joinGame] with the code. Throws
///      [RoomNotFoundException] / [RoomFullException] /
///      [NotAuthorizedException] as appropriate. On success, status
///      advances to [GameStatus.active].
///   4. Both: subscribe to [watchGame] for live updates.
///   5. On your move: [submitMove] with the new snapshot
///      (seq = priorSeq + 1, updated fen / lastMove). The Firebase
///      write is conditional on seq advancement; concurrent writes
///      fail loudly rather than silently overwrite.
///   6. On a forfeit/quit: [submitForfeit].
///   7. Every ~15s while in [GameStatus.active]: [heartbeat], so the
///      opponent's grace-window logic can detect disconnects.
///   8. When leaving the screen / done: [leaveGame].
abstract interface class OnlinePlayService {
  /// Anonymous Firebase Auth uid for the local player. Stable across
  /// launches. Null until [ensureAuthenticated] has resolved.
  String? get uid;

  /// Signs in anonymously to Firebase Auth if not already. Idempotent.
  /// Returns the uid. Safe to call on every app start.
  Future<String> ensureAuthenticated();

  /// Creates a new room. Returns the initial snapshot in
  /// [GameStatus.waiting], paired with the freshly-generated room
  /// code. The impl reserves the code via a conditional write — on
  /// the astronomically rare collision it retries with a new code.
  Future<({String code, GameSnapshot snapshot})> createGame();

  /// Claims an existing waiting room. Throws on any failure to
  /// distinguish "wrong code" from "room already full" in the UI.
  /// Returns the updated snapshot ([GameStatus.active], both uids
  /// populated, color assigned).
  Future<GameSnapshot> joinGame(String code);

  /// Live stream of snapshots for the given room. Emits the current
  /// value immediately on subscribe, then a new value on every
  /// remote write. Completes when the document is deleted (e.g. by
  /// TTL cleanup); errors on permission failure or network loss.
  Stream<GameSnapshot> watchGame(String code);

  /// Writes [next] as the new snapshot for [code]. Caller is
  /// responsible for ensuring `next.seq == prior.seq + 1` and that the
  /// fen / lastMove reflect a legal move. The impl performs the write
  /// conditionally — if seq has already advanced (opponent's move
  /// crossed in flight), throws [SequenceConflictException] and the
  /// caller should resync from the next [watchGame] event.
  Future<void> submitMove(String code, GameSnapshot next);

  /// Ends the game by forfeit. Sets [GameStatus.ended] and the
  /// appropriate [TerminalResult] based on the caller's role.
  Future<void> submitForfeit(String code);

  /// Writes a fresh server-timestamp into [GameSnapshot.hostLastHeartbeat]
  /// or [GameSnapshot.joinerLastHeartbeat] depending on [myRole]. Should
  /// be called periodically (~15s) by the local game loop while the
  /// game is active. The opponent reads the field in their snapshots
  /// and declares a timeout when it stops advancing.
  Future<void> heartbeat(String code, PlayerRole myRole);

  /// Marks the room as ended because the opponent stopped responding.
  /// The caller passes [opponentRole] so we can write the right
  /// terminal result (hostTimeout / joinerTimeout). Both clients then
  /// see status:ended via the snapshot stream and end the game with a
  /// Timeout result in the local game-over modal.
  Future<void> declareOpponentTimeout(String code, PlayerRole opponentRole);

  /// Cleans up the caller's presence and any per-session listeners.
  /// Idempotent. Safe to call from `dispose()`. Does NOT delete the
  /// game doc — TTL cleanup handles that. If the game is still active
  /// when called, the caller is treated as having walked away (the
  /// 60s grace window then runs out, the opponent wins).
  Future<void> leaveGame(String code);

  /// Best-effort sweep that deletes rooms previously hosted by *this*
  /// device that aren't currently in an active game. Run on lobby
  /// entry to keep the user's footprint in Firebase tidy without
  /// requiring a server-side TTL job. Anonymous Firebase Auth uids
  /// are stable per install, so `auth.uid == hostUid` reliably
  /// identifies "my rooms" across launches.
  ///
  /// Fire-and-forget: failures are logged but never thrown. Skipping
  /// an orphan is no worse than what we'd have done before this
  /// existed. Active games (status == active) are never touched.
  Future<void> cleanupMyOrphanedRooms();
}

/// Base type for predictable failures the UI surfaces to the player.
/// Network or platform errors not modelled here are thrown as the
/// underlying SDK type and treated as generic "connection lost" in
/// the UI. Not `sealed` — we instantiate the base type directly as a
/// catch-all for "unexpected service failure" without a specific code.
class OnlinePlayException implements Exception {
  const OnlinePlayException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// User-typed code doesn't match any document.
class RoomNotFoundException extends OnlinePlayException {
  const RoomNotFoundException([super.message = 'Room not found']);
}

/// Code exists but already has both players. (Player tried to join a
/// game that's already in progress.)
class RoomFullException extends OnlinePlayException {
  const RoomFullException([super.message = 'Room is already full']);
}

/// Code exists but the room has ended — typically because the host
/// abandoned it (joined someone else's room first, or backed out of
/// the lobby) and we marked it forfeited so nobody could enter a
/// phantom-host situation.
class RoomEndedException extends OnlinePlayException {
  const RoomEndedException([super.message = 'Room is no longer open']);
}

/// Security rules rejected the read/write. Usually means the player
/// isn't one of the two uids in the doc.
class NotAuthorizedException extends OnlinePlayException {
  const NotAuthorizedException([
    super.message = 'Not authorized for this room',
  ]);
}

/// [OnlinePlayService.submitMove] was called with a seq that the doc
/// already passed (opponent's move crossed ours). Caller should
/// resync from the next [OnlinePlayService.watchGame] event.
class SequenceConflictException extends OnlinePlayException {
  const SequenceConflictException([super.message = 'Move out of sequence']);
}
