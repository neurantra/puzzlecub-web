import 'dart:js_interop';
import 'audio/audio_service.dart';

@JS('puzzlecubGameAction')
external void _action(JSBoolean completed);
@JS('puzzlecubBetweenGames')
external JSPromise<JSAny?> _between();
void reportGameAction(bool completed) => _action(completed.toJS);
Future<void> betweenGames() async {
  final sound = AudioService.instance.enabled;
  AudioService.instance.enabled = false;
  await AudioService.instance.stopAll();
  try {
    await _between().toDart;
  } catch (_) {
  } finally {
    AudioService.instance.enabled = sound;
  }
}
