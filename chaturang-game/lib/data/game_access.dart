import 'package:flutter/foundation.dart';

class GameAccess extends ChangeNotifier {
  static final instance = GameAccess();
  bool get freeHints => true;
  bool get coinAdsAllowed => false;
  bool get adsAllowed => false;
  Future<void> initialize() async {}
  Future<bool> startMatch() async => true;
  Future<void> acknowledgeOnlineAdmission() async {}
  void endMatch() {}
}
