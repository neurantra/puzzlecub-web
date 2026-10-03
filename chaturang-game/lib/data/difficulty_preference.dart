import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/difficulty.dart';
import 'stats_service.dart';

/// The AI level the player last chose, kept across games and launches.
///
/// It used to be a field on the board screen, which is rebuilt for every
/// game — so every game started on Easy, and when the AI drew White it had
/// already played Easy's first move before Settings could be opened to
/// change it. A player who had earned Hard was, in practice, never playing
/// it. One notifier for the whole app, loaded at startup and written on
/// every change, is what makes the choice stick; the card-pick screen then
/// offers it before any card is turned.
///
/// The same lifecycle as the other services: fire-and-forget [load] from
/// `main()`, with Easy as the value until it resolves, which is also the
/// right answer for a first launch.
class DifficultyPreference extends ValueNotifier<Difficulty> {
  DifficultyPreference._() : super(Difficulty.easy);

  static final DifficultyPreference instance = DifficultyPreference._();

  static const _key = 'chaturang.settings.difficulty';

  bool _loaded = false;

  /// Reads the stored level. All levels are available in the full-game
  /// edition; unknown values fall back to Easy.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_key);
      if (name == null) return;
      final level = Difficulty.values.cast<Difficulty?>().firstWhere(
        (d) => d!.name == name,
        orElse: () => null,
      );
      if (level == null) return;
      await StatsService.instance.load();
      final stats = StatsService.instance.stats;
      if (level.isUnlockedBy(
        easyWins: stats.easyWins,
        mediumWins: stats.mediumWins,
      )) {
        // Set without persisting: it is what is persisted already.
        super.value = level;
      }
    } catch (_) {
      // Preferences unavailable (tests, a broken store) — stay on Easy.
    }
  }

  @override
  set value(Difficulty level) {
    if (level == value) return;
    super.value = level;
    _persist(level);
  }

  /// Forgets the loaded state so the next [load] reads preferences again.
  /// Tests only: the singleton outlives each test's mock preferences.
  @visibleForTesting
  void resetForTest() {
    _loaded = false;
    super.value = Difficulty.easy;
  }

  Future<void> _persist(Difficulty level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, level.name);
    } catch (_) {
      // Nothing to do: the choice still holds for this session.
    }
  }
}
