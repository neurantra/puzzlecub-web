import 'package:alphadoku/game/axis.dart';
import 'package:alphadoku/game/grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('there are eighteen candidate tracks', () {
    expect(AxisTrack.all.length, 18);
    expect(AxisTrack.all.toSet().length, 18);
  });

  test('labels read R1-R9 then C1-C9', () {
    expect(AxisTrack.all.first.label, 'R1');
    expect(AxisTrack.all[8].label, 'R9');
    expect(AxisTrack.all[9].label, 'C1');
    expect(AxisTrack.all.last.label, 'C9');
  });

  test('applying a track makes it spell the phrase', () {
    for (final axis in AxisTrack.all) {
      final grid = Grid();
      axis.apply(grid);
      expect(axis.spellsPhrase(grid), isTrue, reason: axis.label);
      expect(grid.isConsistent, isTrue, reason: axis.label);
    }
  });

  // The original specification asked for one row AND one column to spell the
  // phrase. Section 3 of that document proves such a pair must share an index.
  // This test shows why no grid can then exist, so the rule cannot come back
  // by accident.
  test('the spec\'s dual-axis rule is impossible for every diagonal index', () {
    for (var d = 0; d < 9; d++) {
      final grid = Grid();
      AxisTrack(AxisKind.row, d).apply(grid);
      AxisTrack(AxisKind.column, d).apply(grid);
      expect(
        grid.isConsistent,
        isFalse,
        reason: 'row $d plus column $d should collide inside the diagonal box',
      );
    }
  });

  test('a placed axis blocks every other track under full propagation', () {
    // This is why viability and compatibility have to be separate notions.
    final grid = Grid();
    const axis = AxisTrack(AxisKind.row, 3);
    axis.apply(grid);
    expect(viableAxes(grid), [axis]);
    expect(compatibleAxes(grid).length, greaterThan(1));
  });

  test('a contradicting given removes a track from the scan', () {
    final grid = Grid();
    // Position 0 of row 5 must hold letter 0; put letter 4 there instead.
    grid.set(5, 0, 4);
    expect(const AxisTrack(AxisKind.row, 5).isCompatible(grid), isFalse);
    expect(const AxisTrack(AxisKind.row, 4).isCompatible(grid), isTrue);
  });

  test('an empty board leaves every track open', () {
    expect(compatibleAxes(Grid()).length, 18);
  });
}
