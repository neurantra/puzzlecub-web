import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/domain/hunt.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/domain/puzzle_language.dart';
import 'package:maze_words/services/packs/language_packs.dart';
import 'package:maze_words/services/packs/pack_validation.dart';
import 'language_packs_test.dart' show MemoryPacks, entry, payload;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalog =
      jsonDecode(File('pack_hosting/catalog.json').readAsStringSync()) as Map;
  test(
    'all catalog payloads and 7650 maze solutions validate with intact tiles',
    () {
      var count = 0, shortIndic = 0;
      for (final raw in catalog['packs'] as List) {
        final e = PackEntry.fromJson(Map<String, dynamic>.from(raw as Map));
        final bytes = File('pack_hosting/${e.path}').readAsBytesSync();
        expect(bytes.length, e.bytes);
        expect(sha256.convert(bytes).toString(), e.digest);
        final bundle = validateBundle(utf8.decode(bytes), e.id, e.revision);
        final distinctWords = <String>{};
        for (final level in MazeLevel.values) {
          final mazes = bundle.levels[level]!.mazes;
          expect(mazes.length, e.difficultyCounts[level.name]);
          expect(mazes.length, 150);
          for (final maze in mazes) {
            count++;
            distinctWords.addAll(maze.words);
            expect(maze.language, e.id);
            var threeTileWords = 0, longerWords = 0;
            for (final word in maze.commonWords) {
              final h = Hunt(maze: maze, level: level, relaxed: true);
              final path = maze.commonPaths[word]!;
              h.start(path.first);
              for (final c in path.skip(1)) {
                expect(h.step(c), true);
              }
              expect(h.word, word);
              if (h.wordTileCount == 3) threeTileWords++;
              if (h.wordTileCount >= 4) longerWords++;
              if (maze.script.indic && h.wordTileCount == 2) shortIndic++;
              expect(h.submit(), FindResult.common, reason: '${e.id}: $word');
              expect(h.score, greaterThan(0));
            }
            if (maze.script.indic) {
              expect(
                threeTileWords,
                greaterThanOrEqualTo(level.index + 2),
                reason:
                    '${e.id} ${level.name} ${maze.id} needs enough three-tile targets',
              );
              expect(
                longerWords,
                greaterThanOrEqualTo(level.index),
                reason: 'Medium/Hard must retain longer targets',
              );
            }
          }
        }
        expect(distinctWords.length, greaterThanOrEqualTo(2000), reason: e.id);
      }
      expect(count, 7650);
      expect(shortIndic, greaterThan(0));
    },
  );
  test(
    'Tamil/Hindi refresh replaces old packs and retains them offline',
    () async {
      final disk = MemoryPacks();
      final packs = LanguagePacks(
        storage: disk,
        client: MockClient(
          (request) async => http.Response.bytes(
            File('pack_hosting${request.url.path}').readAsBytesSync(),
            200,
          ),
        ),
      );
      for (final id in ['ta', 'hi']) {
        final old = File('pack_hosting/packs/$id/1.json').readAsStringSync();
        expect(await packs.install(entry(old)), true);
        expect(packs.installedRevision(id), 1);
      }
      expect(await packs.updateWords(), true);
      expect(packs.updateSummary, contains('Updated 3 word packs'));
      for (final id in ['ta', 'hi']) {
        expect(packs.installedRevision(id), 3);
      }
      packs.dispose();
      final offline = LanguagePacks(
        storage: disk,
        client: MockClient((_) async => throw StateError('offline')),
      );
      for (final id in ['ta', 'hi']) {
        for (final level in MazeLevel.values) {
          final pack = await offline.load(id, level);
          for (final maze in pack.mazes) {
            final three = maze.commonWords
                .where(
                  (w) =>
                      maze.commonPaths[w]!
                          .where(
                            (c) =>
                                maze.letterAt(
                                  c % maze.width,
                                  c ~/ maze.width,
                                ) !=
                                null,
                          )
                          .length ==
                      3,
                )
                .length;
            expect(three, greaterThanOrEqualTo(level.index + 2));
          }
        }
      }
      offline.dispose();
    },
  );
  test(
    'Indic validation rejects detached signs, split conjuncts and mixed scripts',
    () {
      final ta = PuzzleLanguage.of('ta'), hi = PuzzleLanguage.of('hi');
      for (final t in ['கி', 'மா', 'ம்', 'கொ']) {
        expect(ta.validTile(t), true);
      }
      for (final t in ['स्त', 'क्ष', 'कि', 'ड़', 'हैं']) {
        expect(hi.validTile(t), true);
      }
      for (final t in ['ि', '्', 'स्', 'AB', 'कक', 'கி']) {
        expect(hi.validTile(t), false);
      }
      for (final t in ['ி', '்', 'கம', 'A', 'कि']) {
        expect(ta.validTile(t), false);
      }
      for (final id in ['ta', 'hi']) {
        final j =
            jsonDecode(File('pack_hosting/packs/$id/1.json').readAsStringSync())
                as Map;
        j['levels']['easy']['mazes'][0]['letters'][0]['letter'] = id == 'ta'
            ? 'ி'
            : 'ि';
        expect(
          () => validateBundle(jsonEncode(j), id, 1),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'word refresh upgrades installed Spanish only, preserves old hunt and offline packs',
    () async {
      final disk = MemoryPacks();
      final requests = <String>[];
      var failSpanish = false;
      final packs = LanguagePacks(
        storage: disk,
        client: MockClient((r) async {
          requests.add(r.url.path);
          if (failSpanish && r.url.path == '/packs/es/3.json') {
            return http.Response('offline', 503);
          }
          return http.Response.bytes(
            File('pack_hosting${r.url.path}').readAsBytesSync(),
            200,
          );
        }),
      );
      expect(await packs.install(entry(payload('es'))), true);
      final old = await packs.load('es', MazeLevel.easy);
      await packs.initialize();
      failSpanish = true;
      expect(await packs.updateWords(), true);
      expect(packs.updateSummary, contains('Could not update'));
      expect(packs.installedRevision('es'), 1);
      failSpanish = false;
      expect(await packs.updateWords(), true);
      expect(packs.installedRevision('es'), 3);
      expect(old.mazes.length, 12);
      expect((await packs.load('es', MazeLevel.easy)).mazes.length, 150);
      expect(
        requests.any((p) => p.contains('/ta/') || p.contains('/hi/')),
        false,
      );
      final before = requests.length;
      expect(await packs.updateWords(), true);
      expect(packs.updateSummary, contains('up to date'));
      expect(requests.length, before + 1);
      packs.dispose();
      final offline = LanguagePacks(
        storage: disk,
        client: MockClient((_) async => throw StateError('offline')),
      );
      expect((await offline.load('es', MazeLevel.hard)).mazes.length, 150);
      offline.dispose();
    },
  );
  test('old cached catalog cannot hide newly bundled languages', () async {
    final disk = MemoryPacks()
      ..values['catalog'] = jsonEncode({
        'schemaVersion': 1,
        'packs': [
          <String, dynamic>{
            ...(catalog['packs'] as List).firstWhere((e) => e['id'] == 'en'),
          },
          <String, dynamic>{
            ...(catalog['packs'] as List).firstWhere((e) => e['id'] == 'es'),
            'revision': 1,
            'path': 'packs/es/1.json',
          },
        ],
      });
    final packs = LanguagePacks(storage: disk);
    await packs.initialize();
    expect(
      packs.entries.map((e) => e.id),
      containsAll(['en', 'es', 'ta', 'hi']),
    );
    expect(packs.entries.singleWhere((e) => e.id == 'es').revision, 3);
    packs.dispose();
  });
  test(
    'Tamil and Hindi selection persists without changing coins or replaying daily rewards',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PlayerStore(prefs);
      await store.record(
        level: MazeLevel.easy,
        score: 100,
        found: 3,
        cleared: true,
        relaxed: false,
        daily: 20260925,
        language: 'en',
      );
      await store.selectLanguage('ta');
      final balance = store.coins;
      expect(PlayerStore(prefs).language, 'ta');
      await store.selectLanguage('hi');
      expect(PlayerStore(prefs).language, 'hi');
      expect(
        await store.record(
          level: MazeLevel.easy,
          score: 90,
          found: 3,
          cleared: true,
          relaxed: false,
          daily: 20260925,
          language: 'hi',
        ),
        0,
      );
      expect(store.coins, balance);
      expect(store.best(MazeLevel.easy, language: 'hi'), 90);
      expect(store.best(MazeLevel.easy, language: 'en'), 100);
    },
  );
}
