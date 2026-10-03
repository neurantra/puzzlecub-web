import 'package:flutter/foundation.dart';
import '../engine/move_limit.dart';

/// Session preferences shared by the home screen and game settings.
class GamePreferences {
  GamePreferences._();
  static final soundEnabled = ValueNotifier<bool>(true);
  static final timedMode = ValueNotifier<bool>(false);
  static final moveLimit = ValueNotifier<MoveLimit>(MoveLimit.unlimited);
}
