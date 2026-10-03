import 'dart:js_interop';

@JS('puzzlecubGameAction')
external void _action(JSBoolean completed);
@JS('puzzlecubSetAdsAllowed')
external void _allowed(JSBoolean allowed);
@JS('puzzlecubWebBetweenGames')
external JSPromise<JSAny?> _between();
void reportGameAction(bool completed) => _action(completed.toJS);
void setWebAdsAllowed(bool allowed) => _allowed(allowed.toJS);
Future<void> betweenGames() async {
  try {
    await _between().toDart;
  } catch (_) {}
}
