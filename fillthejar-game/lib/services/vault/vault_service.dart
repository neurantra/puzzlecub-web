import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../game/session.dart';

class VaultFailure implements Exception {
  final String message;
  const VaultFailure(this.message);
  @override
  String toString() => message;
}

abstract class VaultRemote {
  bool get linked;
  Future<bool> available();
  Future<void> ready();
  Future<int> balance();
  Future<String> issueCode();
  Future<void> redeem(String code);
  Future<void> unlink();
  Future<void> apply(String id, int amount, String kind);
  Future<void> acknowledge(String id);
}

/// The journal is saved together with game coins, before contacting Firebase.
/// An unknown server outcome is retried with the SAME immutable transfer ID.
class VaultService extends ChangeNotifier {
  final GameSession game;
  final VaultRemote remote;
  final Future<void> Function(String) persist;
  bool busy = false, live = false;
  int? balance;
  String? error, code;
  VaultService(this.game, this.remote, this.persist);
  bool get linked => remote.linked;
  bool get pending => game.vaultTransfers.isNotEmpty;

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    if (game.solving || game.rewardBusy) {
      error = 'Let the solve or reward finish, then try again.';
      notifyListeners();
      return;
    }
    busy = game.walletBusy = true;
    error = null;
    game.refresh();
    notifyListeners();
    try {
      await action();
    } catch (e) {
      // Never expose raw Firebase errors: their paths can contain vault IDs.
      error = e is VaultFailure
          ? e.message
          : 'The vault could not finish. Check your connection and try again.';
    } finally {
      busy = game.walletBusy = false;
      game.refresh();
      notifyListeners();
    }
  }

  Future<void> refresh() => _run(() async {
    live = await remote.available();
    balance = null;
    if (!linked || (!live && !pending)) return;
    await remote.ready();
    await _recover();
    balance = await remote.balance();
  });

  Future<void> showCode() => _run(() async {
    _requireLive();
    await remote.ready();
    code = await remote.issueCode();
    balance = await remote.balance();
  });

  Future<void> link(String value) => _run(() async {
    _requireLive();
    _requireSettled();
    await remote.ready();
    await remote.redeem(value);
    code = null;
    balance = await remote.balance();
  });

  Future<void> unlink() => _run(() async {
    _requireLive();
    _requireSettled();
    await remote.ready();
    await remote.unlink();
    code = null;
    balance = null;
  });

  void _requireLive() {
    if (!live) {
      throw const VaultFailure('Shared transfers are not available right now.');
    }
  }

  void _requireSettled() {
    if (pending) {
      throw const VaultFailure(
        'Finish the pending transfer before linking another vault.',
      );
    }
  }

  Future<void> transfer(int amount, {required bool bank}) => _run(() async {
    _requireLive();
    _requireSettled();
    if (!linked) throw const VaultFailure('Link a game first.');
    if (amount <= 0 || amount > 10000000 || (bank && amount > game.coins)) {
      throw const VaultFailure('There are not enough coins for that transfer.');
    }
    await remote.ready();
    final current = await remote.balance();
    if ((!bank && amount > current) ||
        (bank && current + amount > 10000000) ||
        (!bank && game.coins + amount > 10000000)) {
      throw const VaultFailure('That amount is outside the available balance.');
    }
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
    final rng = Random.secure();
    final entry = <String, dynamic>{
      'id': List.generate(
        22,
        (_) => alphabet[rng.nextInt(alphabet.length)],
      ).join(),
      'amount': amount,
      'kind': bank ? 'bank' : 'withdraw',
      'credited': false,
    };
    await _commit(() {
      if (bank) game.coins -= amount;
      game.vaultTransfers.add(entry);
    });
    await _recover();
    balance = await remote.balance();
  });

  Future<void> _commit(void Function() change) async {
    final coins = game.coins;
    final journal = game.vaultTransfers
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
    change();
    try {
      await persist(game.encode());
    } catch (_) {
      game.coins = coins;
      game.vaultTransfers = journal;
      throw const VaultFailure(
        'Coins could not be saved on this device. Try again before transferring.',
      );
    }
  }

  Future<void> _recover() async {
    for (final entry in List.of(game.vaultTransfers)) {
      final id = entry['id'] as String;
      final amount = entry['amount'] as int;
      final kind = entry['kind'] as String;
      if (entry['credited'] != true) {
        await remote.apply(id, amount, kind);
        if (kind == 'withdraw') {
          await _commit(() {
            game.coins += amount;
            entry['credited'] = true;
          });
        }
      }
      if (kind == 'withdraw') await remote.acknowledge(id);
      await _commit(
        () => game.vaultTransfers.removeWhere((v) => v['id'] == id),
      );
    }
  }
}
