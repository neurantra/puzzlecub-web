import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../data/maze_pack.dart';
import '../../data/regular_vocabulary.dart';
import '../../domain/maze.dart';
import '../../domain/puzzle_language.dart';
import '../../domain/maze_level.dart';
import 'pack_storage.dart';
import 'pack_storage_native.dart'
    if (dart.library.html) 'pack_storage_web.dart';
import 'pack_validation.dart';

class PackEntry {
  PackEntry.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      revision = j['revision'] as int,
      bytes = j['bytes'] as int,
      digest = j['sha256'] as String,
      path = j['path'] as String,
      access = j['access'] as String,
      preview = j['reviewStatus'] == 'preview',
      difficultyCounts = Map<String, int>.from(
        j['difficultyCounts'] as Map? ?? {},
      ),
      minReader = j['minReader'] as int;
  final String id, name, digest, path, access;
  final int revision, bytes, minReader;
  final Map<String, int> difficultyCounts;
  final bool preview;
  bool get supported => PuzzleLanguage.supports(id) && minReader <= 5;
}

class LanguagePacks extends ChangeNotifier {
  LanguagePacks({PackStorage? storage, http.Client? client, Uri? origin})
    : storage = storage ?? storageFactory(),
      client = client ?? http.Client(),
      origin =
          origin ??
          (kIsWeb
              ? Uri.base.resolve('/maze-packs/')
              : Uri.parse(
                  const String.fromEnvironment(
                    'PACKS_BASE_URL',
                    defaultValue: 'https://mazewords-packs.web.app/',
                  ),
                ));
  @visibleForTesting
  static PackStorage Function() storageFactory = createPackStorage;
  final PackStorage storage;
  final http.Client client;
  final Uri origin;
  List<PackEntry> entries = [];
  final Map<String, LanguageBundle> _installed = {};
  final Map<String, Future<void>> _reads = {};
  bool busy = false;
  bool _disposed = false;
  String? error;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  int installedRevision(String id) =>
      _installed[id]?.revision ?? (id == 'en' ? 1 : 0);
  bool installed(String id) => installedRevision(id) > 0;
  Uri url(String path) {
    final result = origin.resolve(path);
    final localWeb = kIsWeb && origin.origin == Uri.base.origin;
    if ((!localWeb && origin.scheme != 'https') ||
        result.scheme != origin.scheme ||
        result.host != origin.host ||
        result.port != origin.port ||
        result.userInfo.isNotEmpty ||
        !result.path.startsWith(origin.path)) {
      throw const FormatException('Invalid pack URL');
    }
    return result;
  }

  List<PackEntry> parseCatalog(String text) {
    final j = jsonDecode(text) as Map;
    if (j['schemaVersion'] != 1 || (j['packs'] as List).length > 100) {
      throw const FormatException('Incompatible catalog');
    }
    final list = (j['packs'] as List)
        .map((e) => PackEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final ids = <String>{};
    for (final e in list) {
      if (!RegExp(r'^[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$').hasMatch(e.id) ||
          !ids.add(e.id) ||
          e.name.length > 80 ||
          e.revision < 1 ||
          e.minReader < 1 ||
          e.bytes <= 0 ||
          e.bytes > 4000000 ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(e.digest) ||
          !['free', 'purchase'].contains(e.access)) {
        throw const FormatException('Invalid catalog entry');
      }
      url(e.path);
    }
    return list;
  }

  Future<void>? _initializing;
  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    entries = parseCatalog(
      await rootBundle.loadString('assets/pack_catalog.json'),
    );
    try {
      final cached = await storage.read('catalog');
      if (cached != null) {
        final bundled = {for (final e in entries) e.id: e};
        for (final entry in parseCatalog(cached)) {
          if (entry.revision >= (bundled[entry.id]?.revision ?? 0)) {
            bundled[entry.id] = entry;
          }
        }
        entries = bundled.values.toList();
      }
    } catch (_) {
      /* bundled catalog is always available offline */
    }
    for (final e in entries.where((e) => e.supported)) {
      await _readInstalled(e.id);
    }
    _notify();
  }

  Future<void> _readInstalled(String id) => _reads[id] ??= _loadInstalled(id);
  Future<void> _loadInstalled(String id) async {
    try {
      final raw = await storage.read('installed.$id');
      if (raw == null) return;
      final envelope = jsonDecode(raw) as Map;
      final text = envelope['payload'] as String;
      if (sha256.convert(utf8.encode(text)).toString() != envelope['sha256']) {
        return;
      }
      // Paid packs require a verified entitlement service; never trust a local flag.
      if (envelope['access'] != 'free') return;
      _installed[id] = validateBundle(text, id, envelope['revision'] as int);
    } catch (_) {
      /* corrupt download falls back to bundled English */
    }
  }

  Future<MazePack> load(String id, MazeLevel level) async {
    if (!PuzzleLanguage.supports(id)) throw StateError('Unsupported language');
    if (!_installed.containsKey(id)) await _readInstalled(id);
    final pack = _installed[id]?.levels[level];
    if (pack != null) return RegularVocabulary.restore(pack, id);
    if (id == 'en') return MazePackLoader.load(level);
    throw StateError('Download this language pack first');
  }

  Future<String> fetch(String path, int maximum) async {
    return (() async {
      final request = http.Request('GET', url(path))..followRedirects = false;
      final response = await client.send(request);
      if (response.statusCode != 200 ||
          (response.contentLength ?? 0) > maximum) {
        throw StateError('Download unavailable');
      }
      final data = <int>[];
      await for (final chunk in response.stream) {
        if (data.length + chunk.length > maximum) {
          throw StateError('Pack too large');
        }
        data.addAll(chunk);
      }
      return utf8.decode(data);
    })().timeout(const Duration(seconds: 45));
  }

  Future<bool> _run(Future<void> Function() operation) async {
    if (busy || _disposed) return false;
    busy = true;
    error = null;
    updateSummary = null;
    _notify();
    try {
      await operation();
      return true;
    } catch (_) {
      error =
          'Could not finish the pack update. Check your connection and try again. Your installed packs and coins are unchanged.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _refresh() async {
    final raw = await fetch('catalog.json', 100000);
    final next = parseCatalog(raw);
    await storage.write('catalog', raw);
    entries = next;
    for (final e in entries.where((e) => e.supported)) {
      await _readInstalled(e.id);
    }
  }

  Future<bool> refresh() => _run(_refresh);
  Future<bool> install(PackEntry entry) => _run(() => _install(entry));
  Future<void> _install(PackEntry entry) async {
    if (!entry.supported || entry.access != 'free') {
      throw StateError('Pack not available');
    }
    if (entry.revision <= installedRevision(entry.id)) return;
    final text = await fetch(entry.path, entry.bytes);
    final bytes = utf8.encode(text);
    if (bytes.length != entry.bytes ||
        sha256.convert(bytes).toString() != entry.digest) {
      throw const FormatException('Download failed integrity check');
    }
    final bundle = validateBundle(text, entry.id, entry.revision);
    // One atomic file replacement includes payload, revision and digest.
    await storage.write(
      'installed.${entry.id}',
      jsonEncode({
        'revision': entry.revision,
        'sha256': entry.digest,
        'access': 'free',
        'payload': text,
      }),
    );
    _installed[entry.id] = bundle;
  }

  String? updateSummary;
  Future<bool> updateWords() => _run(() async {
    updateSummary = null;
    await _refresh();
    var updated = 0;
    final failures = <String>[];
    for (final e in entries.where(
      (e) =>
          e.supported &&
          e.access == 'free' &&
          installed(e.id) &&
          e.revision > installedRevision(e.id),
    )) {
      try {
        await _install(e);
        updated++;
      } catch (_) {
        failures.add(PuzzleLanguage.of(e.id).name);
      }
    }
    updateSummary = failures.isEmpty
        ? updated == 0
              ? 'Your installed word packs are up to date.'
              : 'Updated $updated word pack${updated == 1 ? "" : "s"}. Ready for your next hunt.'
        : 'Updated $updated packs. Could not update ${failures.join(", ")}; their previous versions are still available. Try again.';
  });
  @override
  void dispose() {
    _disposed = true;
    client.close();
    super.dispose();
  }
}
