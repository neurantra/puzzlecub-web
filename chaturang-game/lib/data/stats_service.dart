import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/difficulty.dart';
import '../engine/game_state.dart';
import '../engine/pieces.dart';
import 'wallet_service.dart';

/// Mutable snapshot of the player's lifetime statistics. Held by
/// [StatsService] and persisted to shared_preferences after each
/// recorded game.
class PlayerStats {
  PlayerStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.gamesDrawn = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPlayDate,
    this.easyWins = 0,
    this.mediumWins = 0,
    this.hardWins = 0,
    this.onlineWon = 0,
    this.onlineLost = 0,
    this.onlineDrawn = 0,
  });

  int gamesPlayed;
  int gamesWon;
  int gamesLost;
  int gamesDrawn;
  int currentStreak;
  int longestStreak;

  /// Midnight-normalized timestamp of the last game played. Null when no
  /// game has been recorded yet.
  DateTime? lastPlayDate;

  /// Per-difficulty win counters. Drive the unlock progression in
  /// Settings — Medium unlocks after [easyWins] reaches the threshold,
  /// Hard unlocks after [mediumWins] does.
  int easyWins;
  int mediumWins;
  int hardWins;

  /// Lifetime online (human-vs-human) outcomes, kept separate from the
  /// AI-mode counters so wins against random humans never inflate the
  /// difficulty-unlock progression or the daily-streak ladder.
  /// Maintained via [StatsService.recordOnlineGame].
  int onlineWon;
  int onlineLost;
  int onlineDrawn;

  int get onlineGamesPlayed => onlineWon + onlineLost + onlineDrawn;
}

/// From the human's perspective.
enum GameOutcome { won, lost, drawn }

/// Coins awarded per outcome. Tunable as we learn what feels right.
class CoinRewards {
  CoinRewards._();
  static const int win = 10;
  static const int draw = 5;
  static const int loss = 1; // mercy point for finishing the game
}

/// Coins spent on in-game services.
class CoinCosts {
  CoinCosts._();
  static const int hint = 25;
}

/// Lifetime-stats singleton backed by shared_preferences.
///
/// Survives process restarts. Reads happen lazily (first [load]); writes
/// happen synchronously to the in-memory state plus asynchronously to
/// disk after each [recordGame]. Listeners are notified after every
/// state change so the Stats modal updates live.
class StatsService extends ChangeNotifier {
  StatsService._();
  static final StatsService instance = StatsService._();

  // ---------------------------- storage keys ----------------------------
  static const _kGamesPlayed = 'chaturang.stats.gamesPlayed';
  static const _kGamesWon = 'chaturang.stats.gamesWon';
  static const _kGamesLost = 'chaturang.stats.gamesLost';
  static const _kGamesDrawn = 'chaturang.stats.gamesDrawn';
  static const _kCurrentStreak = 'chaturang.stats.currentStreak';
  static const _kLongestStreak = 'chaturang.stats.longestStreak';
  static const _kLastPlayDate =
      'chaturang.stats.lastPlayDate'; // ms since epoch
  static const _kEasyWins = 'chaturang.stats.easyWins';
  static const _kMediumWins = 'chaturang.stats.mediumWins';
  static const _kHardWins = 'chaturang.stats.hardWins';
  static const _kOnlineWon = 'chaturang.stats.onlineWon';
  static const _kOnlineLost = 'chaturang.stats.onlineLost';
  static const _kOnlineDrawn = 'chaturang.stats.onlineDrawn';

  PlayerStats _stats = PlayerStats();
  PlayerStats get stats => _stats;

  bool _loaded = false;

  /// Pulls values from shared_preferences into memory. Safe to call
  /// multiple times — subsequent calls are no-ops.
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final lastPlayMs = prefs.getInt(_kLastPlayDate);
    _stats = PlayerStats(
      gamesPlayed: prefs.getInt(_kGamesPlayed) ?? 0,
      gamesWon: prefs.getInt(_kGamesWon) ?? 0,
      gamesLost: prefs.getInt(_kGamesLost) ?? 0,
      gamesDrawn: prefs.getInt(_kGamesDrawn) ?? 0,
      currentStreak: prefs.getInt(_kCurrentStreak) ?? 0,
      longestStreak: prefs.getInt(_kLongestStreak) ?? 0,
      lastPlayDate: lastPlayMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastPlayMs),
      easyWins: prefs.getInt(_kEasyWins) ?? 0,
      mediumWins: prefs.getInt(_kMediumWins) ?? 0,
      hardWins: prefs.getInt(_kHardWins) ?? 0,
      onlineWon: prefs.getInt(_kOnlineWon) ?? 0,
      onlineLost: prefs.getInt(_kOnlineLost) ?? 0,
      onlineDrawn: prefs.getInt(_kOnlineDrawn) ?? 0,
    );
    await WalletService.instance.load();
    WalletService.instance.removeListener(notifyListeners);
    WalletService.instance.addListener(notifyListeners);
    _loaded = true;
    notifyListeners();
  }

  /// Records a finished game, awards coins, increments the per-difficulty
  /// win counter (for unlock progression), and updates the day streak.
  /// Pass [now] only in tests; production uses [DateTime.now].
  Future<void> recordGame({
    required GameResult result,
    required Side humanSide,
    required Difficulty difficulty,
    DateTime? now,
  }) async {
    final outcome = _outcomeFor(result, humanSide);
    if (outcome == null) return; // ongoing — nothing to record
    // Ensure the on-disk snapshot is in memory before mutating, so an
    // early game (before the startup load() resolves) can't persist a
    // zeroed snapshot over real stats. load() is idempotent.
    await load();
    final today = _midnight(now ?? DateTime.now());

    int award = 0;
    _stats.gamesPlayed++;
    switch (outcome) {
      case GameOutcome.won:
        _stats.gamesWon++;
        award = CoinRewards.win;
        switch (difficulty) {
          case Difficulty.easy:
            _stats.easyWins++;
          case Difficulty.medium:
            _stats.mediumWins++;
          case Difficulty.hard:
            _stats.hardWins++;
        }
      case GameOutcome.lost:
        _stats.gamesLost++;
        award = CoinRewards.loss;
      case GameOutcome.drawn:
        _stats.gamesDrawn++;
        award = CoinRewards.draw;
    }

    final last = _stats.lastPlayDate;
    if (last == null) {
      _stats.currentStreak = 1;
    } else {
      final lastMidnight = _midnight(last);
      final dayDiff = today.difference(lastMidnight).inDays;
      if (dayDiff == 0) {
        // Already played today — streak unchanged.
      } else if (dayDiff == 1) {
        _stats.currentStreak++;
      } else {
        _stats.currentStreak = 1;
      }
    }
    if (_stats.currentStreak > _stats.longestStreak) {
      _stats.longestStreak = _stats.currentStreak;
    }
    _stats.lastPlayDate = today;

    notifyListeners();
    await _persist();
    await WalletService.instance.addCoins(award);
  }

  /// Records a finished online (human-vs-human) game. Updates the
  /// dedicated online W-L-D counters and nothing else — no coins are
  /// awarded, the AI-mode `gamesWon`/`gamesPlayed` counters and the
  /// per-difficulty unlock counters aren't touched, and the daily
  /// streak isn't advanced (online play doesn't gate any feature, and
  /// keeping the streak strictly AI-mode preserves its meaning).
  Future<void> recordOnlineGame({
    required GameResult result,
    required Side localSide,
  }) async {
    final outcome = _outcomeFor(result, localSide);
    if (outcome == null) return;
    await load();
    switch (outcome) {
      case GameOutcome.won:
        _stats.onlineWon++;
      case GameOutcome.lost:
        _stats.onlineLost++;
      case GameOutcome.drawn:
        _stats.onlineDrawn++;
    }
    notifyListeners();
    await _persist();
  }

  /// The player's coin balance. Owned by [WalletService], not by
  /// [PlayerStats] — the balance moves together with a transfer journal
  /// that has to be written in the same commit, which the stats blob
  /// cannot provide. Kept here as a forwarding getter so callers that only
  /// want a number don't need to know that.
  int get coins => WalletService.instance.balance;

  /// Adds [amount] coins (e.g. from a rewarded ad).
  Future<void> addCoins(int amount) => WalletService.instance.addCoins(amount);

  /// Spends [amount] coins. Returns true if successful, false if the
  /// player doesn't have enough.
  Future<bool> spendCoins(int amount) =>
      WalletService.instance.spendCoins(amount);

  /// Wipes everything. Used by debug tooling / "Reset stats" buttons.
  Future<void> resetAll() async {
    // Mark as loaded so a still-pending startup load() can't repopulate
    // the just-wiped snapshot from disk.
    _loaded = true;
    _stats = PlayerStats();
    notifyListeners();
    await _persist();
    // Coins live in the wallet now, so "reset stats" has to reach across
    // to clear them as it always did. This discards any pending bank
    // journal with them; acceptable for a debug/reset affordance, and
    // noted because it is the one place local coin state is destroyed
    // without the vault being told.
    await WalletService.instance.resetAll();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGamesPlayed, _stats.gamesPlayed);
    await prefs.setInt(_kGamesWon, _stats.gamesWon);
    await prefs.setInt(_kGamesLost, _stats.gamesLost);
    await prefs.setInt(_kGamesDrawn, _stats.gamesDrawn);
    await prefs.setInt(_kCurrentStreak, _stats.currentStreak);
    await prefs.setInt(_kLongestStreak, _stats.longestStreak);
    if (_stats.lastPlayDate != null) {
      await prefs.setInt(
        _kLastPlayDate,
        _stats.lastPlayDate!.millisecondsSinceEpoch,
      );
    }
    await prefs.setInt(_kEasyWins, _stats.easyWins);
    await prefs.setInt(_kMediumWins, _stats.mediumWins);
    await prefs.setInt(_kHardWins, _stats.hardWins);
    await prefs.setInt(_kOnlineWon, _stats.onlineWon);
    await prefs.setInt(_kOnlineLost, _stats.onlineLost);
    await prefs.setInt(_kOnlineDrawn, _stats.onlineDrawn);
  }

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  static GameOutcome? _outcomeFor(GameResult result, Side humanSide) {
    return switch (result) {
      Checkmate(:final winner) =>
        winner == humanSide ? GameOutcome.won : GameOutcome.lost,
      Forfeit(:final winner) =>
        winner == humanSide ? GameOutcome.won : GameOutcome.lost,
      Timeout(:final winner) =>
        winner == humanSide ? GameOutcome.won : GameOutcome.lost,
      Stalemate() => GameOutcome.drawn,
      DrawByAgreement() => GameOutcome.drawn,
      MoveLimitDraw() => GameOutcome.drawn,
      RepetitionDraw() => GameOutcome.drawn,
      InsufficientMaterial() => GameOutcome.drawn,
      Ongoing() => null,
    };
  }
}
