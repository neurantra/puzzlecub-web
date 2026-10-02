import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/phrase.dart';

/// A persistent deck shared by all levels. Exact targets do not repeat until
/// the deck is exhausted. Recent noun families and alphabets are spaced out.
class TargetHistory {
  static const key = 'alphadoku.targets.v1';
  Future<Phrase> choose(List<Phrase> targets, Random random) async {
    if (targets.isEmpty) throw StateError('No approved targets');
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(key) ?? [];
    final seen = history.toSet();
    var pool = targets.where((p) => !seen.contains(p.key)).toList();
    if (pool.isEmpty) {
      // Leave the recent tail in place when starting a new cycle.
      final recent = history.reversed
          .take(min(100, targets.length - 1))
          .toSet();
      if (!await prefs.setStringList(key, recent.toList().reversed.toList())) {
        throw StateError('Could not reset target history');
      }
      pool = targets.where((p) => !recent.contains(p.key)).toList();
    }
    final byKey = {for (final p in targets) p.key: p};
    final recent = history.reversed
        .take(40)
        .map((k) => byKey[k])
        .whereType<Phrase>();
    final families = recent.map(_family).toSet();
    final alphabets = recent.map(_alphabet).toSet();
    final varied = pool
        .where(
          (p) =>
              !families.contains(_family(p)) &&
              !alphabets.contains(_alphabet(p)),
        )
        .toList();
    if (varied.isNotEmpty) pool = varied;
    return pool[random.nextInt(pool.length)];
  }

  Future<void> record(Phrase phrase) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(key) ?? [];
    history.remove(phrase.key);
    history.add(phrase.key);
    if (!await prefs.setStringList(key, history)) {
      throw StateError('Could not save target history');
    }
  }

  String _family(Phrase phrase) {
    var word = phrase.text.split(' ').last;
    if (word.endsWith('S') && !word.endsWith('SS')) {
      word = word.substring(0, word.length - 1);
    }
    return word;
  }

  String _alphabet(Phrase phrase) => (phrase.letters..sort()).join();
}
