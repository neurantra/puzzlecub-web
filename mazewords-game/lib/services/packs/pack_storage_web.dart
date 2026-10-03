import 'package:shared_preferences/shared_preferences.dart';
import 'pack_storage.dart';

PackStorage createPackStorage() => BrowserPackStorage();

class BrowserPackStorage implements PackStorage {
  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString('packs.$key');
  @override
  Future<void> write(String key, String value) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      'packs.$key',
      value,
    )) {
      throw StateError('Could not save pack');
    }
  }
}
