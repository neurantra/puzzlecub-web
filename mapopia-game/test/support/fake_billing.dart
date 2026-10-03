import 'dart:async';
import 'package:mapopia/services/atlas_commerce.dart';

class FakeBilling implements AtlasBilling {
  bool owned = false, available = true, result = true;
  Object? error;
  Completer<bool>? pending;
  void Function(bool)? changed;
  @override
  Future<bool> initialize() async => available;
  @override
  Future<bool> ownership() async {
    if (error != null) throw error!;
    return owned;
  }

  @override
  Future<String?> price() async => '€4.99';
  @override
  Future<bool> purchase() async {
    if (error != null) throw error!;
    return pending == null ? result : pending!.future;
  }

  @override
  Future<bool> restore() => purchase();
  @override
  void listen(void Function(bool) listener) {
    changed = listener;
  }

  @override
  void dispose() {}
}
