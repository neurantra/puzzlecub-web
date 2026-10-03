import 'dart:js_interop';

@JS('puzzlecubGameAction')
external void _gameAction(JSBoolean completed);

void reportGameAction(bool completed) {
  // Analytics must never interrupt a puzzle when an embedding page omits the bridge.
  try {
    _gameAction(completed.toJS);
  } catch (_) {}
}
