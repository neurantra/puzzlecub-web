import 'package:audioplayers/audioplayers.dart';

/// Sounds the game can play. Asset files are mp3, named after the enum value
/// (e.g. `move.mp3`), in `assets/sounds/`.
enum Sound {
  /// Subtle wooden click / soft chime — every legal move that isn't a check
  /// or checkmate.
  move,

  /// Low buzz / dull thud — illegal action (tapping a non-legal square while
  /// a piece is selected).
  illegal,

  /// Gentle alarm / temple bell — a move puts the opposing king in check.
  check,

  /// Longer dramatic tone — checkmate ends the game.
  checkmate,

  /// Short reverse / whoosh — the player undoes a move.
  undo,

  /// Neutral game-concluded tone — plays for every terminal result that is
  /// not a checkmate (stalemate, draw, forfeit, timeout, move-limit draw).
  /// Checkmate keeps its own dramatic [checkmate] tone.
  gameEnd,
}

/// Singleton audio playback service.
///
/// Mirrors the pattern used in Mohan's Sumquest project (see
/// `reference-admob-pattern` memory): one persistent [AudioPlayer] per sound,
/// loaded eagerly via [load], played by seeking to 0 and resuming. Graceful
/// when assets are missing — load failures don't crash; play() falls back
/// via [fallbackChain] or silently no-ops.
class AudioService {
  AudioService._();

  static AudioService? _singleton;
  static AudioService get instance => _singleton ??= AudioService._();

  bool enabled = true;
  bool _loaded = false;
  bool _disposed = false;

  final Map<Sound, AudioPlayer> _players = {};

  static const Map<Sound, String> _assetPaths = {
    Sound.move: 'sounds/move.mp3',
    Sound.illegal: 'sounds/illegal.mp3',
    Sound.check: 'sounds/check.mp3',
    Sound.checkmate: 'sounds/checkmate.mp3',
    Sound.undo: 'sounds/undo.mp3',
    Sound.gameEnd: 'sounds/gameEnd.mp3',
  };

  /// If the requested sound failed to load (missing file etc.), fall back to
  /// these substitutes so the game still has audible feedback.
  static const Map<Sound, Sound> fallbackChain = {
    Sound.illegal: Sound.move,
    Sound.check: Sound.move,
    Sound.checkmate: Sound.check,
    Sound.undo: Sound.move,
    Sound.gameEnd: Sound.checkmate,
  };

  Future<void> load() async {
    if (_loaded || _disposed) return;
    _loaded = true;
    for (final entry in _assetPaths.entries) {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(entry.value));
        _players[entry.key] = player;
      } catch (_) {
        // Missing file or load error — slot stays empty; play() falls back.
      }
    }
  }

  Future<void> play(Sound slot) async {
    if (!enabled || _disposed) return;
    final player = _players[slot];
    if (player != null) {
      try {
        await player.seek(Duration.zero);
        await player.resume();
        return;
      } catch (_) {
        // Fall through to fallback.
      }
    }
    final fallback = fallbackChain[slot];
    if (fallback != null && fallback != slot) {
      await play(fallback);
    }
  }

  Future<void> stopAll() async {
    for (final player in _players.values) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _loaded = false;
  }
}
