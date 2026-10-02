import 'package:alphadoku/data/corpus.dart';
import 'package:alphadoku/game/phrase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release corpus contains at least 2000 reviewed targets', () {
    expect(corpus.length, greaterThanOrEqualTo(2000));
  });
  test('every corpus phrase is a true nine-letter isogram', () {
    final broken = <String>[];
    for (final p in corpus) {
      final letters = p.key.split('');
      if (letters.length != 9) {
        broken.add('${p.text}: ${letters.length} letters');
      } else if (letters.toSet().length != 9) {
        final dupes = letters
            .where((c) => letters.where((o) => o == c).length > 1)
            .toSet();
        broken.add('${p.text}: repeats ${dupes.join(",")}');
      }
    }
    expect(broken, isEmpty, reason: 'invalid phrases:\n${broken.join("\n")}');
  });

  test('corpus is uppercase A-Z and spaces only', () {
    for (final p in corpus) {
      expect(
        RegExp(r'^[A-Z ]+$').hasMatch(p.text),
        isTrue,
        reason: '${p.text} has unexpected characters',
      );
    }
  });

  test('no duplicate phrases', () {
    final keys = corpus.map((p) => p.key).toList();
    expect(keys.toSet().length, keys.length);
  });

  test('every tier has usable phrases', () {
    for (final tier in [PhraseTier.single, PhraseTier.pair]) {
      expect(corpusForTier(tier), isNotEmpty, reason: 'tier ${tier.label}');
    }
  });

  test('tier matches the word count of the phrase', () {
    for (final p in corpus) {
      final words = p.text.split(' ').length;
      final expected = switch (words) {
        1 => PhraseTier.single,
        2 => PhraseTier.pair,
        _ => PhraseTier.triple,
      };
      expect(p.tier, expected, reason: p.text);
    }
  });

  test(
    'only approved word-length patterns ship, with every pattern covered',
    () {
      const allowed = {'9', '5+4', '6+3', '4+5', '7+2', '3+6', '2+7'};
      final seen = <String>{};
      for (final phrase in corpus) {
        final pattern = phrase.text
            .split(' ')
            .map((word) => word.length)
            .join('+');
        expect(allowed, contains(pattern), reason: phrase.text);
        seen.add(pattern);
      }
      expect(seen, allowed);
    },
  );

  test('indexOf maps each letter to its one position', () {
    for (final p in corpus) {
      for (var i = 0; i < 9; i++) {
        expect(p.indexOf(p.letters[i]), i, reason: p.text);
      }
    }
  });
}
