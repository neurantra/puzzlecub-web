import 'dart:collection';
import 'dart:math';

import 'maze.dart';
import 'maze_level.dart';
import 'maze_score.dart';
import 'hunt_options.dart';

enum FindResult { ignored, invalid, duplicate, common, rare }

enum TapResult { selected, undone, blocked, notLetter, ignored }

/// Every collected letter must be reached through an open cardinal edge.
class Hunt {
  Hunt({
    required this.maze,
    required this.level,
    this.relaxed = false,
    this.options = const HuntOptions(),
  });
  final Maze maze;
  final MazeLevel level;
  final bool relaxed;
  final HuntOptions options;
  final List<int> path = [];
  final Set<String> found = {};
  int score = 0;
  int mistakes = 0;
  bool finished = false;

  String get word => path.map((i) => _letter(i) ?? '').join();
  int get wordTileCount => path.where((i) => _letter(i) != null).length;
  int get commonFound => found.where(maze.isCommon).length;
  int get rareFound => found.length - commonFound;
  bool get cleared =>
      maze.commonWords.isNotEmpty && commonFound == maze.commonWords.length;
  int get attemptsLeft => max(0, options.attempts(level) - mistakes);
  int get finalScore => score + (cleared ? kMazePerfectClearBonus : 0);
  String? _letter(int cell) =>
      maze.letterAt(cell % maze.width, cell ~/ maze.width);

  void start(int cell) {
    if (finished || cell < 0 || cell >= maze.width * maze.height) return;
    path
      ..clear()
      ..add(cell);
  }

  bool step(int cell) {
    if (finished || path.isEmpty || path.last == cell) return false;
    if (cell < 0 || cell >= maze.width * maze.height) return false;
    final last = path.last;
    final dx = cell % maze.width - last % maze.width;
    final dy = cell ~/ maze.width - last ~/ maze.width;
    final dir = switch ((dx, dy)) {
      (1, 0) => MazeDir.east,
      (-1, 0) => MazeDir.west,
      (0, 1) => MazeDir.south,
      (0, -1) => MazeDir.north,
      _ => null,
    };
    if (dir == null ||
        !maze.isOpen(last % maze.width, last ~/ maze.width, dir)) {
      return false;
    }
    if (path.length > 1 && path[path.length - 2] == cell) {
      path.removeLast();
    } else {
      path.add(cell);
    }
    return true;
  }

  /// Shortest open routes to the next letters. Empty corridors are traversable;
  /// every letter is a stopping point, never something an assisted tap skips.
  /// The immediately previous cell is excluded to match drag-to-undo behavior.
  Map<int, List<int>> get nextLetterPaths {
    if (finished || path.isEmpty) return {};
    final start = path.last;
    final previous = path.length > 1 ? path[path.length - 2] : null;
    final parents = <int, int?>{start: null};
    final queue = Queue<int>()..add(start);
    final routes = <int, List<int>>{};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final dir in MazeDir.values) {
        if (!maze.isOpen(current % maze.width, current ~/ maze.width, dir)) {
          continue;
        }
        final next = current + dir.dy * maze.width + dir.dx;
        if (parents.containsKey(next) ||
            (current == start && next == previous)) {
          continue;
        }
        parents[next] = current;
        if (_letter(next) != null) {
          // Previously collected tiles are explicit undo targets instead.
          if (path.contains(next)) continue;
          final route = <int>[];
          int? cursor = next;
          while (cursor != null && cursor != start) {
            route.add(cursor);
            cursor = parents[cursor];
          }
          routes[next] = route.reversed.toList();
        } else {
          queue.add(next);
        }
      }
    }
    return routes;
  }

  Set<int> get tapTargets => path.isEmpty
      ? {for (final l in maze.letters) l.y * maze.width + l.x}
      : nextLetterPaths.keys.toSet();

  TapResult tapLetter(int cell) {
    if (finished || cell < 0 || cell >= maze.width * maze.height) {
      return TapResult.ignored;
    }
    if (_letter(cell) == null) return TapResult.notLetter;
    if (path.isEmpty) {
      start(cell);
      return TapResult.selected;
    }
    if (path.last == cell) return TapResult.ignored;
    final previousIndex = path.lastIndexOf(cell);
    if (previousIndex >= 0) {
      path.removeRange(previousIndex + 1, path.length);
      return TapResult.undone;
    }
    final route = nextLetterPaths[cell];
    if (route == null) return TapResult.blocked;
    path.addAll(route);
    return TapResult.selected;
  }

  /// Undo one selected letter and the empty corridor leading up to it.
  void undoLetter() {
    if (finished || path.isEmpty) return;
    final letters = [
      for (var i = 0; i < path.length; i++)
        if (_letter(path[i]) != null) i,
    ];
    if (letters.length < 2) {
      path.clear();
      return;
    }
    path.removeRange(letters[letters.length - 2] + 1, path.length);
  }

  FindResult submit() {
    if (finished) return FindResult.ignored;
    final candidate = word;
    final length = wordTileCount;
    path.clear();
    if (length < kMazeMinAttemptLen) {
      return FindResult.ignored;
    }
    if (length < maze.script.minimumTiles || !maze.contains(candidate)) {
      mistakes++;
      if (!relaxed && attemptsLeft == 0) finish();
      return FindResult.invalid;
    }
    if (!found.add(candidate)) return FindResult.duplicate;
    final common = maze.isCommon(candidate);
    score +=
        scoreForWord(level: level, wordLen: length) +
        (common ? 0 : kMazeRareWordBonus);
    if (cleared) finish();
    return common ? FindResult.common : FindResult.rare;
  }

  void finish() {
    finished = true;
    path.clear();
  }
}

int daySeed(DateTime date) => date.year * 10000 + date.month * 100 + date.day;
