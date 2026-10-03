import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'pack_storage.dart';

PackStorage createPackStorage() => FilePackStorage();

class FilePackStorage implements PackStorage {
  Future<File> file(String key) async {
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(key)) {
      throw const FormatException('Invalid pack key');
    }
    final dir = Directory(
      '${(await getApplicationSupportDirectory()).path}/puzzle_packs',
    );
    await dir.create(recursive: true);
    return File('${dir.path}/$key.json');
  }

  @override
  Future<String?> read(String key) async {
    final f = await file(key);
    return await f.exists() ? f.readAsString() : null;
  }

  @override
  Future<void> write(String key, String value) async {
    final f = await file(key);
    final temporary = File('${f.path}.tmp');
    await temporary.writeAsString(value, flush: true);
    await temporary.rename(f.path);
  }
}
