import 'maze_level.dart';
import 'puzzle_language.dart';

/// Cardinal directions, indexed so bitfield math stays cheap and matches
/// the encoding used by `tools/build-maze-packs.mjs`:
///   bit 0 = N, bit 1 = E, bit 2 = S, bit 3 = W
enum MazeDir { north, east, south, west }

extension MazeDirX on MazeDir {
  int get bit => 1 << index;
  int get dx => switch (this) {
    MazeDir.north => 0,
    MazeDir.east => 1,
    MazeDir.south => 0,
    MazeDir.west => -1,
  };
  int get dy => switch (this) {
    MazeDir.north => -1,
    MazeDir.east => 0,
    MazeDir.south => 1,
    MazeDir.west => 0,
  };
}

/// One letter placed in a maze cell. Coordinates are zero-indexed from
/// the top-left of the grid.
class MazeLetter {
  const MazeLetter({required this.x, required this.y, required this.letter});

  final int x;
  final int y;
  final String letter; // One uppercase letter tile in the pack alphabet.

  factory MazeLetter.fromJson(Map<String, dynamic> json) => MazeLetter(
    x: json['x'] as int,
    y: json['y'] as int,
    letter: (json['letter'] as String).toUpperCase(),
  );
}

/// One playable maze. Carries the wall topology, letter placements, the
/// seeded common word (so we can show "today's hidden word: …" if we
/// ever want a hint UI), and a pre-solved list of every supported corpus word a
/// player can spell by tracing a continuous drag path through the maze.
///
/// The pre-solved list is the authority for "is this a valid word in
/// this maze" at runtime — no dictionary call needed. Built by the
/// release-time tool against the language-specific corpus.
class Maze {
  Maze({
    this.language = 'en',
    required this.id,
    required this.seed,
    required this.width,
    required this.height,
    required this.walls,
    required this.letters,
    required this.seedWord,
    required this.words,
    required this.commonWords,
    required this.commonPaths,
  }) : _letterByKey = {for (final l in letters) _key(l.x, l.y): l.letter},
       _wordSet = words.toSet(),
       _commonSet = commonWords.toSet();

  final String id;
  final String language;
  PuzzleLanguage get script => PuzzleLanguage.of(language);
  final int seed;
  final int width;
  final int height;

  /// One bitfield per cell (length = width × height, row-major). Bits
  /// follow [MazeDir.bit]: bit set = wall present on that side.
  final List<int> walls;

  final List<MazeLetter> letters;

  /// The common word the maze was seeded with — always present in
  /// [commonWords] and always traceable via at least one drag path.
  final String seedWord;

  /// Every word the maze contains, sorted alphabetically. Includes
  /// [seedWord] plus every other dictionary word that happens to be
  /// spellable along any maze-legal path. This is the *validation* set
  /// — any of these counts as a valid drag.
  final List<String> words;

  /// Every traceable word in the language's familiar-word vocabulary,
  /// without a per-difficulty count cap: the "Found X / Y" goal.
  /// Other dictionary words remain valid bonus discoveries.
  final List<String> commonWords;

  /// Pre-computed shortest path per common word, encoded as a flat
  /// list of row-major cell indices (`y * width + x`). Used by the
  /// end-of-round review panel: tapping a missed-word chip animates
  /// the AI tracing this path through the frozen maze so the player
  /// can see where the word was.
  final Map<String, List<int>> commonPaths;

  final Map<int, String> _letterByKey;
  final Set<String> _wordSet;
  final Set<String> _commonSet;

  static int _key(int x, int y) => y * 1000 + x; // 1000 > max maze width.

  /// Letter at the given cell, or `null` if it's a corridor cell.
  String? letterAt(int x, int y) => _letterByKey[_key(x, y)];

  /// True if a drag can move from `(x, y)` in [dir] without hitting a
  /// wall and without leaving the grid.
  bool isOpen(int x, int y, MazeDir dir) {
    if (x < 0 || y < 0 || x >= width || y >= height) return false;
    final nx = x + dir.dx;
    final ny = y + dir.dy;
    if (nx < 0 || ny < 0 || nx >= width || ny >= height) return false;
    final cell = walls[y * width + x];
    return (cell & dir.bit) == 0;
  }

  /// True if the maze recognizes [word] as a valid trace (any
  /// dictionary word — common or rare).
  bool contains(String word) => _wordSet.contains(word.toUpperCase());

  /// True if [word] is in the "common" subset — i.e. it counts toward
  /// the Found-X/Y goal, not just bonus discoveries.
  bool isCommon(String word) => _commonSet.contains(word.toUpperCase());

  factory Maze.fromJson(Map<String, dynamic> json, {String language = 'en'}) =>
      Maze(
        language: language,
        id: json['id'] as String,
        seed: (json['seed'] as num).toInt(),
        width: json['width'] as int,
        height: json['height'] as int,
        walls: (json['walls'] as List)
            .cast<num>()
            .map((n) => n.toInt())
            .toList(growable: false),
        letters: (json['letters'] as List)
            .map((e) => MazeLetter.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        seedWord: (json['seedWord'] as String).toUpperCase(),
        words: (json['words'] as List)
            .cast<String>()
            .map((w) => w.toUpperCase())
            .toList(growable: false),
        commonWords: ((json['commonWords'] as List?) ?? const <dynamic>[])
            .cast<String>()
            .map((w) => w.toUpperCase())
            .toList(growable: false),
        commonPaths:
            ((json['commonPaths'] as Map<String, dynamic>?) ??
                    const <String, dynamic>{})
                .map(
                  (k, v) => MapEntry(
                    k.toUpperCase(),
                    (v as List)
                        .cast<num>()
                        .map((n) => n.toInt())
                        .toList(growable: false),
                  ),
                ),
      );
}

/// A loaded difficulty pack — every maze for [level], plus the profile
/// the build tool used (grid size, letter count, target range).
class MazePack {
  const MazePack({
    required this.version,
    required this.level,
    required this.width,
    required this.height,
    required this.letterCount,
    required this.targetMin,
    required this.targetMax,
    required this.mazes,
  });

  final int version;
  final MazeLevel level;
  final int width;
  final int height;
  final int letterCount;
  final int targetMin;
  final int targetMax;
  final List<Maze> mazes;

  factory MazePack.fromJson(MazeLevel level, Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>;
    final target = profile['targetWordLen'] as Map<String, dynamic>;
    return MazePack(
      version: json['version'] as int? ?? 1,
      level: level,
      width: profile['width'] as int,
      height: profile['height'] as int,
      letterCount: profile['letterCount'] as int,
      targetMin: target['min'] as int,
      targetMax: target['max'] as int,
      mazes: (json['mazes'] as List)
          .map(
            (e) => Maze.fromJson(
              e as Map<String, dynamic>,
              language: json['language'] as String? ?? 'en',
            ),
          )
          .toList(growable: false),
    );
  }
}
