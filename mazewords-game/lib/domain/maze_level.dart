/// Difficulty tier for Maze Quest — picks which pre-built maze pack to
/// load and what target word length to reward. Tier scales with maze
/// size, letter count, and target word length:
///
/// | Level  | Grid | Letters | Target word | Bonus tier |
/// |--------|------|---------|-------------|------------|
/// | easy   | 6×6  | 8       | 3–4         | 5+         |
/// | medium | 7×7  | 12      | 5–6         | 7+         |
/// | hard   | 9×9  | 20      | 7–10        | 11+        |
enum MazeLevel { easy, medium, hard }

extension MazeLevelX on MazeLevel {
  String get label => switch (this) {
    MazeLevel.easy => 'Easy',
    MazeLevel.medium => 'Medium',
    MazeLevel.hard => 'Hard',
  };

  String get assetId => name;

  /// Free per-hunt time allowance; optional upgrades add one or two minutes.
  int get defaultSeconds => switch (this) {
    MazeLevel.easy => 90,
    MazeLevel.medium => 120,
    MazeLevel.hard => 180,
  };

  /// Maximum allowed invalid attempts before the hunt ends. Tighter at
  /// higher tiers so Hard isn't just "guess until you stumble on a word."
  int get invalidAttemptBudget => switch (this) {
    MazeLevel.easy => 6,
    MazeLevel.medium => 5,
    MazeLevel.hard => 5,
  };

  /// Target word length range — words inside this range score base
  /// points; longer words earn the progressive bonus.
  ({int min, int max}) get targetWordLen => switch (this) {
    MazeLevel.easy => (min: 3, max: 4),
    MazeLevel.medium => (min: 5, max: 6),
    MazeLevel.hard => (min: 7, max: 10),
  };
}
