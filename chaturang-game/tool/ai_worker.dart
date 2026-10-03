import 'dart:convert';
import 'dart:js_interop';
import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/move.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/square.dart';
import 'package:chaturang/engine/searcher.dart';
import 'package:chaturang/engine/opening_book.dart';
import 'package:chaturang/engine/tablebase.dart';

@JS('self.onmessage')
external set onMessage(JSFunction value);
@JS('self.postMessage')
external void postMessage(JSString value);
@JS()
extension type Message(JSObject _) implements JSObject {
  external JSString get data;
}
void main() {
  Searcher? searcher;
  onMessage = ((Message event) {
    try {
      final req = jsonDecode(event.data.toDart) as Map<String, dynamic>;
      if (req['init'] == true) {
        searcher = Searcher(
          book: OpeningBook.parse(req['book'] as String? ?? ''),
          tablebase: req['tablebase'] == null
              ? null
              : Tablebase(krkData: base64Decode(req['tablebase'] as String)),
          options: const SearchOptions(reuseTable: true),
        );
        return;
      }
      final board = Board();
      for (final raw in req['moves'] as List<dynamic>) {
        final m = raw as List<dynamic>;
        board.makeMove(
          Move(
            from: Square(m[0] as int, m[1] as int),
            to: Square(m[2] as int, m[3] as int),
            promotion: m[4] == null ? null : PieceType.values[m[4] as int],
          ),
        );
      }
      searcher ??= Searcher(options: const SearchOptions(reuseTable: true));
      final result = searcher!.search(
        board,
        depth: req['depth'] as int,
        budget: Duration(milliseconds: req['budget'] as int),
      );
      final m = result.move;
      postMessage(
        jsonEncode({
          'move': m == null
              ? null
              : [
                  m.from.file,
                  m.from.rank,
                  m.to.file,
                  m.to.rank,
                  m.promotion?.index,
                ],
          'score': result.score,
          'nodes': result.nodes,
        }).toJS,
      );
    } catch (_) {
      postMessage('{"move":null,"error":true}'.toJS);
    }
  }).toJS;
}
