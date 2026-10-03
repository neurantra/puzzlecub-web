/// AI difficulty levels selectable from Settings.
///
/// Each level maps to a search depth + a blunder probability. Real engines
/// don't blunder, but artificial blunders let Easy mode lose to kids while
/// still playing recognizable chess most of the time.
///
/// Phase 2 may layer further per-level differences on top: time pressure,
/// opening-book preferences, sub-optimal eval params for weaker levels.
enum Difficulty {
  easy,
  medium,
  hard;

  String get label => switch (this) {
    Difficulty.easy => 'Easy',
    Difficulty.medium => 'Medium',
    Difficulty.hard => 'Hard',
  };

  /// Plies the searcher looks ahead at this level.
  ///
  /// Easy and Medium are bounded by depth: they are meant to be beatable,
  /// and a fixed depth is what keeps them consistently so. Hard is bounded
  /// by the clock instead — its depth is a ceiling the search is not
  /// expected to reach, so that every improvement to search speed turns
  /// into extra plies rather than a shorter wait. Before this it was pinned
  /// at 6, which normal play finished in a median 0.8s of its budget,
  /// leaving most of the level's thinking time unused.
  int get searchDepth => switch (this) {
    Difficulty.easy => 2,
    Difficulty.medium => 5,
    Difficulty.hard => 20,
  };

  /// Wall-clock ceiling on one search at this level.
  ///
  /// For Easy and Medium, a backstop: normal play finishes the full depth
  /// far inside these, and the budget exists for the tail where depth stops
  /// predicting time at all — one tactical position took 11s at Medium's
  /// depth 4 unbudgeted. For Hard it is the thinking time itself, and the
  /// product knob for how long a player waits: the search starts a new
  /// iteration only while one looks likely to finish inside it, so a
  /// typical move ends somewhere between half the budget and all of it.
  /// Past the budget the search returns the last depth it actually
  /// finished, which is a slightly weaker move rather than no move at all.
  Duration get searchBudget => switch (this) {
    Difficulty.easy => const Duration(milliseconds: 500),
    Difficulty.medium => const Duration(milliseconds: 1500),
    Difficulty.hard => const Duration(seconds: 6),
  };

  /// Probability per turn of playing a random legal move instead of the
  /// search's best move. Easy makes real, recoverable mistakes; Medium and
  /// Hard always play their best.
  double get blunderChance => switch (this) {
    Difficulty.easy => 0.25,
    _ => 0.0,
  };

  /// All skill levels are available during the trial and after purchase.
  /// Keep the legacy progression API for saved stats and shared controls.
  int get unlockThreshold => 0;
  bool isUnlockedBy({required int easyWins, required int mediumWins}) => true;
  int winsRemainingToUnlock({required int easyWins, required int mediumWins}) =>
      0;
  Difficulty? get gatedBy => null;
}
