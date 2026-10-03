import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:maze_words/domain/hunt.dart';
import 'package:maze_words/domain/maze.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/domain/regular_goals.dart';
import 'package:maze_words/data/regular_vocabulary.dart';
import 'package:maze_words/services/packs/pack_validation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final vocabulary =
      (jsonDecode(File('assets/regular_vocabulary.json').readAsStringSync())
              as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as List).cast<String>().toSet()));

  test(
    'all installed language goals are restored with playable hint paths',
    () {
      final catalog =
          jsonDecode(File('assets/pack_catalog.json').readAsStringSync())
              as Map;
      for (final entry in catalog['packs'] as List) {
        final language = entry['id'] as String;
        final bundle = validateBundle(
          File('pack_hosting/${entry['path']}').readAsStringSync(),
          language,
          entry['revision'] as int,
        );
        for (final pack in bundle.levels.values) {
          final restored = restoreRegularGoals(pack, vocabulary[language]!);
          for (var i = 0; i < pack.mazes.length; i++) {
            final before = pack.mazes[i];
            final maze = restored.mazes[i];
            expect(maze.words, before.words);
            expect(maze.walls, before.walls);
            expect(maze.commonWords.toSet(), {
              ...before.commonWords,
              ...before.words.where(vocabulary[language]!.contains),
            }, reason: '$language/${maze.id}');
            for (final word in maze.commonWords.where(
              (w) => !before.isCommon(w),
            )) {
              final hunt = Hunt(maze: maze, level: pack.level, relaxed: true);
              final route = maze.commonPaths[word]!;
              hunt.start(route.first);
              for (final cell in route.skip(1)) {
                expect(
                  hunt.step(cell),
                  isTrue,
                  reason: '$language/${maze.id}: $word',
                );
              }
              expect(hunt.word, word);
              expect(hunt.submit(), FindResult.common);
              expect(hunt.commonFound, 1);
              expect(hunt.rareFound, 0);
            }
            for (final word in maze.words.where(
              (w) => !vocabulary[language]!.contains(w) && !before.isCommon(w),
            )) {
              expect(maze.isCommon(word), isFalse);
            }
          }
        }
      }
    },
  );

  test(
    'bundled English and async restoration retain every familiar goal',
    () async {
      for (final level in MazeLevel.values) {
        final pack = MazePack.fromJson(
          level,
          jsonDecode(File('assets/maze/${level.name}.json').readAsStringSync())
              as Map<String, dynamic>,
        );
        final restored = await RegularVocabulary.restore(pack, 'en');
        expect(
          identical(await RegularVocabulary.restore(pack, 'en'), restored),
          isTrue,
        );
        for (final maze in restored.mazes) {
          expect(
            maze.commonWords,
            containsAll(maze.words.where(vocabulary['en']!.contains)),
          );
        }
      }
    },
  );
}
