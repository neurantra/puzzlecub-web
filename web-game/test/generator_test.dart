import 'dart:math';

import 'package:alphadoku/game/axis.dart';
import 'package:alphadoku/game/difficulty.dart';
import 'package:alphadoku/game/generator.dart';
import 'package:alphadoku/game/solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final difficulty in Difficulty.values) {
    group(difficulty.label, () {
      late final puzzle = Generator(
        random: Random(difficulty.index + 17),
      ).generate(difficulty);

      test('solution is a legal, complete grid', () {
        expect(puzzle.solution.isComplete, isTrue);
        expect(puzzle.solution.isConsistent, isTrue);
      });

      test('exactly one track spells the phrase', () {
        final spelling = spellingAxes(puzzle.solution);
        expect(spelling, [puzzle.axis]);
      });

      test('givens agree with the solution', () {
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (!puzzle.givens.isEmpty(r, c)) {
              expect(puzzle.givens.at(r, c), puzzle.solution.at(r, c));
            }
          }
        }
      });

      test('givens count sits in the tier band', () {
        expect(puzzle.givensCount, greaterThanOrEqualTo(difficulty.minGivens));
        expect(puzzle.givensCount, lessThanOrEqualTo(difficulty.maxGivens));
      });

      test('axis ambiguity sits in the tier band', () {
        final n = compatibleAxes(puzzle.givens).length;
        expect(n, greaterThanOrEqualTo(difficulty.minAxes));
        expect(n, lessThanOrEqualTo(difficulty.maxAxes));
      });

      test('the puzzle has exactly one legal solution', () {
        expect(Solver(puzzle.givens).countSolutions(limit: 3), 1);
      });

      test('the puzzle is solvable by logic alone', () {
        final report = Solver(puzzle.givens).solveLogically();
        expect(report.solved, isTrue);
        expect(report.grid.cells, puzzle.solution.cells);
      });

      test('classical difficulty stays under the tier ceiling', () {
        final report = Solver(puzzle.givens).solveLogically();
        expect(
          report.hardestCell.rank,
          lessThanOrEqualTo(difficulty.ceiling.rank),
        );
      });

      test('the phrase is a valid isogram', () {
        expect(puzzle.phrase.isValid, isTrue);
      });

      test('json round-trip carries the axis and grid', () {
        final json = puzzle.toJson();
        expect(json['target_phrase'], puzzle.phrase.key);
        expect(json['givens_count'], puzzle.givensCount);
        expect((json['mystery_axis'] as Map)['label'], puzzle.axis.label);
        expect((json['initial_grid'] as List).length, 9);
      });
    });
  }

  test('hard and pro require the axis deduction', () {
    for (final d in [Difficulty.hard, Difficulty.pro]) {
      final p = Generator(random: Random(d.index + 31)).generate(d);
      final report = Solver(p.givens).solveLogically();
      expect(report.usedAxisLogic, isTrue, reason: d.label);
    }
  });

  test('generation is repeatable for a given seed', () {
    final a = Generator(random: Random(99)).generate(Difficulty.medium);
    final b = Generator(random: Random(99)).generate(Difficulty.medium);
    expect(a.givens.cells, b.givens.cells);
    expect(a.axis, b.axis);
    expect(a.phrase.key, b.phrase.key);
  });

  test('a cell removed from the givens stays deducible', () {
    final p = Generator(random: Random(4)).generate(Difficulty.medium);
    final report = Solver(p.givens).solveLogically();
    expect(report.axis, p.axis);
  });

  test('repeated generation stays within budget', () {
    final gen = Generator(random: Random(12));
    final sw = Stopwatch()..start();
    for (var i = 0; i < 10; i++) {
      gen.generate(Difficulty.medium);
    }
    sw.stop();
    expect(
      sw.elapsedMilliseconds,
      lessThan(20000),
      reason: 'ten medium boards took ${sw.elapsedMilliseconds}ms',
    );
  });
}
