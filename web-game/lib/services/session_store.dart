import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/session.dart';

/// One versioned local slot. Serialize writes so an older move cannot finish
/// after a newer one or resurrect a completed game after its slot is cleared.
class SessionStore {
  static final instance = SessionStore();
  static String get saveKey => 'alphadoku.session.v1${Uri.base.queryParameters['day'] == null ? '' : '.daily.' + Uri.base.queryParameters['day']!}';
  static const tutorialKey = 'alphadoku.tutorial.v1';

  Future<void>? _pending;

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = (_pending ?? Future<void>.value()).then(
      (_) => operation(),
      onError: (_) => operation(),
    );
    _pending = next;
    // Observe the error even when the caller is being disposed.
    void finished() {
      if (identical(_pending, next)) _pending = null;
    }

    next.then((_) => finished(), onError: (Object _) => finished());
    return next;
  }

  Future<Session?> load() async {
    final pending = _pending;
    if (pending != null) await pending.catchError((_) {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final text = prefs.getString(saveKey);
    if (text == null) return null;
    try {
      return Session.fromSave(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      // Keep the original bytes: never silently destroy an unreadable save.
      throw const FormatException('The saved puzzle could not be read.');
    }
  }

  Future<void> save(Session session) {
    if (session.isSolved) return clear();
    final text = jsonEncode(session.toSave());
    return _enqueue(() async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(saveKey, text)) {
        throw StateError('Could not save this puzzle.');
      }
    });
  }

  Future<void> clear() => _enqueue(() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove(saveKey)) {
      throw StateError('Could not update saved progress.');
    }
  });

  Future<bool> tutorialCompleted() async =>
      (await SharedPreferences.getInstance()).getBool(tutorialKey) ?? false;

  Future<void> completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(tutorialKey, true)) {
      throw StateError('Could not save tutorial progress.');
    }
  }
}
