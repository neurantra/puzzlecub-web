import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:maze_words/domain/hunt.dart';
import 'package:maze_words/domain/maze.dart';
import 'package:maze_words/domain/maze_level.dart';

Maze userMaze() {
  final pack = MazePack.fromJson(
    MazeLevel.medium,
    jsonDecode(File('assets/maze/medium.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  return pack.mazes.singleWhere((m) => m.id == 'medium-048');
}

void main() {
  test('the user’s B A T taps connect empty corridors in medium-048', () {
    final hunt = Hunt(maze: userMaze(), level: MazeLevel.medium);
    expect(hunt.tapLetter(41), TapResult.selected);
    expect(hunt.word, 'B');
    expect(hunt.tapTargets, contains(27));
    expect(hunt.tapLetter(27), TapResult.selected);
    expect(hunt.word, 'BA');
    expect(hunt.tapLetter(13), TapResult.selected);
    expect(hunt.path, [41, 34, 27, 20, 13]);
    expect(hunt.word, 'BAT');
    expect(hunt.submit(), FindResult.common);
    expect(hunt.found, contains('BAT'));
  });
  test('cannot skip A by tapping B then T', () {
    final hunt = Hunt(maze: userMaze(), level: MazeLevel.medium)..tapLetter(41);
    expect(hunt.tapTargets, isNot(contains(13)));
    expect(hunt.tapLetter(13), TapResult.blocked);
    expect(hunt.word, 'B');
    expect(hunt.mistakes, 0);
    expect(hunt.path, [41]);
  });
  test('undo returns to the previous letter, not its empty corridor', () {
    final hunt = Hunt(maze: userMaze(), level: MazeLevel.medium)
      ..tapLetter(41)
      ..tapLetter(27)
      ..tapLetter(13);
    hunt.undoLetter();
    expect(hunt.path, [41, 34, 27]);
    expect(hunt.word, 'BA');
    expect(hunt.tapLetter(41), TapResult.undone);
    expect(hunt.path, [41]);
    hunt.undoLetter();
    expect(hunt.path, isEmpty);
    expect(hunt.tapTargets.length, hunt.maze.letters.length);
  });
  test(
    'empty cells give no selection; repeating a tap never submits a word',
    () {
      final hunt = Hunt(maze: userMaze(), level: MazeLevel.medium);
      expect(hunt.tapLetter(34), TapResult.notLetter);
      expect(hunt.path, isEmpty);
      hunt.tapLetter(41);
      expect(hunt.tapLetter(41), TapResult.ignored);
      expect(hunt.word, 'B');
      expect(hunt.found, isEmpty);
    },
  );
  test(
    'every assisted route respects walls and contains no intervening letter',
    () {
      for (final level in MazeLevel.values) {
        final pack = MazePack.fromJson(
          level,
          jsonDecode(File('assets/maze/${level.name}.json').readAsStringSync())
              as Map<String, dynamic>,
        );
        for (final maze in pack.mazes) {
          for (final letter in maze.letters) {
            final start = letter.y * maze.width + letter.x;
            final hunt = Hunt(maze: maze, level: level)..tapLetter(start);
            for (final route in hunt.nextLetterPaths.values) {
              var previous = start;
              for (var i = 0; i < route.length; i++) {
                final cell = route[i];
                final dir = MazeDir.values.singleWhere(
                  (d) =>
                      d.dx == cell % maze.width - previous % maze.width &&
                      d.dy == cell ~/ maze.width - previous ~/ maze.width,
                );
                expect(
                  maze.isOpen(
                    previous % maze.width,
                    previous ~/ maze.width,
                    dir,
                  ),
                  true,
                );
                if (i < route.length - 1) {
                  expect(
                    maze.letterAt(cell % maze.width, cell ~/ maze.width),
                    isNull,
                  );
                }
                previous = cell;
              }
            }
          }
        }
      }
    },
  );
}
