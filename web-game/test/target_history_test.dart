import 'dart:math';
import 'package:alphadoku/data/corpus.dart';
import 'package:alphadoku/game/phrase.dart';
import 'package:alphadoku/services/target_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'target history survives restarts and excludes previous targets',
    () async {
      final seen = <String>{};
      for (var i = 0; i < 120; i++) {
        final history = TargetHistory();
        final phrase = await history.choose(corpus, Random(i));
        expect(seen.add(phrase.key), isTrue);
        await history.record(phrase);
      }
    },
  );
  test(
    'exhausted deck starts a new cycle without immediate repetition',
    () async {
      final targets = corpus.take(3).toList();
      final history = TargetHistory();
      for (final phrase in targets) {
        await history.record(phrase);
      }
      final next = await history.choose(targets, Random(1));
      expect(next.key, targets.first.key);
    },
  );
  test(
    'recent noun family is avoided when other targets are available',
    () async {
      const previous = Phrase(text: 'BLUE SHIRT', tier: PhraseTier.pair);
      const related = Phrase(text: 'GOLD SHIRT', tier: PhraseTier.pair);
      const alternative = Phrase(text: 'ALGORITHM', tier: PhraseTier.single);
      final history = TargetHistory();
      await history.record(previous);
      final next = await history.choose([
        previous,
        related,
        alternative,
      ], Random(1));
      expect(next, alternative);
    },
  );
}
