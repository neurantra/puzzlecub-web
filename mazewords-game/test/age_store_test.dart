import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';

void main() {
  test(
    'legacy migration preserves coins and progress, age correction persists',
    () async {
      SharedPreferences.setMockInitialValues({
        PlayerStore.storageKey:
            '{"adult":true,"onboarded":true,"coins":94,"rounds":7}',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = PlayerStore(prefs);
      expect(store.adult, true);
      expect(store.birthYear, isNull);
      await store.setBirthYear(DateTime.now().year - 8);
      expect(store.adult, false);
      expect(store.coins, 94);
      expect(store.rounds, 7);
      final restored = PlayerStore(prefs);
      expect(restored.birthYear, DateTime.now().year - 8);
      await restored.setBirthYear(1990);
      expect(restored.adult, true);
      expect(restored.coins, 94);
    },
  );
  test(
    'pending transfers and failed storage cannot change declaration',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PlayerStore(prefs);
      await store.setBirthYear(1990);
      await store.beginTransfer({'id': 'test', 'amount': 10, 'kind': 'bank'});
      await expectLater(store.setBirthYear(2020), throwsStateError);
      expect(store.birthYear, 1990);
      expect(store.coins, 20);
      final failed = PlayerStore(prefs, persist: (_) async => false);
      // Remove the pending entry in a separate saved store to isolate disk failure.
      await store.completeTransfer('test');
      final disk = PlayerStore(prefs, persist: (_) async => false);
      await expectLater(disk.setBirthYear(2020), throwsStateError);
      expect(disk.birthYear, 1990);
      expect(failed.coins, 20);
    },
  );
}
