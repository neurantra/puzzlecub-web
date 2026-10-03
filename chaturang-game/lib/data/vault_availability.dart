import 'package:flutter/foundation.dart';

class VaultAvailability extends ChangeNotifier {
  static final instance = VaultAvailability();
  bool get isLive => false;
  Future<void> load() async {}
  Future<void> refresh() async {}
}
