import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/services/packs/language_packs.dart';
import 'package:maze_words/services/packs/pack_storage.dart';
import 'package:maze_words/services/packs/pack_validation.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/domain/hunt.dart';
import 'package:maze_words/ui/language_packs_screen.dart';

class MemoryPacks implements PackStorage {
  final Map<String, String> values = {};
  bool fail = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('disk full');
    values[key] = value;
  }
}

String payload(String id) =>
    File('pack_hosting/packs/$id/1.json').readAsStringSync();
PackEntry entry(String text, {String access = 'free'}) {
  final j = jsonDecode(text) as Map;
  return PackEntry.fromJson({
    'id': j['language'],
    'name': 'Test pack',
    'revision': j['revision'],
    'bytes': utf8.encode(text).length,
    'sha256': sha256.convert(utf8.encode(text)).toString(),
    'path': 'packs/${j['language']}/${j['revision']}.json',
    'access': access,
    'minReader': 1,
    'reviewStatus': 'preview',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all 216 bundled/published mazes validate and goals can be played', () {
    var mazes = 0;
    final special = <String>{};
    for (final id in ['en', 'es']) {
      final bundle = validateBundle(payload(id), id, 1);
      for (final level in MazeLevel.values) {
        for (final maze in bundle.levels[level]!.mazes) {
          mazes++;
          for (final l in maze.letters) {
            if ('ÑÁÉÍÓÚÜ'.contains(l.letter)) special.add(l.letter);
          }
          for (final word in maze.commonWords) {
            final hunt = Hunt(maze: maze, level: level, relaxed: true);
            final path = maze.commonPaths[word]!;
            hunt.start(path.first);
            for (final cell in path.skip(1)) {
              expect(hunt.step(cell), true);
            }
            expect(hunt.word, word);
            expect(hunt.submit(), FindResult.common);
          }
        }
      }
    }
    expect(mazes, 216);
    expect(special, contains('Ñ'));
    expect(special.length, greaterThan(1));
  });
  test(
    'download survives restart/offline and failed update retains previous revision',
    () async {
      final disk = MemoryPacks();
      var response = payload('es');
      var requests = 0;
      final packs = LanguagePacks(
        storage: disk,
        client: MockClient((_) async {
          requests++;
          return http.Response.bytes(utf8.encode(response), 200);
        }),
      );
      expect(await packs.install(entry(response)), true);
      expect(packs.installedRevision('es'), 1);
      final old = await packs.load('es', MazeLevel.easy);
      final changed = jsonDecode(response) as Map<String, dynamic>;
      changed['revision'] = 2;
      response = jsonEncode(changed);
      disk.fail = true;
      expect(await packs.install(entry(response)), false);
      expect(packs.installedRevision('es'), 1);
      expect(identical(await packs.load('es', MazeLevel.easy), old), true);
      disk.fail = false;
      expect(await packs.install(entry(response)), true);
      expect(packs.installedRevision('es'), 2);
      expect(
        old.mazes,
        isNotEmpty,
      ); // Existing hunt owns its immutable old pack.
      final offline = LanguagePacks(
        storage: disk,
        client: MockClient((_) async => throw StateError('offline')),
      );
      expect((await offline.load('es', MazeLevel.hard)).mazes.length, 12);
      expect(offline.installedRevision('es'), 2);
      final before = requests;
      expect(await packs.install(entry(payload('es'))), true);
      expect(requests, before);
      packs.dispose();
      offline.dispose();
    },
  );
  test(
    'bad checksum, schema, walls, letters and goal paths never activate',
    () async {
      final original = payload('es');
      final disk = MemoryPacks();
      var response = original;
      final packs = LanguagePacks(
        storage: disk,
        client: MockClient(
          (_) async => http.Response.bytes(utf8.encode(response), 200),
        ),
      );
      response = original.replaceFirst('CASA', 'XXXX');
      // Always corrupt the byte stream, even if this maze selection has no CASA.
      response = '$response ';
      expect(await packs.install(entry(original)), false);
      expect(packs.installed('es'), false);
      for (final damage in [
        (Map j) => j['schemaVersion'] = 99,
        (Map j) => j['levels']['easy']['mazes'][0]['walls'][0] = 0,
        (Map j) =>
            j['levels']['easy']['mazes'][0]['letters'][0]['letter'] = '😀',
        (Map j) => j['levels']['easy']['mazes'][0]['commonPaths'] = {},
      ]) {
        final j = jsonDecode(original) as Map;
        damage(j);
        response = jsonEncode(j);
        expect(await packs.install(entry(response)), false);
        expect(disk.values, isEmpty);
      }
      packs.dispose();
    },
  );
  test(
    'paid packs and external catalog URLs are rejected without a request',
    () async {
      var requests = 0;
      final packs = LanguagePacks(
        storage: MemoryPacks(),
        client: MockClient((_) async {
          requests++;
          return http.Response('', 200);
        }),
      );
      expect(
        await packs.install(entry(payload('es'), access: 'purchase')),
        false,
      );
      expect(requests, 0);
      final catalog =
          jsonDecode(File('assets/pack_catalog.json').readAsStringSync())
              as Map;
      catalog['packs'][0]['path'] = 'https://untrusted.example/pack.json';
      expect(
        () => packs.parseCatalog(jsonEncode(catalog)),
        throwsFormatException,
      );
      packs.dispose();
    },
  );
  test(
    'catalog failure retains offline entries and corrupt local data falls back',
    () async {
      final disk = MemoryPacks()..values['installed.es'] = 'broken';
      final packs = LanguagePacks(
        storage: disk,
        client: MockClient((_) async => http.Response('unavailable', 503)),
      );
      await packs.initialize();
      expect(packs.entries.length, 17);
      expect(packs.installed('es'), false);
      expect(await packs.refresh(), false);
      expect(packs.entries.length, 17);
      expect((await packs.load('en', MazeLevel.easy)).mazes.length, 60);
      packs.dispose();
    },
  );
  test(
    'language changes and revisions cannot repeat daily rewards; legacy bests stay',
    () async {
      SharedPreferences.setMockInitialValues({
        PlayerStore.storageKey:
            '{"coins":94,"daily":20260925,"best.easy.false":150}',
      });
      final store = PlayerStore(await SharedPreferences.getInstance());
      expect(store.best(MazeLevel.easy), 150);
      await store.selectLanguage('es');
      expect(store.best(MazeLevel.easy), 0);
      final before = store.coins;
      expect(
        await store.record(
          level: MazeLevel.easy,
          relaxed: false,
          score: 100,
          found: 3,
          daily: 20260925,
          language: 'es',
        ),
        0,
      );
      expect(store.coins, before);
      expect(store.best(MazeLevel.easy), 100);
      await store.record(
        level: MazeLevel.easy,
        relaxed: false,
        score: 100,
        found: 3,
        daily: 20260926,
        language: 'es',
      );
      expect(
        await store.record(
          level: MazeLevel.easy,
          relaxed: false,
          score: 100,
          found: 3,
          daily: 20260925,
          language: 'en',
        ),
        0,
      );
      await store.selectLanguage('en');
      expect(store.best(MazeLevel.easy), 150);
    },
  );
  testWidgets(
    'pack screen makes no automatic request; download then select Spanish',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = PlayerStore(await SharedPreferences.getInstance());
      await store.setBirthYear(1990);
      var requests = 0;
      final packs = LanguagePacks(
        storage: MemoryPacks(),
        client: MockClient((request) async {
          requests++;
          return http.Response.bytes(
            File('pack_hosting${request.url.path}').readAsBytesSync(),
            200,
          );
        }),
      );
      await tester.runAsync(packs.initialize);
      await tester.pumpWidget(
        MaterialApp(
          home: LanguagePacksScreen(store: store, packs: packs),
        ),
      );
      await tester.runAsync(() async {
        await packs.initialize();
      });
      await tester.pumpAndSettle();
      expect(requests, 0);
      expect(find.byTooltip('Word sources'), findsNothing);
      expect(
        find.textContaining('Found an error or discrepancy'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(find.text('Español'), 200);
      expect(find.text('Español'), findsOneWidget);
      await tester.ensureVisible(find.textContaining('Download ·').first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Download ·').first);
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(store.language, 'en');
      await tester.ensureVisible(find.text('Use Español'));
      await tester.pumpAndSettle();
      // Complete the real worker isolate before returning to fake widget time.
      await tester.runAsync(() => packs.load('es', MazeLevel.easy));
      await tester.tap(find.text('Use Español'));
      await tester.pumpAndSettle();
      expect(store.language, 'es');
      expect(store.coins, 30);
      await tester.pumpWidget(const SizedBox());
      packs.dispose();
    },
  );
}
