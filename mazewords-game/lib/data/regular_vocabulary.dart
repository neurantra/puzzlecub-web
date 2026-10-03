import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../domain/maze.dart';
import '../domain/regular_goals.dart';

class RegularVocabulary {
  static final _cache = Expando<Future<MazePack>>();
  static Future<Map<String, Set<String>>>? _vocabulary;

  static Future<Map<String, Set<String>>> _load() async {
    final raw = await rootBundle.loadString('assets/regular_vocabulary.json');
    return (jsonDecode(raw) as Map<String, dynamic>).map(
      (language, words) =>
          MapEntry(language, (words as List).cast<String>().toSet()),
    );
  }

  static Future<MazePack> restore(MazePack pack, String language) =>
      _cache[pack] ??= _restore(pack, language);

  static Future<MazePack> _restore(MazePack pack, String language) async {
    final vocabulary = await (_vocabulary ??= _load());
    final words = vocabulary[language];
    if (words == null) return pack;
    return compute(_restoreInBackground, (pack, words));
  }
}

MazePack _restoreInBackground((MazePack, Set<String>) input) =>
    restoreRegularGoals(input.$1, input.$2);
