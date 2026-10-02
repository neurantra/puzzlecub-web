import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/corpus.dart';
import '../game/difficulty.dart';
import '../game/generator.dart';
import '../game/phrase.dart';
import '../game/puzzle.dart';
import 'target_history.dart';

Future<void> _generationQueue = Future<void>.value();

/// Serialize selection and recording so simultaneous requests cannot draw the
/// same target. Only a successfully generated puzzle is added to the history.
Future<Puzzle> buildPuzzle(Difficulty difficulty) {
  final result = _generationQueue.then((_) async {
    final day = Uri.base.queryParameters['day'];
    if (day != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) {
      final seed = int.parse(day.replaceAll('-', ''));
      return Generator(random: Random(seed)).generate(Difficulty.medium);
    }
    final history = TargetHistory();
    final phrase = await history.choose(corpus, Random());
    final puzzle = await compute(_generate, (difficulty, phrase));
    await history.record(phrase);
    return puzzle;
  });
  _generationQueue = result.then<void>((_) {}, onError: (Object _) {});
  return result;
}

Puzzle _generate((Difficulty, Phrase) request) =>
    Generator().generate(request.$1, phrase: request.$2);
