import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'vault_service.dart';

class FirebaseVault implements VaultRemote {
  final SharedPreferences prefs;
  FirebaseDatabase? _db;
  FirebaseAuth? _auth;
  Future<void>? _initializing;
  String? _vault;
  FirebaseVault(this.prefs) : _vault = prefs.getString('family.vault.id');
  @override
  bool get linked => _vault != null;
  static const _timeout = Duration(seconds: 12);
  static const _flag = 'config/sharedWalletLive';
  Future<T> _bounded<T>(Future<T> future) => future.timeout(_timeout);
  Future<void> _init() async {
    if (_db != null) return;
    try {
      await (_initializing ??= _initialize());
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    final options = VaultFirebaseOptions.current;
    if (options == null) {
      throw const VaultFailure(
        'Shared coins will be available in the configured iOS and Android app.',
      );
    }
    final matches = Firebase.apps.where((a) => a.name == 'vault');
    final app = matches.isNotEmpty
        ? matches.first
        : await _bounded(
            Firebase.initializeApp(name: 'vault', options: options),
          );
    _auth = FirebaseAuth.instanceFor(app: app);
    _db = FirebaseDatabase.instanceFor(app: app);
  }

  @override
  Future<bool> available() async {
    await _init();
    try {
      final live = (await _bounded(_db!.ref(_flag).get())).value == true;
      await prefs.setBool('family.vault.live', live);
      return live;
    } catch (_) {
      return prefs.getBool('family.vault.live') ?? false;
    }
  }

  @override
  Future<void> ready() async {
    await _init();
    if (_auth!.currentUser == null) await _bounded(_auth!.signInAnonymously());
    final connected = Completer<void>();
    final sub = _db!
        .ref('.info/connected')
        .onValue
        .listen(
          (event) {
            if (event.snapshot.value == true && !connected.isCompleted) {
              connected.complete();
            }
          },
          onError: (Object _) {
            if (!connected.isCompleted) {
              connected.completeError(
                const VaultFailure(
                  'The vault is offline. Try again when connected.',
                ),
              );
            }
          },
        );
    // .info is client-side; wake an idle Android connection with a real read.
    unawaited(
      _bounded(_db!.ref(_flag).get()).then((_) {}, onError: (Object _) {}),
    );
    try {
      await connected.future.timeout(const Duration(seconds: 5));
    } finally {
      await sub.cancel();
    }
  }

  DatabaseReference get _ref {
    if (_vault == null) {
      throw const VaultFailure('Link another game to share coins.');
    }
    return _db!.ref('vaults/$_vault');
  }

  @override
  Future<int> balance() async {
    final value = (await _bounded(_ref.child('balance').get())).value;
    if (value is! int) {
      throw const VaultFailure(
        'The vault balance could not be read. Try refreshing.',
      );
    }
    return value;
  }

  String _random(int length, String alphabet) {
    final rng = Random.secure();
    return List.generate(
      length,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    ).join();
  }

  Future<void> _store(String? value) async {
    final saved = value == null
        ? await prefs.remove('family.vault.id')
        : await prefs.setString('family.vault.id', value);
    if (!saved) {
      throw const VaultFailure(
        'The vault link could not be saved on this device.',
      );
    }
    _vault = value;
  }

  @override
  Future<String> issueCode() async {
    if (!linked) {
      final id = _random(
        22,
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-',
      );
      // Persist before network so interrupted creation can resume on this ID.
      await _store(id);
    }
    final uid = _auth!.currentUser!.uid;
    await _bounded(_ref.child('members/$uid').set(true));
    final initial = await _bounded(_ref.child('balance').get());
    if (!initial.exists) await _bounded(_ref.child('balance').set(0));
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _random(6, 'ABCDEFGHJKMNPQRSTUVWXYZ23456789');
      try {
        await _bounded(
          _db!.ref('codes/$code').set({
            'vaultId': _vault,
            'createdAt': now,
            'expiresAt': now + const Duration(minutes: 30).inMilliseconds,
          }),
        );
        return code;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
      }
    }
    throw const VaultFailure('Could not create a code. Try again.');
  }

  @override
  Future<void> redeem(String code) async {
    final normalized = code.trim().toUpperCase();
    if (!RegExp(
      r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$',
    ).hasMatch(normalized)) {
      throw const VaultFailure(
        'Enter the six-character code shown in the other game.',
      );
    }
    final snap = await _bounded(_db!.ref('codes/$normalized').get());
    if (snap.value is! Map) {
      throw const VaultFailure(
        'That code was not found. Check it and try again.',
      );
    }
    final data = Map<String, dynamic>.from(snap.value as Map);
    if (data['redeemedAt'] != null) {
      throw const VaultFailure(
        'That code has already been used. Get a fresh code.',
      );
    }
    if (data['expiresAt'] is! int ||
        data['expiresAt'] < DateTime.now().millisecondsSinceEpoch) {
      throw const VaultFailure(
        'That code has expired. Get a fresh code in the other game.',
      );
    }
    final id = data['vaultId'];
    if (id is! String || !RegExp(r'^[A-Za-z0-9_-]{20,64}$').hasMatch(id)) {
      throw const VaultFailure('That code is not valid.');
    }
    if (linked && _vault != id) {
      if (await balance() != 0) {
        throw const VaultFailure(
          'Collect the coins in your current vault before linking another.',
        );
      }
      await unlink();
    }
    // Retain the destination if the join lands but its response is lost.
    await _store(id);
    await _bounded(
      _db!.ref().update({
        'codes/$normalized/redeemedAt': DateTime.now().millisecondsSinceEpoch,
        'vaults/$id/members/${_auth!.currentUser!.uid}': true,
      }),
    );
  }

  @override
  Future<void> unlink() async {
    if (!linked) return;
    final members = await _bounded(_ref.child('members').get());
    if (members.children.length <= 1 && await balance() > 0) {
      throw const VaultFailure(
        'Collect your coins first. This is the only game linked to this vault.',
      );
    }
    await _bounded(_ref.child('members/${_auth!.currentUser!.uid}').remove());
    await _store(null);
  }

  Future<bool> _alreadyApplied(String id, int amount, String kind) async {
    final value = (await _bounded(_ref.child('transfers/$id').get())).value;
    if (value == null) return false;
    if (value is! Map ||
        value['amount'] != amount ||
        value['kind'] != kind ||
        value['by'] != _auth!.currentUser!.uid) {
      throw const VaultFailure(
        'This pending transfer could not be verified. Its coins remain reserved.',
      );
    }
    return true;
  }

  @override
  Future<void> apply(String id, int amount, String kind) async {
    // Check before funds: a successful but unconfirmed withdrawal can empty it.
    if (await _alreadyApplied(id, amount, kind)) return;
    for (var attempt = 0; attempt < 4; attempt++) {
      final prev = await balance();
      final next = kind == 'bank' ? prev + amount : prev - amount;
      if (next < 0 || next > 10000000) {
        throw const VaultFailure(
          'The vault balance changed. Your transfer is pending; refresh when enough coins are available.',
        );
      }
      try {
        await _bounded(
          _ref.update({
            'balance': next,
            'transfers/$id': {
              'amount': amount,
              'kind': kind,
              'prev': prev,
              'at': DateTime.now().millisecondsSinceEpoch,
              'by': _auth!.currentUser!.uid,
            },
          }),
        );
        return;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        if (await _alreadyApplied(id, amount, kind)) return;
      }
    }
    throw const VaultFailure(
      'The vault is busy. Refresh to finish your pending transfer.',
    );
  }

  @override
  Future<void> acknowledge(String id) async {
    final ref = _ref.child('transfers/$id/ackedAt');
    if ((await _bounded(ref.get())).exists) return;
    try {
      await _bounded(ref.set(DateTime.now().millisecondsSinceEpoch));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied' ||
          !(await _bounded(ref.get())).exists) {
        rethrow;
      }
    }
  }
}
