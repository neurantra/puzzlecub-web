import 'dart:convert';
import 'dart:js_interop';
import 'board.dart';
import 'move.dart';
import 'pieces.dart';
import 'square.dart';
import 'searcher.dart';

@JS('puzzlecubSearch')
external JSPromise<JSString> _search(JSString request);
@JS('puzzlecubStopSearch')
external void _stop(JSString id);

class WorkerSearch {
  static int _serial = 0;
  final String _id = 'worker-${_serial++}';
  bool _disposed = false;
  Future<SearchResult> search(
    Board board, {
    required int depth,
    Duration? budget,
  }) async {
    if (_disposed) return const SearchResult(move: null, score: 0, nodes: 0);
    try {
      final raw = await _search(
        jsonEncode({
          'id': _id,
          'depth': depth,
          'budget': (budget ?? const Duration(seconds: 2)).inMilliseconds,
          'moves': board.moveHistory
              .map(
                (m) => [
                  m.from.file,
                  m.from.rank,
                  m.to.file,
                  m.to.rank,
                  m.promotion?.index,
                ],
              )
              .toList(),
        }).toJS,
      ).toDart;
      if (_disposed) return const SearchResult(move: null, score: 0, nodes: 0);
      final data = jsonDecode(raw.toDart) as Map<String, dynamic>;
      final m = data['move'] as List<dynamic>?;
      return SearchResult(
        move: m == null
            ? null
            : Move(
                from: Square(m[0] as int, m[1] as int),
                to: Square(m[2] as int, m[3] as int),
                promotion: m[4] == null ? null : PieceType.values[m[4] as int],
              ),
        score: data['score'] as int? ?? 0,
        nodes: data['nodes'] as int? ?? 0,
      );
    } catch (_) {
      return const SearchResult(move: null, score: 0, nodes: 0);
    }
  }

  void dispose() {
    _disposed = true;
    _stop(_id.toJS);
  }
}

Future<SearchResult> webHint(Board board) async {
  final worker = WorkerSearch();
  try {
    return await worker.search(
      board,
      depth: 4,
      budget: const Duration(milliseconds: 1500),
    );
  } finally {
    worker.dispose();
  }
}
