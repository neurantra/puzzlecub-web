import 'dart:async';
import 'package:maze_words/services/packs/language_packs.dart';
import 'package:maze_words/services/packs/pack_storage.dart';

/// Unit/widget tests never read a real player's downloaded content directory.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Test harness uses in-memory pack storage to avoid native filesystem calls.
  // ignore: invalid_use_of_visible_for_testing_member
  LanguagePacks.storageFactory = () => _TestPackStorage();
  await testMain();
}

class _TestPackStorage implements PackStorage {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
