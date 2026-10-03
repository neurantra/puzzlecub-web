import 'board.dart';
import 'eval_params.dart';
import 'evaluator.dart';
import 'pieces.dart';
import 'square.dart';

/// Interface for a learned position evaluator.
///
/// Phase 3b sets up this abstraction; the production implementation
/// (Phase 3c, next session) will load a trained TFLite model exported by
/// `tool/nnue/train.py` and run it through `tflite_flutter` inside the
/// search isolate.
///
/// All implementations return centipawn evaluations from White's
/// perspective — positive = good for White. The Searcher mirrors to
/// side-to-move's perspective at use time, matching the convention used
/// by [Evaluator.evaluate].
abstract class NnueEvaluator {
  /// White-perspective centipawn evaluation of the position.
  int evaluateWhite(Board board);
}

/// Default implementation: delegates straight to the classical
/// [Evaluator]. Used until a trained model lands — keeps the Searcher's
/// code path uniform whether or not a NN is wired in.
///
/// Once Phase 3c provides a TFLite-backed implementation, this adapter
/// stays useful as a safety net for positions outside the training
/// distribution (e.g., wildly unbalanced material).
class ClassicalNnueAdapter implements NnueEvaluator {
  ClassicalNnueAdapter({this.params});

  /// Optional eval-parameter override. Null = engine defaults.
  final EvalParams? params;

  @override
  int evaluateWhite(Board board) => Evaluator.evaluate(board, params);
}

/// Feature encoding shared with the Python trainer (`tool/nnue/dataset.py`).
/// Keep this in lockstep with `featurize` in dataset.py.
class NnueFeatures {
  NnueFeatures._();

  /// 6 piece types × 2 sides = 12 piece kinds × 64 squares + 3 flag bits
  /// (side-to-move, white-leap-used, black-leap-used).
  static const int inputDim = 12 * 64 + 3;

  /// Writes the binary feature vector for [board] into [out]. [out] must
  /// have length [inputDim]; each slot is 0.0 or 1.0.
  static void encode(Board board, List<double> out) {
    if (out.length != inputDim) {
      throw ArgumentError(
        'Expected output of length $inputDim, got ${out.length}',
      );
    }
    for (var i = 0; i < out.length; i++) {
      out[i] = 0.0;
    }
    // Piece one-hots: square sq = file*8+rank, kind = type.index*2 + side.index.
    for (var f = 0; f < 8; f++) {
      for (var r = 0; r < 8; r++) {
        final piece = board.pieceAt(Square(f, r));
        if (piece == null) continue;
        final sq = f * 8 + r;
        final kind = piece.type.index * 2 + piece.side.index;
        out[sq * 12 + kind] = 1.0;
      }
    }
    out[12 * 64 + 0] = board.sideToMove == Side.white ? 0.0 : 1.0;
    out[12 * 64 + 1] = board.kingKnightMoveUsed(Side.white) ? 1.0 : 0.0;
    out[12 * 64 + 2] = board.kingKnightMoveUsed(Side.black) ? 1.0 : 0.0;
  }
}
