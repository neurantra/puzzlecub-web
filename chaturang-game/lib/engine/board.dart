import 'move.dart';
import 'pieces.dart';
import 'square.dart';
import 'zobrist.dart';

/// Opening-position back ranks. Note the asymmetry: Black has King on e1
/// (file 4) and Counsellor on d1 (file 3); White has King on d8 (file 3)
/// and Counsellor on e8 (file 4). The two kings are diagonally opposite,
/// not file-aligned.
const List<PieceType> blackBackRank = [
  PieceType.rook,
  PieceType.knight,
  PieceType.elephant,
  PieceType.counsellor,
  PieceType.king,
  PieceType.elephant,
  PieceType.knight,
  PieceType.rook,
];

const List<PieceType> whiteBackRank = [
  PieceType.rook,
  PieceType.knight,
  PieceType.elephant,
  PieceType.king,
  PieceType.counsellor,
  PieceType.elephant,
  PieceType.knight,
  PieceType.rook,
];

/// Mutable Chaturang board state.
///
/// Holds piece positions, side to move, and the per-side flag tracking
/// whether the king has spent its once-per-game knight move. Move history
/// is kept for undo.
///
/// This class is intentionally a low-level state container: it does NOT
/// validate move legality. The move generator (added next) is responsible
/// for producing legal moves; this class only applies and reverses them.
class Board {
  Board() {
    setupInitial();
  }

  // Indexed as [file][rank]; null = empty square.
  final List<List<Piece?>> _pieces = List.generate(
    8,
    (_) => List.filled(8, null),
  );

  Side _sideToMove = Side.white;
  bool _whiteKingKnightMoveUsed = false;
  bool _blackKingKnightMoveUsed = false;
  final List<_HistoryEntry> _history = [];

  /// Zobrist hash of the current position. Maintained incrementally in
  /// [makeMove] / [undoMove]; recomputed from scratch in [setupInitial] /
  /// [setupCustom]. Used by the searcher's transposition table.
  BigInt _zobrist = BigInt.zero;
  BigInt get zobrist => _zobrist;

  /// Zobrist key of every position reached, current one last.
  ///
  /// Kept so repetition can be detected without replaying the move list.
  /// A capture is irreversible — no earlier position can recur across one —
  /// so [_irreversiblePly] marks where the search back has to stop, which
  /// keeps the scan short in the long quiet phases where it matters most.
  final List<BigInt> _positionKeys = <BigInt>[];
  final List<int> _irreversibleStack = <int>[];
  int _irreversiblePly = 0;

  /// How many times the current position has occurred, itself included.
  ///
  /// Two means the position is on the board for the second time; three is
  /// the threefold that ends the game.
  int repetitionCount() {
    var count = 1;
    // The current position is the last key; same-side-to-move positions sit
    // two plies apart, so the previous candidate is length-3, not length-2.
    for (var i = _positionKeys.length - 3; i >= _irreversiblePly; i -= 2) {
      if (_positionKeys[i] == _zobrist) count++;
    }
    return count;
  }

  /// True when the current position has occurred before in this game. The
  /// search treats this as a draw immediately rather than waiting for a
  /// third occurrence — by then the repetition is already forced, and
  /// scoring it sooner is what lets the engine find perpetuals and avoid
  /// shuffling in positions it should be winning.
  bool get isRepetition => repetitionCount() >= 2;

  /// Where each side's king stands, indexed by [Side.index]. Maintained
  /// incrementally so that check detection — asked at every node, for every
  /// candidate move — starts from the king rather than scanning for it.
  /// Null only in a test position built without that king.
  final List<Square?> _kingSquares = [null, null];

  /// Pieces on the board, in total and per side excluding king and padatis.
  /// Kept so the null-move zugzwang guard and the tablebase probe can answer
  /// their material questions without a board scan.
  int _pieceCount = 0;
  final List<int> _nonPawnPieceCount = [0, 0];

  Square? kingSquare(Side side) => _kingSquares[side.index];
  int get pieceCount => _pieceCount;

  /// How many pieces [side] has that are neither its raja nor a padati.
  int nonPawnPieceCount(Side side) => _nonPawnPieceCount[side.index];

  Side get sideToMove => _sideToMove;
  int get plyCount => _history.length;

  /// Read-only snapshot of every move played so far, in play order.
  /// The board owns the canonical list; this getter just exposes the
  /// `Move` projection (callers don't need the captured-piece +
  /// king-knight-flag bookkeeping that lives in [_HistoryEntry]).
  /// Useful for the end-of-game move-list modal and any future
  /// PGN-style export.
  List<Move> get moveHistory =>
      List<Move>.unmodifiable(_history.map((e) => e.move));

  /// The most recent move played, or null at the start of the game. A null
  /// move leaves no entry, so after one this is still the last real move.
  Move? get lastMove => _history.isEmpty ? null : _history.last.move;

  bool kingKnightMoveUsed(Side side) =>
      side == Side.white ? _whiteKingKnightMoveUsed : _blackKingKnightMoveUsed;

  Piece? pieceAt(Square square) => _pieces[square.file][square.rank];

  /// [pieceAt] without the [Square]: for the inner loops that would
  /// otherwise allocate one per square just to unwrap it again.
  Piece? pieceAtCoords(int file, int rank) => _pieces[file][rank];

  /// Pieces [captor] has captured over the course of the game so far —
  /// i.e. enemy pieces removed by [captor]'s moves, in chronological order.
  List<Piece> capturedBy(Side captor) {
    return [
      for (final entry in _history)
        if (entry.movedPiece.side == captor && entry.captured != null)
          entry.captured!,
    ];
  }

  /// Resets the board to the opening Chaturang position with White to move.
  void setupInitial() {
    for (var f = 0; f < 8; f++) {
      for (var r = 0; r < 8; r++) {
        _pieces[f][r] = null;
      }
    }
    for (var f = 0; f < 8; f++) {
      _pieces[f][0] = Piece(blackBackRank[f], Side.black);
      _pieces[f][1] = const Piece(PieceType.pawn, Side.black);
      _pieces[f][6] = const Piece(PieceType.pawn, Side.white);
      _pieces[f][7] = Piece(whiteBackRank[f], Side.white);
    }
    _sideToMove = Side.white;
    _whiteKingKnightMoveUsed = false;
    _blackKingKnightMoveUsed = false;
    _history.clear();
    _recomputeZobrist();
    _recomputeMaterial();
    _resetPositionHistory();
  }

  /// Test helper: place pieces directly. Clears existing state and history.
  void setupCustom(
    Map<Square, Piece> pieces, {
    Side sideToMove = Side.white,
    bool whiteKingKnightUsed = false,
    bool blackKingKnightUsed = false,
  }) {
    for (var f = 0; f < 8; f++) {
      for (var r = 0; r < 8; r++) {
        _pieces[f][r] = null;
      }
    }
    pieces.forEach((sq, p) {
      _pieces[sq.file][sq.rank] = p;
    });
    _sideToMove = sideToMove;
    _whiteKingKnightMoveUsed = whiteKingKnightUsed;
    _blackKingKnightMoveUsed = blackKingKnightUsed;
    _history.clear();
    _recomputeZobrist();
    _recomputeMaterial();
    _resetPositionHistory();
  }

  /// Rebuilds the king squares and piece counts from the board. Only used
  /// at setup time — make/undo maintain them incrementally.
  void _recomputeMaterial() {
    _kingSquares[0] = null;
    _kingSquares[1] = null;
    _pieceCount = 0;
    _nonPawnPieceCount[0] = 0;
    _nonPawnPieceCount[1] = 0;
    for (var f = 0; f < 8; f++) {
      for (var r = 0; r < 8; r++) {
        final p = _pieces[f][r];
        if (p == null) continue;
        _pieceCount++;
        if (p.type == PieceType.king) {
          _kingSquares[p.side.index] = Square(f, r);
        } else if (p.type != PieceType.pawn) {
          _nonPawnPieceCount[p.side.index]++;
        }
      }
    }
  }

  /// Seeds the repetition history with the current position. Must run
  /// AFTER [_recomputeZobrist] — seeding it with the stale hash would make
  /// the starting position unmatchable, so no line could ever be seen to
  /// return to it.
  void _resetPositionHistory() {
    _positionKeys
      ..clear()
      ..add(_zobrist);
    _irreversibleStack.clear();
    _irreversiblePly = 0;
  }

  /// Computes the Zobrist hash from scratch by XOR-ing the appropriate
  /// term for every piece + side-to-move + king-leap flag. Only used at
  /// setup time — make/undo maintain the hash incrementally.
  void _recomputeZobrist() {
    var key = BigInt.zero;
    for (var f = 0; f < 8; f++) {
      for (var r = 0; r < 8; r++) {
        final p = _pieces[f][r];
        if (p != null) key ^= Zobrist.piece(p.type, p.side, f, r);
      }
    }
    if (_sideToMove == Side.black) key ^= Zobrist.sideToMove;
    if (_whiteKingKnightMoveUsed) key ^= Zobrist.kingLeap(Side.white);
    if (_blackKingKnightMoveUsed) key ^= Zobrist.kingLeap(Side.black);
    _zobrist = key;
  }

  /// Applies [move]. Assumes the caller has verified legality.
  void makeMove(Move move) {
    final piece = _pieces[move.from.file][move.from.rank];
    if (piece == null) {
      throw StateError('makeMove: no piece at ${move.from}');
    }

    final captured = _pieces[move.to.file][move.to.rank];
    final prevFlag = kingKnightMoveUsed(piece.side);
    final usedKnightLeap =
        piece.type == PieceType.king && _isKnightOffset(move.from, move.to);
    final placedPiece = move.promotion != null
        ? Piece(move.promotion!, piece.side)
        : piece;

    _pieces[move.from.file][move.from.rank] = null;
    _pieces[move.to.file][move.to.rank] = placedPiece;

    if (piece.type == PieceType.king) {
      _kingSquares[piece.side.index] = move.to;
    } else if (move.promotion != null) {
      // A padati became a piece that counts.
      _nonPawnPieceCount[piece.side.index]++;
    }
    if (captured != null) {
      _pieceCount--;
      if (captured.type == PieceType.king) {
        _kingSquares[captured.side.index] = null;
      } else if (captured.type != PieceType.pawn) {
        _nonPawnPieceCount[captured.side.index]--;
      }
    }

    // Incremental Zobrist: XOR out the from-square piece, the captured
    // piece (if any), and the side-to-move flag; XOR in the placed
    // piece's hash. king-leap flag is XOR'd only on transition.
    _zobrist ^= Zobrist.piece(
      piece.type,
      piece.side,
      move.from.file,
      move.from.rank,
    );
    if (captured != null) {
      _zobrist ^= Zobrist.piece(
        captured.type,
        captured.side,
        move.to.file,
        move.to.rank,
      );
    }
    _zobrist ^= Zobrist.piece(
      placedPiece.type,
      placedPiece.side,
      move.to.file,
      move.to.rank,
    );
    _zobrist ^= Zobrist.sideToMove;
    if (usedKnightLeap && !prevFlag) {
      _zobrist ^= Zobrist.kingLeap(piece.side);
    }

    if (usedKnightLeap) {
      if (piece.side == Side.white) {
        _whiteKingKnightMoveUsed = true;
      } else {
        _blackKingKnightMoveUsed = true;
      }
    }

    _history.add(
      _HistoryEntry(
        move: move,
        movedPiece: piece,
        captured: captured,
        prevKingKnightMoveUsed: prevFlag,
      ),
    );
    _sideToMove = _sideToMove.opposite;

    _irreversibleStack.add(_irreversiblePly);
    // A capture or a promotion can never be undone by later play, so no
    // position before it can repeat.
    if (captured != null || move.promotion != null) {
      // The key about to be appended lands at the current length, and that
      // position can itself recur — it is everything strictly before it
      // that cannot. So the floor is the index of the new position.
      _irreversiblePly = _positionKeys.length;
    }
    _positionKeys.add(_zobrist);
  }

  /// Passes the turn without moving a piece.
  ///
  /// Not a legal Chaturang move — it exists for null-move pruning, where the
  /// search asks "if I did nothing here, would the position still be good
  /// enough?" A yes means the real moves are almost certainly better still,
  /// and the subtree can be cut.
  ///
  /// The position key flips side-to-move so the table does not confuse a
  /// passed position with the real one. Nothing is pushed onto the
  /// repetition history: a passed position was never actually on the board,
  /// and counting it would invent repetitions that did not happen.
  void makeNullMove() {
    _zobrist ^= Zobrist.sideToMove;
    _sideToMove = _sideToMove.opposite;
    _nullMoveDepth++;
  }

  /// Reverses [makeNullMove].
  void undoNullMove() {
    _nullMoveDepth--;
    _zobrist ^= Zobrist.sideToMove;
    _sideToMove = _sideToMove.opposite;
  }

  /// How many null moves are on the stack. The searcher uses this to avoid
  /// two in a row, which would just be handing the opponent a free tempo
  /// and proves nothing.
  int get nullMoveDepth => _nullMoveDepth;
  int _nullMoveDepth = 0;

  /// Reverses the most recent move. Throws if history is empty.
  void undoMove() {
    if (_history.isEmpty) {
      throw StateError('undoMove: no move to undo');
    }
    final entry = _history.removeLast();
    _positionKeys.removeLast();
    _irreversiblePly = _irreversibleStack.removeLast();
    final move = entry.move;
    final placedPiece = _pieces[move.to.file][move.to.rank];

    _pieces[move.from.file][move.from.rank] = entry.movedPiece;
    _pieces[move.to.file][move.to.rank] = entry.captured;

    final moved = entry.movedPiece;
    if (moved.type == PieceType.king) {
      _kingSquares[moved.side.index] = move.from;
    } else if (move.promotion != null) {
      _nonPawnPieceCount[moved.side.index]--;
    }
    final captured = entry.captured;
    if (captured != null) {
      _pieceCount++;
      if (captured.type == PieceType.king) {
        _kingSquares[captured.side.index] = move.to;
      } else if (captured.type != PieceType.pawn) {
        _nonPawnPieceCount[captured.side.index]++;
      }
    }

    // Mirror of makeMove's Zobrist XORs (XOR is its own inverse).
    _zobrist ^= Zobrist.piece(
      entry.movedPiece.type,
      entry.movedPiece.side,
      move.from.file,
      move.from.rank,
    );
    if (entry.captured != null) {
      _zobrist ^= Zobrist.piece(
        entry.captured!.type,
        entry.captured!.side,
        move.to.file,
        move.to.rank,
      );
    }
    if (placedPiece != null) {
      _zobrist ^= Zobrist.piece(
        placedPiece.type,
        placedPiece.side,
        move.to.file,
        move.to.rank,
      );
    }
    _zobrist ^= Zobrist.sideToMove;

    final wasFlagFlipped = entry.movedPiece.side == Side.white
        ? (_whiteKingKnightMoveUsed != entry.prevKingKnightMoveUsed)
        : (_blackKingKnightMoveUsed != entry.prevKingKnightMoveUsed);
    if (wasFlagFlipped) {
      _zobrist ^= Zobrist.kingLeap(entry.movedPiece.side);
    }

    if (entry.movedPiece.side == Side.white) {
      _whiteKingKnightMoveUsed = entry.prevKingKnightMoveUsed;
    } else {
      _blackKingKnightMoveUsed = entry.prevKingKnightMoveUsed;
    }
    _sideToMove = _sideToMove.opposite;
  }

  static bool _isKnightOffset(Square from, Square to) {
    final df = (to.file - from.file).abs();
    final dr = (to.rank - from.rank).abs();
    return (df == 1 && dr == 2) || (df == 2 && dr == 1);
  }
}

class _HistoryEntry {
  _HistoryEntry({
    required this.move,
    required this.movedPiece,
    required this.captured,
    required this.prevKingKnightMoveUsed,
  });

  final Move move;
  final Piece movedPiece;
  final Piece? captured;
  final bool prevKingKnightMoveUsed;
}
