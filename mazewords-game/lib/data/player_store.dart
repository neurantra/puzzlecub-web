import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/maze_level.dart';
import '../domain/puzzle_language.dart';
import '../domain/maze_theme.dart';
import '../domain/hunt_options.dart';
import '../services/audience.dart';

class PlayerStore extends ChangeNotifier {
  PlayerStore(this.prefs, {Future<bool> Function(String)? persist})
    : _persist = persist ?? ((value) => prefs.setString(storageKey, value)) {
    final raw = prefs.getString(storageKey);
    if (raw != null) {
      try {
        _data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        /* An unreadable save should not prevent offline play. */
      }
    }
  }
  static const storageKey = 'maze_words.player.v1';
  final SharedPreferences prefs;
  final Future<bool> Function(String) _persist;
  bool walletBusy = false;
  void walletChanged() => notifyListeners();
  List<Map<String, dynamic>> get vaultTransfers =>
      ((_data['vaultTransfers'] as List?) ?? [])
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
  Map<String, dynamic> _data = {};
  Future<void> _pending = Future.value();
  String? saveError;
  String get language =>
      PuzzleLanguage.supports(_data['language'] as String? ?? '')
      ? _data['language'] as String
      : 'en';
  Future<void> selectLanguage(String value) => _change((data) {
    if (!PuzzleLanguage.supports(value)) throw ArgumentError.value(value);
    data['language'] = value;
  }, durable: true);
  MazeTheme get mazeTheme => MazeTheme.values.firstWhere(
    (theme) => theme.name == _data['mazeTheme'],
    orElse: () => MazeTheme.hedge,
  );
  int get coins => (_data['coins'] as int?) ?? 30;
  int get rounds => (_data['rounds'] as int?) ?? 0;
  int get solvedTrails => (_data['solvedTrails'] as int?) ?? 0;
  bool get interstitialDue =>
      solvedTrails - ((_data['adCheckpoint'] as int?) ?? 0) >= 3;
  Future<void> consumeInterstitialBreak() => set('adCheckpoint', solvedTrails);
  int get words => (_data['words'] as int?) ?? 0;
  bool get tapLetters => (_data['tapLetters'] as bool?) ?? false;
  bool get sound => (_data['sound'] as bool?) ?? true;
  bool get haptics => (_data['haptics'] as bool?) ?? true;
  bool get onboarded => (_data['onboarded'] as bool?) ?? false;
  int? get birthYear => _data['birthYear'] as int?;
  Audience get audience => Audience(birthYear);
  // Keep legacy declarations until the player supplies a real birth year.
  bool get adult => audience.answered
      ? audience.externalServicesAllowed
      : ((_data['adult'] as bool?) ?? false);
  Future<void> setBirthYear(int year) => _change((data) {
    if (!Audience(year).answered) throw ArgumentError.value(year);
    if (walletBusy || vaultTransfers.isNotEmpty) {
      throw StateError('Finish the transfer first');
    }
    data['birthYear'] = year;
    data['onboarded'] = true;
    data.remove('adult');
  }, durable: true);
  int best(MazeLevel level, {bool relaxed = false, String? language}) =>
      (_data[_bestKey(level, relaxed, language ?? this.language)] as int?) ?? 0;
  String _bestKey(MazeLevel level, bool relaxed, String language) =>
      language == 'en'
      ? 'best.${level.name}.$relaxed'
      : 'best.$language.${level.name}.$relaxed';
  bool dailyDone(int seed) =>
      _data['daily'] == seed ||
      ((_data['dailyRewards'] as List?) ?? const []).contains(seed);

  Future<void> set(String key, Object value) => _change((data) {
    data[key] = value;
  });

  Future<bool> spend(int amount) async {
    if (walletBusy) return false;
    return _change((data) {
      if (walletBusy || amount < 0 || coins < amount) return false;
      data['coins'] = coins - amount;
      return true;
    });
  }

  HuntOptions huntOptions(MazeLevel level) {
    final value = _data['huntOptions.${level.name}'];
    int tier(String key) {
      final v = value is Map ? value[key] : null;
      return v is int && v >= 0 && v <= 2 ? v : 0;
    }

    return HuntOptions(timeTier: tier('time'), attemptTier: tier('attempts'));
  }

  Future<void> setHuntOptions(MazeLevel level, HuntOptions options) =>
      _change((data) {
        data['huntOptions.${level.name}'] = {
          'time': options.timeTier,
          'attempts': options.attemptTier,
        };
      }, durable: true);

  /// A paid hunt starts only after its single combined debit is durable.
  Future<bool> purchaseHunt(int cost) => _change((data) {
    if (cost < 0 || cost > 120 || cost % 30 != 0) {
      throw ArgumentError.value(cost);
    }
    if (walletBusy || vaultTransfers.isNotEmpty || coins < cost) return false;
    data['coins'] = coins - cost;
    return true;
  }, durable: true);

  Future<void> reward(int amount) => _change((data) {
    if (amount < 0) throw ArgumentError.value(amount);
    data['coins'] = coins + amount;
  });

  Future<int> record({
    required MazeLevel level,
    required bool relaxed,
    required int score,
    required int found,
    int? daily,
    bool cleared = false,
    String? language,
  }) => _change((data) {
    final eligible = daily == null || !dailyDone(daily);
    final earned = eligible ? (score ~/ 10) + (daily != null ? 20 : 0) : 0;
    data['coins'] = coins + earned;
    data['rounds'] = rounds + 1;
    if (cleared && eligible) data['solvedTrails'] = solvedTrails + 1;
    data['words'] = words + found;
    final selected = language ?? this.language;
    final key = _bestKey(level, relaxed, selected);
    if (score > best(level, relaxed: relaxed, language: selected)) {
      data[key] = score;
    }
    if (daily != null) {
      final days = <dynamic>{
        ...((_data['dailyRewards'] as List?) ?? []),
        if (_data['daily'] != null) _data['daily'],
        daily,
      };
      data['dailyRewards'] = days.toList();
      data['daily'] = daily;
    }
    return earned;
  });

  /// Debit + intent share one durable snapshot. No network write may precede it.
  Future<void> beginTransfer(Map<String, dynamic> entry) => _change((data) {
    if (vaultTransfers.isNotEmpty) throw StateError('Pending transfer');
    final amount = entry['amount'] as int;
    final bank = entry['kind'] == 'bank';
    if (amount <= 0 || amount > 10000000 || (bank && amount > coins)) {
      throw StateError('Invalid transfer amount');
    }
    if (bank) data['coins'] = coins - amount;
    data['vaultTransfers'] = [Map<String, dynamic>.from(entry)];
  }, durable: true);

  /// Credit and receipt are indivisible; a retry can never credit twice.
  Future<void> creditTransfer(String id) => _change((data) {
    final entries = vaultTransfers;
    final entry = entries.singleWhere((v) => v['id'] == id);
    if (entry['credited'] == true) return;
    final amount = entry['amount'] as int;
    if (entry['kind'] != 'withdraw' || coins + amount > 10000000) {
      throw StateError('Cannot credit transfer');
    }
    data['coins'] = coins + amount;
    entry['credited'] = true;
    data['vaultTransfers'] = entries;
  }, durable: true);

  Future<void> completeTransfer(String id) => _change((data) {
    data['vaultTransfers'] = vaultTransfers
        .where((v) => v['id'] != id)
        .toList();
  }, durable: true);

  /// All writers, including rewards arriving during a transfer, share one queue.
  /// Durable failures leave the previous snapshot intact and propagate to vault.
  Future<T> _change<T>(
    T Function(Map<String, dynamic>) change, {
    bool durable = false,
  }) {
    final result = _pending.then((_) async {
      final data = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(_data)) as Map,
      );
      final value = change(data);
      try {
        if (!await _persist(jsonEncode(data))) throw StateError('Save failed');
        saveError = null;
      } catch (_) {
        saveError =
            'Progress could not be saved. Keep the app open and try again.';
        if (durable) {
          notifyListeners();
          rethrow;
        }
      }
      _data = data;
      notifyListeners();
      return value;
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
