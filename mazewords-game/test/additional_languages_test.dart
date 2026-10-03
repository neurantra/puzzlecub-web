import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/domain/puzzle_language.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/domain/hunt.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/services/packs/pack_validation.dart';

void main() {
  test(
    'Latin accents, ligatures and capital sharp S remain distinct tiles',
    () {
      for (final row in [
        ('fr', ['É', 'Ç', 'Œ', 'Æ']),
        ('de', ['Ä', 'Ö', 'Ü', 'ẞ']),
        ('pt-BR', ['Ã', 'Õ', 'Ç', 'Ê']),
      ]) {
        final script = PuzzleLanguage.of(row.$1);
        for (final tile in row.$2) {
          expect(script.validTile(tile), true);
        }
        expect(script.validTile('AB'), false);
        expect(script.validTile('\u0301'), false);
      }
      expect(PuzzleLanguage.of('de').validWord('STRAẞE'), true);
      expect(PuzzleLanguage.of('pt-BR').validWord('CORAÇÃO'), true);
    },
  );
  test('Bengali conjuncts and Japanese contracted kana stay whole', () {
    final bn = PuzzleLanguage.of('bn'), ja = PuzzleLanguage.of('ja');
    for (final tile in ['কি', 'ব্র', 'ক্ষ', 'য়', 'ক্ত']) {
      expect(bn.validTile(tile), true, reason: tile);
    }
    for (final tile in ['ি', '্', 'কক', 'क']) {
      expect(bn.validTile(tile), false, reason: tile);
    }
    for (final tile in ['きゃ', 'しゅ', 'ちょ', 'っ', 'が', 'ん']) {
      expect(ja.validTile(tile), true, reason: tile);
    }
    for (final tile in ['ゃ', 'あゃ', 'がく', '学', 'カ', '\u3099']) {
      expect(ja.validTile(tile), false, reason: tile);
    }
    final bundle = validateBundle(
      File('pack_hosting/packs/ja/1.json').readAsStringSync(),
      'ja',
      1,
    );
    var paired = 0;
    for (final level in MazeLevel.values) {
      for (final maze in bundle.levels[level]!.mazes) {
        for (final l in maze.letters.where((l) => l.letter.runes.length == 2)) {
          paired++;
          final h = Hunt(maze: maze, level: level, relaxed: true)
            ..start(l.y * maze.width + l.x);
          expect(h.wordTileCount, 1);
          expect(h.submit(), FindResult.ignored);
          expect(h.mistakes, 0);
        }
      }
    }
    expect(paired, greaterThan(0));
  });
  test(
    'every new language persists independently without affecting the wallet',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PlayerStore(prefs);
      final balance = store.coins;
      for (final id in ['fr', 'de', 'pt-BR', 'bn', 'ja']) {
        await store.selectLanguage(id);
        expect(PlayerStore(prefs).language, id);
        expect(store.coins, balance);
      }
    },
  );
}
