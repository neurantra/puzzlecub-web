import '../../domain/puzzle_language.dart';

/// v1.1 commercial contract. Not connected to the v1.0 purchase/download UI.
/// Prices displayed to players must come from the store, never this catalog.
class LanguageProduct {
  const LanguageProduct(this.language, this.productId);
  final String language;
  final String productId;
  int get freeMazesPerLevel => language == 'en' ? 20 : 12;
  int get paidMazesPerLevel => fullMazesPerLevel - freeMazesPerLevel;
  static const fullMazesPerLevel = 150;
  static const minimumDistinctWords = 2000;
  static const all = [
    LanguageProduct('en', 'com.mazewords.app.language.en'),
    LanguageProduct('es', 'com.mazewords.app.language.es'),
    LanguageProduct('ta', 'com.mazewords.app.language.ta'),
    LanguageProduct('hi', 'com.mazewords.app.language.hi'),
    LanguageProduct('fr', 'com.mazewords.app.language.fr'),
    LanguageProduct('de', 'com.mazewords.app.language.de'),
    LanguageProduct('pt-BR', 'com.mazewords.app.language.pt_br'),
    LanguageProduct('bn', 'com.mazewords.app.language.bn'),
    LanguageProduct('ja', 'com.mazewords.app.language.ja'),
    LanguageProduct('it', 'com.mazewords.app.language.it'),
    LanguageProduct('nl', 'com.mazewords.app.language.nl'),
    LanguageProduct('te', 'com.mazewords.app.language.te'),
    LanguageProduct('kn', 'com.mazewords.app.language.kn'),
    LanguageProduct('ml', 'com.mazewords.app.language.ml'),
    LanguageProduct('gu', 'com.mazewords.app.language.gu'),
    LanguageProduct('mr', 'com.mazewords.app.language.mr'),
    LanguageProduct('pa', 'com.mazewords.app.language.pa'),
  ];

  static LanguageProduct forLanguage(String language) {
    if (!PuzzleLanguage.supports(language)) {
      throw ArgumentError.value(language, 'language', 'Unsupported language');
    }
    return all.firstWhere((p) => p.language == language);
  }

  static LanguageProduct? forProduct(String id) {
    for (final product in all) {
      if (product.productId == id) return product;
    }
    return null;
  }
}
