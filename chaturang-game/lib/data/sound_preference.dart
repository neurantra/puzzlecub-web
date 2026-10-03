import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_service.dart';

/// The player's sound choice survives launches. Temporary ad muting must only
/// change AudioService.enabled, never this preference.
class SoundPreference extends ValueNotifier<bool> {
  SoundPreference({required this.storageKey}) : super(true);

  final String storageKey;
  Future<void>? _loading;
  Future<void> _writes = Future.value();
  bool _changed = false;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_changed) super.value = prefs.getBool(storageKey) ?? true;
    } catch (_) {
      // Storage unavailable: keep the current session choice.
    }
    AudioService.instance.enabled = value;
  }

  @override
  set value(bool enabled) {
    if (enabled == value) return;
    _changed = true;
    super.value = enabled;
    AudioService.instance.enabled = enabled;
    // Serialize quick toggles so the last choice is always the stored choice.
    _writes = _writes.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(storageKey, enabled);
      } catch (_) {
        // Sound still changes immediately even if persistence is unavailable.
      }
    });
  }

  @visibleForTesting
  Future<void> get pendingWrites => _writes;
}
