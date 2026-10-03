import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/services/vault/vault_service.dart';

class FakeVault implements VaultRemote {
  @override
  bool linked = true;
  bool live = true, offline = false, loseResponse = false, failAck = false;
  int coins = 100, calls = 0, requests = 0;
  Completer<void>? hold;
  final Set<String> applied = {}, acked = {};
  @override
  Future<bool> available() async {
    requests++;
    return live;
  }

  @override
  Future<void> ready() async {
    if (offline) throw const VaultFailure('Offline');
  }

  @override
  Future<int> balance() async => coins;
  @override
  Future<String> issueCode() async {
    linked = true;
    return 'ABC234';
  }

  @override
  Future<void> redeem(String code) async {
    linked = true;
  }

  @override
  Future<void> unlink() async {
    linked = false;
  }

  @override
  Future<void> apply(String id, int amount, String kind) async {
    calls++;
    if (hold != null) await hold!.future;
    if (applied.add(id)) coins += kind == 'bank' ? amount : -amount;
    if (loseResponse) {
      loseResponse = false;
      throw TimeoutException('response lost');
    }
  }

  @override
  Future<void> acknowledge(String id) async {
    if (failAck) throw TimeoutException('ack lost');
    acked.add(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlayerStore game;
  late FakeVault remote;
  late VaultService vault;
  late String saved;
  var writes = 0, failWrite = 0;
  Future<bool> persist(String value) async {
    writes++;
    if (writes == failWrite) return false;
    saved = value;
    return true;
  }

  Future<PlayerStore> restore(String value) async {
    SharedPreferences.setMockInitialValues({PlayerStore.storageKey: value});
    return PlayerStore(await SharedPreferences.getInstance(), persist: persist);
  }

  setUp(() async {
    saved = '{"coins":60,"adult":true,"onboarded":true}';
    writes = 0;
    failWrite = 0;
    game = await restore(saved);
    remote = FakeVault();
    vault = VaultService(game, remote);
    await vault.refresh();
  });
  test(
    'bank persists debit first and retries a lost response exactly once after restart',
    () async {
      remote.loseResponse = true;
      await vault.transfer(25, bank: true);
      expect(game.coins, 35);
      expect(remote.coins, 125);
      expect(vault.pending, true);
      game = await restore(saved);
      vault = VaultService(game, remote);
      await vault.refresh();
      expect(game.coins, 35);
      expect(remote.coins, 125);
      expect(vault.pending, false);
    },
  );
  test(
    'withdraw intent recovers crash after remote debit, before local credit',
    () async {
      remote.loseResponse = true;
      await vault.transfer(100, bank: false);
      expect(remote.coins, 0);
      expect(game.coins, 60);
      game = await restore(saved);
      vault = VaultService(game, remote);
      await vault.refresh();
      await vault.refresh();
      expect(remote.coins, 0);
      expect(game.coins, 160);
      expect(vault.pending, false);
      expect(remote.acked.length, 1);
    },
  );
  test(
    'lost acknowledgement never credits the same withdrawal again',
    () async {
      remote.failAck = true;
      await vault.transfer(50, bank: false);
      expect(game.coins, 110);
      expect(vault.pending, true);
      game = await restore(saved);
      vault = VaultService(game, remote);
      remote.failAck = false;
      await vault.refresh();
      expect(game.coins, 110);
      expect(remote.coins, 50);
      expect(vault.pending, false);
    },
  );
  test(
    'failed initial save cannot debit local coins or contact transfer endpoint',
    () async {
      failWrite = 1;
      await vault.transfer(25, bank: true);
      expect(game.coins, 60);
      expect(remote.calls, 0);
      expect(vault.pending, false);
    },
  );
  test(
    'failed local credit save recovers from the persisted withdrawal intent',
    () async {
      failWrite = 2;
      await vault.transfer(30, bank: false);
      expect(game.coins, 60);
      expect(remote.coins, 70);
      expect(vault.pending, true);
      game = await restore(saved);
      vault = VaultService(game, remote);
      await vault.refresh();
      expect(game.coins, 90);
      expect(remote.coins, 70);
      expect(vault.pending, false);
    },
  );
  test('failed journal cleanup remains idempotent', () async {
    failWrite = 2;
    await vault.transfer(10, bank: true);
    expect(vault.pending, true);
    await vault.refresh();
    expect(game.coins, 50);
    expect(remote.coins, 110);
    expect(vault.pending, false);
  });
  test('offline requests never reserve coins', () async {
    remote.offline = true;
    await vault.transfer(25, bank: true);
    expect(game.coins, 60);
    expect(vault.pending, false);
    expect(remote.calls, 0);
  });
  test(
    'pending transfer prevents unlink, relink, and a second transfer',
    () async {
      remote.loseResponse = true;
      await vault.transfer(10, bank: true);
      await vault.unlink();
      expect(remote.linked, true);
      await vault.link('ABC234');
      expect(vault.error, contains('pending'));
      await vault.transfer(10, bank: true);
      expect(remote.calls, 1);
    },
  );
  test(
    'concurrent taps and paid game actions cannot race the durable transfer',
    () async {
      remote.hold = Completer<void>();
      final first = vault.transfer(10, bank: true);
      await Future<void>.delayed(Duration.zero);
      expect(game.walletBusy, true);
      expect(await game.spend(5), false);
      await vault.transfer(10, bank: true);
      remote.hold!.complete();
      await first;
      expect(remote.calls, 1);
      expect(game.coins, 50);
    },
  );
  test(
    'remote switch blocks new transfers but lets existing intents finish',
    () async {
      remote.loseResponse = true;
      await vault.transfer(10, bank: true);
      remote.live = false;
      await vault.refresh();
      expect(vault.pending, false);
      await vault.transfer(10, bank: true);
      expect(game.coins, 50);
      expect(remote.coins, 110);
    },
  );
  test('invalid amounts cannot change either balance', () async {
    for (final amount in [0, -1, 61]) {
      await vault.transfer(amount, bank: true);
    }
    expect(game.coins, 60);
    expect(remote.coins, 100);
    expect(remote.calls, 0);
  });
  test(
    'queued game rewards and score saves survive a transfer in flight',
    () async {
      remote.hold = Completer<void>();
      final first = vault.transfer(10, bank: true);
      await Future<void>.delayed(Duration.zero);
      await game.reward(25);
      await game.record(
        level: MazeLevel.easy,
        relaxed: true,
        score: 100,
        found: 3,
      );
      await game.set('sound', false);
      remote.hold!.complete();
      await first;
      final restored = await restore(saved);
      expect(restored.coins, 85); // 60 - 10 + 25 + 10
      expect(restored.words, 3);
      expect(restored.sound, false);
      expect(restored.vaultTransfers, isEmpty);
      expect(remote.coins, 110);
    },
  );
  test('under-16 profile never contacts the remote vault', () async {
    await game.set('adult', false);
    remote.requests = 0;
    await vault.refresh();
    await vault.showCode();
    await vault.link('ABC234');
    await vault.transfer(10, bank: true);
    await vault.unlink();
    expect(remote.requests, 0);
    expect(remote.calls, 0);
    expect(game.coins, 60);
  });
  test('showing a new code is blocked while a transfer is pending', () async {
    remote.loseResponse = true;
    await vault.transfer(10, bank: true);
    await vault.showCode();
    expect(vault.error, contains('pending'));
    expect(vault.code, isNull);
  });
}
