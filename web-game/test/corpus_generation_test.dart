import 'dart:math';
import 'package:alphadoku/data/corpus.dart';
import 'package:alphadoku/game/axis.dart';
import 'package:alphadoku/game/difficulty.dart';
import 'package:alphadoku/game/generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every phrase pattern generates a valid puzzle at each difficulty', () {
    final representatives = {
      for (final p in corpus)
        p.text.split(' ').map((w) => w.length).join('+'): p,
    };
    var seed = 10;
    for (final phrase in representatives.values) {
      for (final tier in Difficulty.values) {
        final puzzle = Generator(
          random: Random(seed++),
        ).generate(tier, phrase: phrase);
        expect(puzzle.solution.isConsistent, isTrue);
        expect(puzzle.solution.filledCount, 81);
        expect(spellingAxes(puzzle.solution), [puzzle.axis]);
        expect(puzzle.phrase, phrase);
      }
    }
  });
}
