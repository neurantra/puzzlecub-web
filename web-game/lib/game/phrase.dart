/// A target phrase: exactly nine distinct letters, the alphabet of one puzzle.
///
/// Every Alphadoku grid is a Sudoku over this nine-letter alphabet rather than
/// over 1-9. [letters] is the natural reading order of the phrase, so
/// `letters[i]` is the letter a solver expects at index `i` of the mystery
/// axis. The constructor is const so the corpus is a compile-time constant.
class Phrase {
  const Phrase({required this.text, required this.tier});

  /// Display form, including spaces: `MONEY TALK`.
  final String text;

  final PhraseTier tier;

  /// Compact form used as a puzzle key: `MONEYTALK`.
  String get key => text.replaceAll(' ', '');

  /// The nine letters in reading order, spaces stripped.
  List<String> get letters => key.split('');

  /// Index of [letter] in the phrase, or -1. Letters are unique within a
  /// phrase, so this is also the only axis position that can hold that letter.
  int indexOf(String letter) => key.indexOf(letter);

  /// True only for a genuine nine-letter isogram. Enforced by the corpus test.
  bool get isValid => key.length == 9 && key.split('').toSet().length == 9;

  @override
  String toString() => text;
}

enum PhraseTier {
  /// One word: ALGORITHM.
  single('Single word'),

  /// Two words: MONEY TALK.
  pair('Two words'),

  /// Three words: WET DOG RUN.
  triple('Three words');

  const PhraseTier(this.label);
  final String label;
}
