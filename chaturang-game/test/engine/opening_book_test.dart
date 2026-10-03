import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/move.dart';
import 'package:chaturang/engine/move_generator.dart';
import 'package:chaturang/engine/opening_book.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/searcher.dart';
import 'package:chaturang/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips a position and a move', () {
    final b = Board();
    // e2e3: a white padati stepping one square. Chaturang has no
    // double-step, so e2e4 would not be legal.
    final book = OpeningBook.parse('${b.zobrist.toRadixString(16)} e7e6\n');
    expect(book.length, 1);
    expect(
      book.lookup(b.zobrist),
      const Move(from: Square(4, 6), to: Square(4, 5)),
    );
    expect(book.lookup(BigInt.from(0)), isNull);
  });

  test('comments, blanks and junk lines are skipped, not fatal', () {
    // A book is an optimisation. A corrupt one should cost the engine its
    // head start, not the game.
    final book = OpeningBook.parse('''
# a comment

deadbeef e7e5
not-hex   e7e5
cafe      zzzz
cafe2     e7
''');
    expect(book.length, 1);
    expect(book.lookup(BigInt.from(0xdeadbeef)), isNotNull);
  });

  test('a promotion survives the round trip', () {
    final book = OpeningBook.parse('1 a7a8C\n');
    final m = book.lookup(BigInt.from(1));
    expect(m!.promotion, PieceType.counsellor);
  });

  test('a book move is played without searching', () {
    final b = Board();
    const chosen = Move(from: Square(4, 6), to: Square(4, 5));
    final book = OpeningBook.parse('${b.zobrist.toRadixString(16)} e7e6\n');
    final r = Searcher(book: book).search(b, depth: 6);
    expect(r.move, chosen);
    expect(r.nodes, 0, reason: 'a book hit should not search at all');
  });

  test('an illegal book move is ignored rather than played', () {
    // Guards against a book built against different move generation, or
    // simply corrupted. Playing an illegal move would be far worse than
    // losing the head start.
    final b = Board();
    final book = OpeningBook.parse('${b.zobrist.toRadixString(16)} a1h8\n');
    final r = Searcher(book: book).search(b, depth: 3);
    expect(r.move, isNotNull);
    expect(MoveGenerator.legalMoves(b), contains(r.move));
    expect(r.nodes, greaterThan(0), reason: 'it should have searched');
  });

  test('out of book, the search runs normally', () {
    final b = Board();
    b.makeMove(const Move(from: Square(4, 6), to: Square(4, 5)));
    final r = Searcher(book: OpeningBook.empty).search(b, depth: 3);
    expect(r.move, isNotNull);
    expect(r.nodes, greaterThan(0));
  });
}
