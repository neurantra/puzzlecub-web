import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wallet_record.dart';

/// Owns the player's coin balance and the bookkeeping that makes coin
/// movement to and from the shared vault recoverable.
///
/// Split out of `StatsService` deliberately. Coins used to be one int in
/// the stats blob; keeping them there would have coupled the ledger's
/// integrity to code that has no idea it exists, since every recorded game
/// rewrites that blob.
///
/// A note for anyone tidying this file later: the methods here are more
/// elaborate than the rest of the data layer, where the idiom is "mutate,
/// persist, done". That is not accidental and it is not over-engineering.
/// The separation of [completeBank] from [abandonBank] in particular looks
/// redundant and is the thing preventing duplicated coins.
///
/// vaultIds must never reach this file. Nothing here logs, throws, or
/// stores one — errors carry a transferId, which is useless to an attacker
/// and is the identifier you actually want when reading a crash.
class WalletService extends ChangeNotifier {
  WalletService._();
  static final WalletService instance = WalletService._();

  static const _kRecord = 'chaturang.wallet.record';

  /// The pre-wallet balance key. Read once at migration, then removed —
  /// but only after the record write has succeeded.
  static const _kLegacyCoins = 'chaturang.stats.coins';

  WalletRecord _record = const WalletRecord();
  WalletRecord get record => _record;

  int get balance => _record.balance;

  bool _loaded = false;
  Future<void>? _writes;
  Future<void>? _loading;
  Future<T> _serialize<T>(Future<T> Function() action) {
    final previous = _writes;
    final next = previous == null
        ? Future<T>.sync(action)
        : previous.then((_) => action());
    late final Future<void> settled;
    void clear() {
      if (identical(_writes, settled)) _writes = null;
    }

    settled = next.then<void>((_) => clear(), onError: (Object _) => clear());
    _writes = settled;
    return next;
  }

  /// True when the stored record could not be parsed and the balance came
  /// from the legacy key instead. Surfaced for tests and diagnostics.
  bool recoveredFromLegacy = false;

  Future<void> load() {
    if (_loading != null) return _loading!;
    if (_loaded) return Future.value();
    return _loading = _load()
        .catchError((Object e) {
          _loaded = false;
          throw e;
        })
        .whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRecord);

    if (raw == null) {
      // First run under the wallet, or a player upgrading. Seed from the
      // legacy int, and only drop that key once the record is safely
      // written — a crash between the two must leave the old balance
      // readable rather than nothing at all.
      final legacy = prefs.getInt(_kLegacyCoins) ?? 0;
      _record = WalletRecord(balance: legacy < 0 ? 0 : legacy);
      _loaded = true;
      await _persist();
      await prefs.remove(_kLegacyCoins);
      notifyListeners();
      return;
    }

    final decoded = WalletRecord.decode(raw);
    if (decoded == null) {
      // Unreadable JSON. Fall back to the legacy int if it is still there,
      // never to an empty record: zero is what a valid empty wallet looks
      // like, so defaulting to it would silently destroy a real balance
      // and look like a legitimate state afterwards.
      final legacy = prefs.getInt(_kLegacyCoins) ?? 0;
      _record = WalletRecord(balance: legacy < 0 ? 0 : legacy);
      recoveredFromLegacy = true;
    } else {
      _record = decoded;
    }
    _loaded = true;
    notifyListeners();
  }

  // ------------------------------ earning ------------------------------

  Future<void> addCoins(int amount) => _serialize(() async {
    if (amount <= 0) return;
    await load();
    await _commit(_record.copyWith(balance: _record.balance + amount));
  });

  /// Returns false when the player cannot afford [amount].
  Future<bool> spendCoins(int amount) => _serialize(() async {
    if (amount <= 0) return true;
    await load();
    if (_record.balance < amount) return false;
    await _commit(_record.copyWith(balance: _record.balance - amount));
    return true;
  });

  /// Balance and pending claim are committed together. A lost server response
  /// is retried with the same nonce, never charged a second time.
  Future<bool> beginBonus(String wallet, String nonce) => _serialize(() async {
    await load();
    if (_record.bonusDebits.containsKey(wallet)) return true;
    if (_record.balance < 100) return false;
    await _commit(
      _record.copyWith(
        balance: _record.balance - 100,
        bonusDebits: {..._record.bonusDebits, wallet: nonce},
      ),
    );
    return true;
  });

  Future<void> finishBonus(String wallet, {required bool refund}) =>
      _serialize(() async {
        await load();
        if (!_record.bonusDebits.containsKey(wallet)) return;
        final remaining = Map<String, String>.of(_record.bonusDebits)
          ..remove(wallet);
        await _commit(
          _record.copyWith(
            balance: _record.balance + (refund ? 100 : 0),
            bonusDebits: remaining,
          ),
        );
      });

  // ----------------------------- banking -------------------------------

  /// Debits [amount] and journals the pending bank in a single commit.
  ///
  /// Returns false when the balance is short. Idempotent on [transferId]:
  /// a repeat call for an id already in the journal is a no-op that
  /// returns true, so a retry cannot debit twice.
  Future<bool> beginBank({required String transferId, required int amount}) =>
      _serialize(() async {
        if (amount <= 0) return false;
        await load();
        if (_record.journal.any((e) => e.transferId == transferId)) return true;
        if (_record.balance < amount) return false;
        await _commit(
          _record.copyWith(
            balance: _record.balance - amount,
            journal: [
              ..._record.journal,
              PendingBank(transferId: transferId, amount: amount),
            ],
          ),
        );
        return true;
      });

  /// Clears the journal entry after the vault has accepted the transfer.
  /// The coins have already moved; this only closes the local liability.
  Future<void> completeBank(String transferId) => _serialize(() async {
    await load();
    if (!_record.journal.any((e) => e.transferId == transferId)) return;
    await _commit(
      _record.copyWith(
        journal: _record.journal
            .where((e) => e.transferId != transferId)
            .toList(),
      ),
    );
  });

  /// Refunds a bank the vault has *permanently rejected*.
  ///
  /// Permanent rejection only. Never call this on a network failure, a
  /// timeout, or any error that might still be in flight: the vault write
  /// may yet land, and refunding locally while it does is precisely the
  /// duplication the begin/complete ordering exists to prevent. If you are
  /// not certain the transfer will never be accepted, leave it in the
  /// journal — [pendingBanks] will replay it.
  ///
  /// It is separate from [completeBank] so that a reader has to notice the
  /// two are different. Collapsing them, or reaching this from a retry
  /// path, reintroduces the bug.
  Future<void> abandonBank(String transferId) => _serialize(() async {
    await load();
    final entry = _record.journal
        .where((e) => e.transferId == transferId)
        .cast<PendingBank?>()
        .firstWhere((e) => true, orElse: () => null);
    if (entry == null) return;
    await _commit(
      _record.copyWith(
        balance: _record.balance + entry.amount,
        journal: _record.journal
            .where((e) => e.transferId != transferId)
            .toList(),
      ),
    );
  });

  /// Banks debited locally whose vault write was never confirmed. Replay
  /// these at launch.
  List<PendingBank> get pendingBanks => List.unmodifiable(_record.journal);

  /// Pending banks that have failed enough times to be treated as stuck.
  ///
  /// These are the coins a player has lost sight of: debited locally, never
  /// accepted by the vault. Something must show them — a balance that
  /// quietly went down with no explanation is the worst available outcome,
  /// and is exactly what silent infinite retrying produces.
  List<PendingBank> get stuckBanks =>
      List.unmodifiable(_record.journal.where((e) => e.isStuck));

  /// Records that a replay failed, so repeated failure becomes visible
  /// rather than invisible. Never refunds — see [abandonBank].
  Future<void> noteBankAttemptFailed(String transferId) => _serialize(() async {
    await load();
    var changed = false;
    final next = _record.journal.map((e) {
      if (e.transferId != transferId) return e;
      changed = true;
      return e.retried;
    }).toList();
    if (!changed) return;
    await _commit(_record.copyWith(journal: next));
  });

  // ---------------------------- withdrawing ----------------------------

  /// Credits a withdrawal, recording [transferId] so a replay cannot
  /// credit it again. Returns false when it has already been credited.
  Future<bool> creditWithdrawal({
    required String transferId,
    required int amount,
  }) => _serialize(() async {
    if (amount <= 0) return false;
    await load();
    if (hasCredited(transferId)) return false;
    await _commit(
      _record
          .copyWith(
            balance: _record.balance + amount,
            applied: [
              ..._record.applied,
              AppliedWithdrawal(transferId: transferId, acked: false),
            ],
          )
          .pruned,
    );
    return true;
  });

  bool hasCredited(String transferId) =>
      _record.applied.any((e) => e.transferId == transferId);

  Future<void> markWithdrawalAcked(String transferId) => _serialize(() async {
    await load();
    var changed = false;
    final next = _record.applied.map((e) {
      if (e.transferId == transferId && !e.acked) {
        changed = true;
        return e.ackedCopy();
      }
      return e;
    }).toList();
    if (!changed) return;
    await _commit(_record.copyWith(applied: next).pruned);
  });

  /// Withdrawals credited locally that the vault has not been told about.
  List<String> get unackedWithdrawals => List.unmodifiable(
    _record.applied.where((e) => !e.acked).map((e) => e.transferId),
  );

  // ------------------------------ plumbing -----------------------------

  Future<void> resetAll() => _serialize(() async {
    _loaded = true;
    recoveredFromLegacy = false;
    await _commit(const WalletRecord());
  });

  Future<void> _commit(WalletRecord next) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_kRecord, next.encode())) {
      throw StateError('Could not save coins. Please retry.');
    }
    _record = next;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_kRecord, _record.encode())) {
      throw StateError('Could not save coins. Please retry.');
    }
  }

  @visibleForTesting
  void resetForTest() {
    _record = const WalletRecord();
    _loaded = false;
    _loading = null;
    _writes = null;
    recoveredFromLegacy = false;
  }
}
