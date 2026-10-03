import 'maze_level.dart';

/// Score awarded for finding a word of [wordLen] letters in a [level]
/// maze.
///
/// Base score scales linearly with word length:
///   base = wordLen * 10
///
/// Words longer than the level's target range earn a *progressive*
/// bonus — each extra letter beyond the cap is worth more than the
/// last. This makes a 6-letter find on Easy genuinely impressive
/// without punishing players who only spot 3-letter words.
///
/// Bonus formula (for length L over targetMax T):
///   bonus = 5 + 10 + 15 + ... up to (L - T) terms
///         = 5 * sum(1..L-T)
///         = 5 * (L-T) * (L-T+1) / 2
///
/// Example for Easy (targetMax = 4):
///   3-letter: base 30,  bonus 0   -> 30
///   4-letter: base 40,  bonus 0   -> 40
///   5-letter: base 50,  bonus 5   -> 55
///   6-letter: base 60,  bonus 15  -> 75
///   7-letter: base 70,  bonus 30  -> 100
///   8-letter: base 80,  bonus 50  -> 130
int scoreForWord({required MazeLevel level, required int wordLen}) {
  final base = wordLen * 10;
  final over = wordLen - level.targetWordLen.max;
  if (over <= 0) return base;
  final bonus = 5 * over * (over + 1) ~/ 2;
  return base + bonus;
}

/// Flat bonus awarded when the player taps "End Hunt" *and* has found
/// every COMMON word in the maze. Encourages completionism without
/// rewarding early-abandonment. Rare ENABLE-only finds aren't part of
/// the goal (most players never spot them), so they don't gate the
/// perfect-clear bonus.
const int kMazePerfectClearBonus = 100;

/// Flat extra points awarded for finding a "rare" word — a valid
/// ENABLE entry that wasn't in the common-words list. Recognises the
/// achievement of spotting an obscure word without leaning on it as
/// the main score lever.
const int kMazeRareWordBonus = 25;

/// Coin cost to peek one hint — briefly highlights a cell that starts
/// an unfound common word. Mirrors WordQuest's hint pricing.
const int kMazeHintCost = 5;

/// Coin cost of the "Infinite Time" power-up on the setup screen.
const int kMazeInfiniteTimeCost = 20;

/// Coin cost of the "Infinite Attempts" power-up on the setup screen.
/// Slightly cheaper than time because time is the more limiting
/// resource for completionists.
const int kMazeInfiniteAttemptsCost = 15;

/// Threshold below which a drag-attempt's resulting letter sequence is
/// silently discarded (treated as a finger-wobble, not an attempt).
/// Doesn't count against the invalid-attempt budget.
const int kMazeMinAttemptLen = 2;
