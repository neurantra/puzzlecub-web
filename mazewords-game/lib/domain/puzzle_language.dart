import 'indic_script_rules.dart';

/// Supported puzzle scripts. Menu text remains English during language previews.
class PuzzleLanguage {
  const PuzzleLanguage(
    this.id,
    this.name,
    this.flag,
    this.font, {
    this.indic = false,
    this.kana = false,
  });
  final String id, name, flag, font;
  final bool indic, kana;
  bool get complexTiles => indic || kana;
  int get minimumTiles => complexTiles ? 2 : 3;
  static const all = [
    PuzzleLanguage('en', 'English', '🇺🇸', 'PlusJakartaSans'),
    PuzzleLanguage('es', 'Español', '🇪🇸', 'PlusJakartaSans'),
    PuzzleLanguage('ta', 'தமிழ் · Tamil', '🇮🇳', 'NotoSansTamil', indic: true),
    PuzzleLanguage(
      'hi',
      'हिन्दी · Hindi',
      '🇮🇳',
      'NotoSansDevanagari',
      indic: true,
    ),
    PuzzleLanguage('fr', 'Français', '🇫🇷', 'PlusJakartaSans'),
    PuzzleLanguage('de', 'Deutsch', '🇩🇪', 'PlusJakartaSans'),
    PuzzleLanguage('pt-BR', 'Português · Brasil', '🇧🇷', 'PlusJakartaSans'),
    PuzzleLanguage(
      'bn',
      'বাংলা · Bengali',
      '🇧🇩',
      'NotoSansBengali',
      indic: true,
    ),
    PuzzleLanguage('ja', '日本語 · Hiragana', '🇯🇵', 'NotoSansJP', kana: true),
    PuzzleLanguage('it', 'Italiano · Italian', '🇮🇹', 'PlusJakartaSans'),
    PuzzleLanguage('nl', 'Nederlands · Dutch', '🇳🇱', 'PlusJakartaSans'),
    PuzzleLanguage(
      'te',
      'తెలుగు · Telugu',
      '🇮🇳',
      'NotoSansTelugu',
      indic: true,
    ),
    PuzzleLanguage(
      'kn',
      'ಕನ್ನಡ · Kannada',
      '🇮🇳',
      'NotoSansKannada',
      indic: true,
    ),
    PuzzleLanguage(
      'ml',
      'മലയാളം · Malayalam',
      '🇮🇳',
      'NotoSansMalayalam',
      indic: true,
    ),
    PuzzleLanguage(
      'gu',
      'ગુજરાતી · Gujarati',
      '🇮🇳',
      'NotoSansGujarati',
      indic: true,
    ),
    PuzzleLanguage(
      'mr',
      'मराठी · Marathi',
      '🇮🇳',
      'NotoSansDevanagari',
      indic: true,
    ),
    PuzzleLanguage(
      'pa',
      'ਪੰਜਾਬੀ · Punjabi (Gurmukhi)',
      '🇮🇳',
      'NotoSansGurmukhi',
      indic: true,
    ),
  ];
  static bool supports(String id) => all.any((l) => l.id == id);
  static PuzzleLanguage of(String id) =>
      all.firstWhere((l) => l.id == id, orElse: () => all.first);

  String get alphabet => switch (id) {
    'it' => 'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÈÉÌÍÒÓÙÚ',
    'nl' => 'ABCDEFGHIJKLMNOPQRSTUVWXYZÁÀÂÄÇÉÈÊËÍÎÏÓÔÖÚÛÜ',
    'es' => 'ABCDEFGHIJKLMNOPQRSTUVWXYZÁÉÍÓÚÜÑ',
    'fr' => 'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÂÆÇÉÈÊËÎÏÔŒÙÛÜŸ',
    'de' => 'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜẞ',
    'pt-BR' => 'ABCDEFGHIJKLMNOPQRSTUVWXYZÁÀÂÃÉÊÍÓÔÕÚÜÇ',
    _ => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  };
  int get _virama =>
      indicScriptRules[id]?.virama ?? (id == 'bn' ? 0x9cd : 0x94d);
  bool _base(int r) => indicScriptRules.containsKey(id)
      ? indicScriptRules[id]!.bases.contains(String.fromCharCode(r))
      : id == 'bn'
      ? (r >= 0x985 && r <= 0x98c) ||
            (r >= 0x98f && r <= 0x990) ||
            (r >= 0x993 && r <= 0x9a8) ||
            (r >= 0x9aa && r <= 0x9b0) ||
            r == 0x9b2 ||
            (r >= 0x9b6 && r <= 0x9b9) ||
            r == 0x9ce ||
            r == 0x9dc ||
            r == 0x9dd ||
            r == 0x9df ||
            r == 0x9e0 ||
            r == 0x9e1
      : id == 'ta'
      ? 'அஆஇஈஉஊஎஏஐஒஓஔகஙசஞடணதநபமயரலவழளறனஜஷஸஹ'.runes.contains(r)
      : (r >= 0x904 && r <= 0x939) || (r >= 0x958 && r <= 0x95f);
  bool _mark(int r) => indicScriptRules.containsKey(id)
      ? indicScriptRules[id]!.marks.contains(String.fromCharCode(r))
      : id == 'bn'
      ? [
          0x981,
          0x982,
          0x983,
          0x9bc,
          0x9be,
          0x9bf,
          0x9c0,
          0x9c1,
          0x9c2,
          0x9c3,
          0x9c4,
          0x9c7,
          0x9c8,
          0x9cb,
          0x9cc,
          0x9cd,
          0x9d7,
          0x9e2,
          0x9e3,
        ].contains(r)
      : id == 'ta'
      ? [
          0xbbe,
          0xbbf,
          0xbc0,
          0xbc1,
          0xbc2,
          0xbc6,
          0xbc7,
          0xbc8,
          0xbca,
          0xbcb,
          0xbcc,
          0xbcd,
          0xbd7,
        ].contains(r)
      : (r >= 0x900 && r <= 0x903) ||
            (r >= 0x93a && r <= 0x94d) ||
            (r >= 0x951 && r <= 0x957) ||
            r == 0x962 ||
            r == 0x963;
  bool validTile(String value) {
    if (kana) {
      return (RegExp(r'^[あ-ゖ]$').hasMatch(value) &&
              !'ぃぅぇぉゃゅょゎゕゖ'.contains(value)) ||
          RegExp(r'^[きぎしじちぢにひびぴみり][ゃゅょ]$').hasMatch(value);
    }
    if (!indic) return value.runes.length == 1 && alphabet.contains(value);
    final runes = value.runes.toList();
    if (runes.isEmpty || runes.length > 12 || !_base(runes.first)) return false;
    for (var i = 1; i < runes.length; i++) {
      if (_mark(runes[i])) continue;
      if (id != 'ta' && runes[i - 1] == _virama && _base(runes[i])) continue;
      return false;
    }
    return id == 'ta' ||
        (indicScriptRules[id]?.allowTerminalVirama ?? false) ||
        runes.last != _virama;
  }

  bool validWord(String value) {
    if (kana) {
      return RegExp(r'^[ぁ-ゖ]{2,32}$').hasMatch(value);
    }
    if (!indic) {
      return value.runes.length >= 3 &&
          value.runes.length <= 24 &&
          value.runes.every((r) => alphabet.contains(String.fromCharCode(r)));
    }
    final runes = value.runes.toList();
    return runes.length >= 2 &&
        runes.length <= 96 &&
        _base(runes.first) &&
        runes.every((r) => _base(r) || _mark(r));
  }
}
