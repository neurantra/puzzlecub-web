import 'package:flutter/foundation.dart';

class ReleasePolicy extends ChangeNotifier {
  static final instance = ReleasePolicy();
  bool get blocked => false;
  String get minimum => '0.0.0';
  Future<void> refresh({bool force = false}) async {}
}
