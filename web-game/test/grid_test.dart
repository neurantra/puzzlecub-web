import 'package:alphadoku/game/grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a new grid is empty and consistent', () {
    final g = Grid();
    expect(g.filledCount, 0);
    expect(g.isComplete, isFalse);
    expect(g.isConsistent, isTrue);
  });

  test('box indexing covers the nine boxes', () {
    expect(Grid.boxOf(0, 0), 0);
    expect(Grid.boxOf(0, 8), 2);
    expect(Grid.boxOf(4, 4), 4);
    expect(Grid.boxOf(8, 0), 6);
    expect(Grid.boxOf(8, 8), 8);
  });

  test('allows rejects a repeat in row, column and box', () {
    final g = Grid();
    g.set(0, 0, 3);
    expect(g.allows(0, 5, 3), isFalse, reason: 'same row');
    expect(g.allows(5, 0, 3), isFalse, reason: 'same column');
    expect(g.allows(1, 1, 3), isFalse, reason: 'same box');
    expect(g.allows(5, 5, 3), isTrue);
  });

  test('a repeat makes the grid inconsistent', () {
    final g = Grid();
    g.set(0, 0, 1);
    expect(g.isConsistent, isTrue);
    g.set(0, 4, 1);
    expect(g.isConsistent, isFalse);
  });

  test('candidates shrink as the unit fills', () {
    final g = Grid();
    expect(g.candidates(4, 4).length, 9);
    for (var c = 0; c < 8; c++) {
      g.set(4, c, c);
    }
    expect(g.candidates(4, 8), {8});
  });

  test('copy does not alias the original', () {
    final a = Grid();
    a.set(2, 2, 5);
    final b = Grid.copy(a);
    b.set(2, 2, 6);
    expect(a.at(2, 2), 5);
    expect(b.at(2, 2), 6);
  });
}
