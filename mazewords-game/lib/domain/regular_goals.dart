import 'maze.dart';

/// Recover every familiar, traceable goal, including goals capped in old packs.
/// Rare dictionary entries remain bonuses; recognized words never change.
MazePack restoreRegularGoals(MazePack pack, Set<String> vocabulary) {
  final mazes = pack.mazes
      .map((maze) {
        final paths = Map<String, List<int>>.of(maze.commonPaths);
        final missing = maze.words
            .where((w) => vocabulary.contains(w) && !maze.isCommon(w))
            .toSet();
        if (missing.isEmpty) return maze;
        final prefixes = <String>{};
        for (final word in missing) {
          for (var i = 1; i <= word.length; i++) {
            prefixes.add(word.substring(0, i));
          }
        }
        final letters = {
          for (final tile in maze.letters)
            tile.y * maze.width + tile.x: tile.letter,
        };
        final queue = <({int cell, int previous, String word, int parent})>[];
        final visited = <(int, int, String)>{};
        void add(int cell, int previous, String word, int parent) {
          if (!prefixes.contains(word) ||
              !visited.add((cell, previous, word))) {
            return;
          }
          queue.add((
            cell: cell,
            previous: previous,
            word: word,
            parent: parent,
          ));
          if (missing.remove(word)) {
            final path = <int>[cell];
            var cursor = parent;
            while (cursor >= 0) {
              path.add(queue[cursor].cell);
              cursor = queue[cursor].parent;
            }
            paths[word] = path.reversed.toList(growable: false);
          }
        }

        for (final entry in letters.entries) {
          add(entry.key, -1, entry.value, -1);
        }
        // Match the build solver's undo rule and bounded search. An untraceable
        // or excessively expensive candidate stays a bonus, never a broken goal.
        for (
          var head = 0;
          head < queue.length && missing.isNotEmpty && visited.length < 250000;
          head++
        ) {
          final state = queue[head];
          for (final dir in MazeDir.values) {
            if (!maze.isOpen(
              state.cell % maze.width,
              state.cell ~/ maze.width,
              dir,
            )) {
              continue;
            }
            final next = state.cell + dir.dy * maze.width + dir.dx;
            if (next == state.previous) continue;
            add(next, state.cell, state.word + (letters[next] ?? ''), head);
          }
        }
        final commonWords = maze.words
            .where(
              (w) =>
                  maze.isCommon(w) ||
                  vocabulary.contains(w) && paths.containsKey(w),
            )
            .toList(growable: false);
        return Maze(
          language: maze.language,
          id: maze.id,
          seed: maze.seed,
          width: maze.width,
          height: maze.height,
          walls: maze.walls,
          letters: maze.letters,
          seedWord: maze.seedWord,
          words: maze.words,
          commonWords: commonWords,
          commonPaths: {for (final word in commonWords) word: paths[word]!},
        );
      })
      .toList(growable: false);
  return MazePack(
    version: pack.version,
    level: pack.level,
    width: pack.width,
    height: pack.height,
    letterCount: pack.letterCount,
    targetMin: pack.targetMin,
    targetMax: pack.targetMax,
    mazes: mazes,
  );
}
