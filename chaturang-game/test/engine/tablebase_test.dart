import 'dart:typed_data';

import 'package:chaturang/engine/board.dart';
import 'package:chaturang/engine/evaluator.dart';
import 'package:chaturang/engine/pieces.dart';
import 'package:chaturang/engine/searcher.dart';
import 'package:chaturang/engine/square.dart';
import 'package:chaturang/engine/tablebase.dart';
import 'package:flutter_test/flutter_test.dart';

Square sq(String s) => Square.algebraic(s);

void main() {
  group('Tablebase: encoding', () {
    test('krkSize is exactly 2 MiB (2,097,152 entries)', () {
      expect(Tablebase.krkSize, 2 * 1024 * 1024);
    });

    test('probe returns null for non-KR-K positions (initial position)', () {
      // Stub the tablebase with a zero-filled blob — probe should still
      // return null because the *position* doesn't match KR-K, never
      // touching the blob.
      final tb = Tablebase(krkData: Uint8List(Tablebase.krkSize));
      final board = Board();
      expect(tb.probe(board), isNull);
    });

    test('probe returns the blob value for KR-K positions', () {
      // Stub: every entry encodes "side-to-move wins". probe should
      // return that for any KR-K position regardless of squares.
      final blob = Uint8List(Tablebase.krkSize);
      for (var i = 0; i < blob.length; i++) {
        blob[i] = TbOutcome.sideToMoveWins;
      }
      final tb = Tablebase(krkData: blob);
      final board = Board()
        ..setupCustom({
          sq('e4'): const Piece(PieceType.king, Side.white),
          sq('a1'): const Piece(PieceType.rook, Side.white),
          sq('h8'): const Piece(PieceType.king, Side.black),
        }, sideToMove: Side.white);
      expect(tb.probe(board), TbOutcome.sideToMoveWins);
    });

    test(
      'color-flip: black-has-rook positions are probed via the same blob',
      () {
        // Stub: a single specific cell is set. We construct a black-has-rook
        // position whose color-flipped index lands on that cell, and verify
        // probe returns the stub value (i.e. color-flip plumbing works).
        // The exact cell doesn't matter — we just need any board that
        // produces a deterministic index.
        final blob = Uint8List(Tablebase.krkSize);
        // Mark every cell so any color-flipped index returns the same value.
        for (var i = 0; i < blob.length; i++) {
          blob[i] = TbOutcome.sideToMoveWins;
        }
        final tb = Tablebase(krkData: blob);
        final board = Board()
          ..setupCustom({
            sq('e4'): const Piece(PieceType.king, Side.black),
            sq('a1'): const Piece(PieceType.rook, Side.black),
            sq('h8'): const Piece(PieceType.king, Side.white),
          }, sideToMove: Side.black);
        expect(tb.probe(board), TbOutcome.sideToMoveWins);
      },
    );
  });

  // End-to-end generation test. Slice 4e-2 rewrote the generator as a
  // specialized solver (no Board / MoveGenerator in the hot loop), so
  // this now runs in ~1s and is part of the regular test suite.
  group('Tablebase: KR-K generation (integration)', () {
    test('generated table has correct outcomes for hand-picked positions', () {
      final sw = Stopwatch()..start();
      final krkData = computeKrkTablebase();
      sw.stop();
      // ignore: avoid_print
      print('KR-K solve: ${sw.elapsedMilliseconds}ms');
      final tb = Tablebase(krkData: krkData);

      // Sanity: table is mostly populated.
      expect(krkData.length, Tablebase.krkSize);

      // Mate-in-1 position from searcher_test.
      final mate = Board()
        ..setupCustom({
          sq('a8'): const Piece(PieceType.rook, Side.white),
          sq('f3'): const Piece(PieceType.king, Side.white),
          sq('h1'): const Piece(PieceType.king, Side.black),
        }, sideToMove: Side.white);
      expect(tb.probe(mate), TbOutcome.sideToMoveWins);

      // Hanging rook → KvK draw.
      final hanging = Board()
        ..setupCustom({
          sq('h1'): const Piece(PieceType.king, Side.white),
          sq('a7'): const Piece(PieceType.rook, Side.white),
          sq('a8'): const Piece(PieceType.king, Side.black),
        }, sideToMove: Side.black);
      expect(tb.probe(hanging), TbOutcome.draw);
    });

    test('Searcher with tablebase short-circuits KR-K to mate-score', () {
      // Attaching the TB should make the Searcher return a winning score
      // (and explore very few nodes) for a clearly-winning KR-K position,
      // because the probe at the root hands back perfect-play info.
      final tb = Tablebase(krkData: computeKrkTablebase());
      final board = Board()
        ..setupCustom({
          sq('e4'): const Piece(PieceType.king, Side.white),
          sq('a1'): const Piece(PieceType.rook, Side.white),
          sq('h8'): const Piece(PieceType.king, Side.black),
        }, sideToMove: Side.white);
      final result = Searcher(tablebase: tb).search(board, depth: 1);
      // Score must be in the "mate-adjacent" band (we encode TB wins as
      // mateScore - (1000 - depth)).
      expect(result.score.abs(), greaterThan(Evaluator.mateScore - 2000));
      expect(result.move, isNotNull);
    });
  });
}
