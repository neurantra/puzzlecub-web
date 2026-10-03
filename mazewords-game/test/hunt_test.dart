import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:maze_words/domain/hunt.dart';
import 'package:maze_words/domain/maze.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/domain/maze_score.dart';

Maze fixture() => Maze(
  id: 'test',
  seed: 0,
  width: 3,
  height: 2,
  walls: [9, 5, 3, 12, 5, 6],
  letters: [
    const MazeLetter(x: 0, y: 0, letter: 'C'),
    const MazeLetter(x: 1, y: 0, letter: 'A'),
    const MazeLetter(x: 2, y: 0, letter: 'T'),
  ],
  seedWord: 'CAT',
  words: ['CAT', 'TAC'],
  commonWords: ['CAT'],
  commonPaths: {
    'CAT': [0, 1, 2],
  },
);

void main() {
  test('scores an actual traced word and awards clear bonus only once', () {
    final hunt = Hunt(maze: fixture(), level: MazeLevel.easy);
    hunt.start(0);
    hunt.step(1);
    hunt.step(2);
    expect(hunt.word, 'CAT');
    expect(hunt.submit(), FindResult.common);
    expect(hunt.finalScore, 130);
    expect(hunt.finished, true);
    hunt.finish();
    expect(hunt.finalScore, 130);
    expect(hunt.submit(), FindResult.ignored);
  });
  test(
    'cannot cross a wall, jump a cell, move diagonally, or leave the grid',
    () {
      final hunt = Hunt(maze: fixture(), level: MazeLevel.easy)..start(1);
      for (final target in [4, 3, 5, -1, 8]) {
        expect(hunt.step(target), false);
      }
      expect(hunt.path, [1]);
      hunt.start(0);
      expect(hunt.step(2), false);
    },
  );
  test('backtracking removes the last collected letter', () {
    final hunt = Hunt(maze: fixture(), level: MazeLevel.easy)..start(0);
    hunt.step(1);
    hunt.step(0);
    expect(hunt.word, 'C');
    expect(hunt.path, [0]);
    expect(hunt.submit(), FindResult.ignored);
    expect(hunt.mistakes, 0);
  });
  test('rare finds score once and do not complete the common goal', () {
    final hunt = Hunt(maze: fixture(), level: MazeLevel.easy)..start(2);
    hunt.step(1);
    hunt.step(0);
    expect(hunt.submit(), FindResult.rare);
    expect(hunt.score, 55);
    expect(hunt.commonFound, 0);
    expect(hunt.finished, false);
    hunt.start(2);
    hunt.step(1);
    hunt.step(0);
    expect(hunt.submit(), FindResult.duplicate);
    expect(hunt.score, 55);
  });
  test('invalid attempts end timed rounds but not relaxed rounds', () {
    for (final relaxed in [false, true]) {
      final hunt = Hunt(
        maze: fixture(),
        level: MazeLevel.easy,
        relaxed: relaxed,
      );
      for (var i = 0; i < 6; i++) {
        hunt.start(0);
        hunt.step(1);
        expect(hunt.submit(), FindResult.invalid);
      }
      expect(hunt.finished, !relaxed);
    }
  });
  test('progressive scoring preserves the original maze rules', () {
    expect(scoreForWord(level: MazeLevel.easy, wordLen: 8), 130);
    expect(scoreForWord(level: MazeLevel.hard, wordLen: 8), 80);
    expect(daySeed(DateTime(2026, 9, 24)), 20260924);
  });
  for (final level in MazeLevel.values) {
    test(
      '${level.name} pack paths stay inside the maze, cross open edges and spell their advertised words',
      () {
        final pack = MazePack.fromJson(
          level,
          jsonDecode(File('assets/maze/${level.name}.json').readAsStringSync())
              as Map<String, dynamic>,
        );
        expect(pack.mazes, isNotEmpty);
        for (final maze in pack.mazes) {
          expect(maze.words, containsAll(maze.commonWords));
          expect(maze.commonWords, contains(maze.seedWord));
          for (final word in maze.commonWords) {
            final path = maze.commonPaths[word]!;
            final letters = StringBuffer();
            for (var i = 0; i < path.length; i++) {
              final cell = path[i];
              expect(cell, inInclusiveRange(0, maze.width * maze.height - 1));
              letters.write(
                maze.letterAt(cell % maze.width, cell ~/ maze.width) ?? '',
              );
              if (i > 0) {
                final prev = path[i - 1];
                final dx = cell % maze.width - prev % maze.width;
                final dy = cell ~/ maze.width - prev ~/ maze.width;
                final dir = MazeDir.values.singleWhere(
                  (d) => d.dx == dx && d.dy == dy,
                );
                expect(
                  maze.isOpen(prev % maze.width, prev ~/ maze.width, dir),
                  true,
                  reason: '${maze.id}: $word',
                );
              }
            }
            expect(letters.toString(), word, reason: maze.id);
          }
        }
      },
    );
  }
}
