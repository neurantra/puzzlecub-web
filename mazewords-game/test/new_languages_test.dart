import 'package:flutter_test/flutter_test.dart';
import 'package:maze_words/domain/puzzle_language.dart';

void main() {
  test(
    'new Indic tiles retain marks and conjuncts and reject mixed scripts',
    () {
      const examples = {
        'te': 'క్షి',
        'kn': 'ಕ್ಷಿ',
        'ml': 'ക്ഷി',
        'gu': 'ક્ષિ',
        'mr': 'क्षि',
        'pa': 'ਕ੍ਰਿ',
      };
      for (final entry in examples.entries) {
        final script = PuzzleLanguage.of(entry.key);
        expect(script.id, entry.key);
        expect(script.indic, true);
        expect(script.validTile(entry.value), true, reason: entry.key);
        expect(
          script.validTile(entry.value.substring(1)),
          false,
          reason: entry.key,
        );
        expect(script.validTile('${entry.value}A'), false);
        expect(script.validTile('12'), false);
      }
      expect(PuzzleLanguage.of('ml').validTile('ൻ'), true);
      expect(PuzzleLanguage.of('ml').validTile('ക്'), true);
      expect(PuzzleLanguage.of('kn').validTile('ಕ್'), false);
      expect(PuzzleLanguage.of('pa').validTile('ੱ'), false);
      expect(PuzzleLanguage.of('pa').validTile('ਜੱ'), true);
      expect(PuzzleLanguage.of('pa').validWord('پنجابی'), false);
    },
  );
  test('Italian and Dutch preserve accented spellings', () {
    expect(PuzzleLanguage.of('it').validWord('CITTÀ'), true);
    expect(PuzzleLanguage.of('it').validWord('PERCHÉ'), true);
    expect(PuzzleLanguage.of('nl').validWord('IDEEËN'), true);
    expect(PuzzleLanguage.of('nl').validWord('FAÇADE'), true);
    expect(PuzzleLanguage.of('nl').validWord('IJS'), true);
    expect(PuzzleLanguage.of('nl').validTile('IJ'), false);
  });
}
