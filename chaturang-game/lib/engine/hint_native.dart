import 'board.dart';
import 'searcher.dart';

Future<SearchResult> webHint(Board board) async => Searcher().search(
  board,
  depth: 4,
  budget: const Duration(milliseconds: 1500),
);
