import 'package:flutter/foundation.dart';
import '../engine/move_limit.dart';
import 'sound_preference.dart';

/// Shared settings. Sound persists across launches; game options are session-only.
class GamePreferences {
  GamePreferences._();
  static final soundEnabled = SoundPreference(
    storageKey: 'chaturang.settings.soundEnabled',
  );
  static final timedMode = ValueNotifier<bool>(false);
  static final moveLimit = ValueNotifier<MoveLimit>(MoveLimit.unlimited);
}
