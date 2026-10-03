import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chaturang/audio/audio_service.dart';
import 'package:chaturang/data/sound_preference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'test.soundEnabled';
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AudioService.instance.enabled = true;
  });

  test('sound is on for a new player', () async {
    final preference = SoundPreference(storageKey: key);
    await preference.load();
    expect(preference.value, isTrue);
    expect(AudioService.instance.enabled, isTrue);
    preference.dispose();
  });

  test(
    'mute is restored to both settings and audio after a fresh launch',
    () async {
      final first = SoundPreference(storageKey: key);
      await first.load();
      first.value = false;
      expect(AudioService.instance.enabled, isFalse);
      await first.pendingWrites;
      first.dispose();
      AudioService.instance.enabled = true;
      final reopened = SoundPreference(storageKey: key);
      await reopened.load();
      expect(reopened.value, isFalse);
      expect(AudioService.instance.enabled, isFalse);
      reopened.dispose();
    },
  );

  test(
    'turning sound back on survives reopening, including rapid toggles',
    () async {
      SharedPreferences.setMockInitialValues({key: false});
      final first = SoundPreference(storageKey: key);
      await first.load();
      first.value = true;
      first.value = false;
      first.value = true;
      await first.pendingWrites;
      first.dispose();
      final reopened = SoundPreference(storageKey: key);
      await reopened.load();
      expect(reopened.value, isTrue);
      expect(AudioService.instance.enabled, isTrue);
      reopened.dispose();
    },
  );

  test('a change during loading wins over the stored value', () async {
    final preference = SoundPreference(storageKey: key);
    final loading = preference.load();
    preference.value = false;
    await loading;
    await preference.pendingWrites;
    expect(preference.value, isFalse);
    expect(AudioService.instance.enabled, isFalse);
    expect((await SharedPreferences.getInstance()).getBool(key), isFalse);
    preference.dispose();
  });
}
