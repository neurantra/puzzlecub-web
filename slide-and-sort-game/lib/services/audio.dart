import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class GameAudio {
  AudioPlayer? _musicPlayer;
  AudioPlayer get _music => _musicPlayer ??= AudioPlayer();
  AudioPlayer? _effectsPlayer;
  AudioPlayer get _effects => _effectsPlayer ??= AudioPlayer();
  bool _playing = false;
  Future<void> music(bool enabled) async {
    if (_playing == enabled) return;
    _playing = enabled;
    try {
      if (enabled) {
        await _music.setReleaseMode(ReleaseMode.loop);
        await _music.setVolume(0.16);
        await _music.play(AssetSource('sounds/garden.wav'));
      } else {
        await _music.pause();
      }
    } catch (_) {
      _playing = false;
    }
  }

  void tap(bool enabled, {bool win = false}) {
    if (enabled) unawaited(_effect(win));
  }

  Future<void> _effect(bool win) async {
    try {
      await _effects.play(AssetSource('sounds/${win ? 'success' : 'tap'}.mp3'));
    } catch (_) {
      /* Audio never interrupts a puzzle. */
    }
  }

  void dispose() {
    unawaited(_musicPlayer?.dispose());
    unawaited(_effectsPlayer?.dispose());
  }
}
