import 'maze_level.dart';

/// Consumable upgrades for one hunt; each category is selected independently.
class HuntOptions {
  const HuntOptions({this.timeTier = 0, this.attemptTier = 0})
    : assert(timeTier >= 0 && timeTier <= 2),
      assert(attemptTier >= 0 && attemptTier <= 2);
  final int timeTier, attemptTier;
  String get priceLabel => cost == 0 ? 'Free' : '$cost coins';
  String summary(MazeLevel level) =>
      '${seconds(level) ~/ 60}:${(seconds(level) % 60).toString().padLeft(2, '0')} · ${attempts(level)} invalid attempts · $priceLabel per hunt';
  int get cost => 30 * (timeTier + attemptTier);
  int seconds(MazeLevel level) => level.defaultSeconds + timeTier * 60;
  int attempts(MazeLevel level) => level.invalidAttemptBudget + attemptTier * 2;
}
