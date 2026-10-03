import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maze_words/services/language_licenses.dart';

void main() {
  test(
    'language credits remain available offline without duplicate registration',
    () async {
      registerLanguageLicenses();
      registerLanguageLicenses();
      final entries = await LicenseRegistry.licenses
          .where((entry) => entry.packages.contains('Maze Words language data'))
          .toList();
      expect(entries, hasLength(1));
      final text = entries.single.paragraphs.map((p) => p.text).join('\n');
      for (final credit in [
        'JMdict',
        'James William Breen',
        'V. Krishna',
        'ODbL 1.0',
        'CC BY-SA 4.0',
        'PowerTamil',
        'MIT',
        'public domain',
      ]) {
        expect(text, contains(credit));
      }
    },
  );
}
