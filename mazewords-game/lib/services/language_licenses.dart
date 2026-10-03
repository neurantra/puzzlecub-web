import 'package:flutter/foundation.dart';

const languageCredits = [
  (
    title: 'ENABLE',
    summary: 'English · Public domain',
    details:
        'ENABLE word list by M. Cooper and A. Beale (public domain), with frequency ranking from wordfreq.\nhttps://github.com/dolph/dictionary\n\n',
  ),
  (
    title: 'Wiktionary',
    summary: 'Shared language data · CC BY-SA 4.0',
    details:
        'Italian, Dutch, Telugu, Malayalam, Gujarati, Marathi, Gurmukhi Punjabi, Spanish, French, German, Portuguese, Hindi and Bengali. Wiktionary contributors, extracted by Tatu Ylonen and the Wiktextract/Kaikki project. Vocabulary is normalized and filtered, with frequency ranking where data is available. Licensed under CC BY-SA 4.0.\nhttps://en.wiktionary.org\nhttps://kaikki.org/dictionary/\n\n',
  ),
  (
    title: 'Alar',
    summary: 'Kannada · ODbL 1.0',
    details:
        'Contains information from V. Krishna’s Alar Kannada–English dictionary, made available under ODbL 1.0. The Kannada database modification method is freely available at https://mazewords-packs.web.app/licenses/kannada-modification-method.zip .\nhttps://alar.ink/\nhttps://github.com/alar-dict/data\nhttps://opendatacommons.org/licenses/odbl/1-0/\n\n',
  ),
  (
    title: 'JMdict',
    summary: 'Japanese · CC BY-SA 4.0',
    details:
        'This application uses the JMdict dictionary file. Copyright James William Breen and the Electronic Dictionary Research and Development Group. Hiragana readings are filtered and frequency-ranked. Licensed under CC BY-SA 4.0.\nhttps://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project\nhttps://www.edrdg.org/edrdg/licence.html\n\n',
  ),
  (
    title: 'wordfreq',
    summary: 'Frequency data · CC BY-SA 4.0',
    details:
        'wordfreq 3.1.1 by Robyn Speer and contributors. Used for frequency ranking only in supported languages, including Italian and Dutch. Telugu, Kannada, Malayalam, Gujarati, Marathi and Punjabi have no frequency ranking yet. Frequency data and its derived vocabulary are CC BY-SA 4.0. The source documentation lists the contributing corpora.\nhttps://github.com/rspeer/wordfreq\n\n',
  ),
  (
    title: 'Tamil sources',
    summary: 'PowerTamil and Kaniyam Foundation',
    details:
        'PowerTamil dictionary (MIT) and the Kaniyam Foundation Tamil frequency corpus.\nhttps://github.com/rajkumarpal07/powertamil-dictionary\nhttps://github.com/KaniyamFoundation/all_tamil_words\n\n',
  ),
  (
    title: 'Data license details',
    summary: 'Notices and modifications',
    details:
        'Wiktionary/wordfreq-derived lists and packs are CC BY-SA 4.0. The separate Kannada database is ODbL 1.0; Tamil retains its own source terms. These data licenses do not apply to the app code. Source notices and license details:\nhttps://mazewords-packs.web.app/licenses/\n\nLicense:\nhttps://creativecommons.org/licenses/by-sa/4.0/\n\n',
  ),
];

bool _registered = false;
void registerLanguageLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Maze Words language data',
    ], languageCredits.map((credit) => credit.details).join('\n\n'));
  });
}
