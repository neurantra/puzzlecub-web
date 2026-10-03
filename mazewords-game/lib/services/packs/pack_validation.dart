import 'dart:convert';
import '../../domain/puzzle_language.dart';
import '../../domain/maze.dart';
import '../../domain/maze_level.dart';

class LanguageBundle {
  LanguageBundle(this.language, this.revision, this.levels);
  final String language;
  final int revision;
  final Map<MazeLevel, MazePack> levels;
}

/// Untrusted downloaded JSON must satisfy geometry and solution invariants
/// before any install pointer is changed. Limits also bound rendering/memory.
LanguageBundle validateBundle(String text, String language, int revision) {
  final root = jsonDecode(text) as Map<String, dynamic>;
  if (root['schemaVersion'] != 1 ||
      root['language'] != language ||
      root['revision'] != revision ||
      revision < 1) {
    throw const FormatException('Incompatible pack');
  }
  if (!PuzzleLanguage.supports(language)) {
    throw const FormatException('Unsupported language');
  }
  final script = PuzzleLanguage.of(language);
  final levels = <MazeLevel, MazePack>{};
  for (final level in MazeLevel.values) {
    final raw = (root['levels'] as Map)[level.name] as Map<String, dynamic>;
    if (raw['version'] != 1 || raw['difficulty'] != level.name) {
      throw const FormatException('Invalid difficulty');
    }
    final list = raw['mazes'] as List;
    if (list.isEmpty || list.length > 500) {
      throw const FormatException('Invalid maze count');
    }
    final pack = MazePack.fromJson(level, {...raw, 'language': language});
    final expected = switch (level) {
      MazeLevel.easy => 6,
      MazeLevel.medium => 7,
      MazeLevel.hard => 9,
    };
    if (pack.width != expected || pack.height != expected) {
      throw const FormatException('Invalid board size');
    }
    final ids = <String>{};
    for (final maze in pack.mazes) {
      if (maze.width != expected ||
          maze.height != expected ||
          !ids.add(maze.id) ||
          maze.id.length > 100) {
        throw const FormatException('Invalid maze');
      }
      final total = maze.width * maze.height;
      if (maze.walls.length != total ||
          maze.walls.any((w) => w < 0 || w > 15)) {
        throw const FormatException('Invalid walls');
      }
      if (maze.letters.isEmpty || maze.letters.length > total) {
        throw const FormatException('Invalid letters');
      }
      final occupied = <int>{};
      for (final l in maze.letters) {
        if (l.x < 0 ||
            l.x >= expected ||
            l.y < 0 ||
            l.y >= expected ||
            !script.validTile(l.letter) ||
            !occupied.add(l.y * expected + l.x)) {
          throw const FormatException('Invalid letter tile');
        }
      }
      for (var y = 0; y < expected; y++) {
        for (var x = 0; x < expected; x++) {
          for (final dir in MazeDir.values) {
            final nx = x + dir.dx, ny = y + dir.dy;
            final open = (maze.walls[y * expected + x] & dir.bit) == 0;
            if (nx < 0 || nx >= expected || ny < 0 || ny >= expected) {
              if (open) throw const FormatException('Open boundary');
            } else {
              final opposite = MazeDir.values[(dir.index + 2) % 4];
              if (open != maze.isOpen(nx, ny, opposite)) {
                throw const FormatException('Asymmetric wall');
              }
            }
          }
        }
      }
      if (maze.words.isEmpty ||
          maze.words.length > 5000 ||
          maze.words.any((w) => !script.validWord(w)) ||
          maze.words.toSet().length != maze.words.length) {
        throw const FormatException('Invalid words');
      }
      if (maze.commonWords.isEmpty ||
          maze.commonWords.length > 100 ||
          maze.commonWords.toSet().length != maze.commonWords.length ||
          !maze.commonWords.contains(maze.seedWord)) {
        throw const FormatException('Invalid goals');
      }
      for (final word in maze.commonWords) {
        if (!maze.words.contains(word)) {
          throw const FormatException('Missing goal');
        }
        final path = maze.commonPaths[word];
        if (path == null || path.isEmpty || path.length > total * 4) {
          throw const FormatException('Missing solution');
        }
        final spelling = StringBuffer();
        var tiles = 0;
        for (var i = 0; i < path.length; i++) {
          final cell = path[i];
          if (cell < 0 || cell >= total) {
            throw const FormatException('Invalid path');
          }
          if (maze.letterAt(cell % expected, cell ~/ expected) != null) tiles++;
          spelling.write(
            maze.letterAt(cell % expected, cell ~/ expected) ?? '',
          );
          if (i > 0) {
            final prev = path[i - 1];
            final dx = cell % expected - prev % expected,
                dy = cell ~/ expected - prev ~/ expected;
            final dirs = MazeDir.values.where((d) => d.dx == dx && d.dy == dy);
            if (dirs.isEmpty ||
                !maze.isOpen(prev % expected, prev ~/ expected, dirs.single)) {
              throw const FormatException('Path crosses wall');
            }
            if (i > 1 && cell == path[i - 2]) {
              throw const FormatException('Path requires undo');
            }
          }
        }
        if (spelling.toString() != word || tiles < script.minimumTiles) {
          throw const FormatException('Solution does not spell word');
        }
      }
    }
    levels[level] = pack;
  }
  return LanguageBundle(language, revision, levels);
}
