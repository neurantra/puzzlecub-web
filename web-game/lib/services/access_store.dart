import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/difficulty.dart';

enum AccessKind { hint, puzzle }

/// One document per installation. Rewards survive restarts and are consumed
/// only by an action, never just by opening a paywall or dismissing an ad.
class AccessStore {
  static const key = 'alphadoku.access.v1';
  Future<void> _queue = Future<void>.value();
  Future<T> _serial<T>(Future<T> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<Map<String, dynamic>> _read() async {
    final text = (await SharedPreferences.getInstance()).getString(key);
    if (text == null) return {'freeUsed': <String>[], 'hint': 0, 'puzzle': 0};
    var data = jsonDecode(text) as Map<String, dynamic>;
    // Recover an interrupted generation/save on the next launch. A completed
    // saved puzzle can still be resumed; we favor refunding over losing access.
    final pending = data.remove('reservation');
    if (pending != null) {
      data = Map<String, dynamic>.from(pending as Map);
      await _write(data);
    }
    if (data['freeUsed'] is! List ||
        data['hint'] is! int ||
        data['puzzle'] is! int ||
        (data['hint'] as int) < 0 ||
        (data['puzzle'] as int) < 0) {
      throw const FormatException('Unreadable access record');
    }
    return data;
  }

  Future<void> _write(Map<String, dynamic> data) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode(data),
    )) {
      throw StateError('Could not save access');
    }
  }

  Future<bool> available(AccessKind kind, Difficulty tier) => _serial(() async {
    final data = await _read();
    return (kind == AccessKind.puzzle &&
            !(data['freeUsed'] as List).contains(tier.name)) ||
        (data[kind.name] as int) > 0;
  });
  Future<void> reward(AccessKind kind) => _serial(() async {
    final data = await _read();
    data[kind.name] = (data[kind.name] as int) + 1;
    await _write(data);
  });

  /// Reserve before performing the action. A failed generation/save returns the
  /// same free allowance or credit. Serial execution prevents double spending.
  Future<void> use(
    AccessKind kind,
    Difficulty tier,
    Future<void> Function() action,
  ) => _serial(() async {
    final data = await _read();
    final original = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    final used = data['freeUsed'] as List;
    if (kind == AccessKind.puzzle && !used.contains(tier.name)) {
      used.add(tier.name);
    } else if ((data[kind.name] as int) > 0) {
      data[kind.name] = (data[kind.name] as int) - 1;
    } else {
      throw StateError('This action needs an unlock');
    }
    await _write({...data, 'reservation': original});
    try {
      await action();
      await _write(data);
    } catch (_) {
      await _write(original);
      rethrow;
    }
  });
}
