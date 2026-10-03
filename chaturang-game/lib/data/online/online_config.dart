import '../../engine/pieces.dart';
import 'game_snapshot.dart';
import 'online_play_service.dart';

/// Passed to `BoardScreen` to put it in online-multiplayer mode.
/// When non-null, BoardScreen uses an `OnlinePlayer` for the opponent
/// (instead of an `AiPlayer`), submits each local move through
/// [service], and listens to the snapshot stream for opponent
/// forfeits / disconnects.
///
/// The local player's [Side] is derived from [myRole] and
/// [initialSnapshot.hostColorIsWhite] — the joiner-side color
/// assignment that happens in `FirebaseOnlinePlayService.joinGame`.
class OnlineConfig {
  const OnlineConfig({
    required this.service,
    required this.roomCode,
    required this.myRole,
    required this.initialSnapshot,
  });

  final OnlinePlayService service;
  final String roomCode;
  final PlayerRole myRole;

  /// Snapshot at the moment the game became active (joiner returned
  /// from joinGame, or host saw status flip to active in the watch
  /// stream). Carries the host-color assignment we need to derive
  /// [myColor].
  final GameSnapshot initialSnapshot;

  /// The local player's color. Computed once at construction from
  /// [myRole] and the host-color flag in [initialSnapshot]. Returns
  /// [Side.white] as a safe default if the color flag is somehow
  /// missing — that case shouldn't arise after a successful join.
  Side get myColor {
    final hostWhite = initialSnapshot.hostColorIsWhite ?? true;
    if (myRole == PlayerRole.host) {
      return hostWhite ? Side.white : Side.black;
    }
    return hostWhite ? Side.black : Side.white;
  }
}
