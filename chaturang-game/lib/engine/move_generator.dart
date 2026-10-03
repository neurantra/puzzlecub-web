import 'board.dart';
import 'move.dart';
import 'pieces.dart';
import 'square.dart';

/// Generates legal moves for Chaturang positions and answers attack queries.
///
/// "Legal" = pseudo-legal moves filtered to those that don't leave the moving
/// side's king in check (modern check semantics).
///
/// The king's once-per-game knight-leap is treated as just another candidate
/// king move: it can be used to escape check, and the [Board.makeMove] applies
/// the per-side flag automatically based on geometry.
///
/// Attack queries treat the king's passive attack zone as the 8 adjacent
/// squares only — the knight-leap is an active move, not a passive threat.
class MoveGenerator {
  MoveGenerator._();

  /// Every legal move available to [Board.sideToMove].
  static List<Move> legalMoves(Board board) =>
      _legalMovesWhere(board, capturesOnly: false);

  /// Every legal capture available to [Board.sideToMove] — the same moves
  /// [legalMoves] would return with a piece on the destination, in the same
  /// order, without generating the quiet moves that quiescence would only
  /// throw away.
  static List<Move> legalCaptures(Board board) =>
      _legalMovesWhere(board, capturesOnly: true);

  static List<Move> _legalMovesWhere(
    Board board, {
    required bool capturesOnly,
  }) {
    final moves = <Move>[];
    final side = board.sideToMove;
    final inCheck = isInCheck(board, side);
    for (var f = 0; f < 8; f++) {
      for (var r = 0; r < 8; r++) {
        final piece = board.pieceAtCoords(f, r);
        if (piece == null || piece.side != side) continue;
        _addLegalMovesFor(
          board,
          Square(f, r),
          piece,
          inCheck,
          capturesOnly,
          moves,
        );
      }
    }
    return moves;
  }

  /// Legal moves for the piece on [from], or empty if [from] is empty or holds
  /// an opponent's piece.
  static List<Move> legalMovesFrom(Board board, Square from) {
    final piece = board.pieceAt(from);
    if (piece == null || piece.side != board.sideToMove) return const [];
    final moves = <Move>[];
    _addLegalMovesFor(
      board,
      from,
      piece,
      isInCheck(board, piece.side),
      false,
      moves,
    );
    return moves;
  }

  /// True if any piece of [bySide] currently attacks [square].
  ///
  /// Looks outward from [square] rather than scanning the board: a piece
  /// can only attack it from the squares its own move pattern reaches, and
  /// every Chaturang pattern is short-range except the ratha's, whose four
  /// rays stop at the first piece. That is at most ~30 lookups against 64
  /// geometry tests, and this is the most-called routine in the engine.
  static bool isSquareAttacked(Board board, Square square, Side bySide) {
    final f = square.file;
    final r = square.rank;
    for (final (df, dr) in _kingSteps) {
      if (_pieceIs(board, f + df, r + dr, bySide, PieceType.king)) return true;
    }
    for (final (df, dr) in _knightSteps) {
      if (_pieceIs(board, f + df, r + dr, bySide, PieceType.knight)) {
        return true;
      }
    }
    for (final (df, dr) in _diagonalSteps) {
      if (_pieceIs(board, f + df, r + dr, bySide, PieceType.counsellor)) {
        return true;
      }
    }
    for (final (df, dr) in _elephantSteps) {
      if (_pieceIs(board, f + df, r + dr, bySide, PieceType.elephant)) {
        return true;
      }
    }
    // A padati attacks diagonally forward, so the attacker sits diagonally
    // *behind* the target from its own point of view.
    final pawnRank = bySide == Side.white ? r + 1 : r - 1;
    if (_pieceIs(board, f - 1, pawnRank, bySide, PieceType.pawn) ||
        _pieceIs(board, f + 1, pawnRank, bySide, PieceType.pawn)) {
      return true;
    }
    for (final (df, dr) in _orthogonalSteps) {
      var tf = f + df;
      var tr = r + dr;
      while (tf >= 0 && tf < 8 && tr >= 0 && tr < 8) {
        final p = board.pieceAt(Square(tf, tr));
        if (p != null) {
          if (p.side == bySide && p.type == PieceType.rook) return true;
          break;
        }
        tf += df;
        tr += dr;
      }
    }
    return false;
  }

  /// True if the square at ([f], [r]) is on the board and holds a piece of
  /// [side] and [type].
  static bool _pieceIs(Board board, int f, int r, Side side, PieceType type) {
    if (f < 0 || f >= 8 || r < 0 || r >= 8) return false;
    final p = board.pieceAt(Square(f, r));
    return p != null && p.side == side && p.type == type;
  }

  /// True if [side]'s king is currently attacked. Returns false if the king
  /// is missing (should not happen in legal play).
  static bool isInCheck(Board board, Side side) {
    final kingSq = board.kingSquare(side);
    if (kingSq == null) return false;
    return isSquareAttacked(board, kingSq, side.opposite);
  }

  // -------------------------- legality filter --------------------------

  /// Appends the legal moves of [piece] on [from] to [out].
  ///
  /// A pseudo-legal move can only leave its own king in check in three
  /// ways: the king was already in check and the move fails to answer it;
  /// the king itself steps onto an attacked square; or the move uncovers a
  /// line to the king. Only the ratha slides, so the last needs the moving
  /// piece to stand on the king's rank or file with nothing between — and
  /// everything else is legal as generated. Those three cases get the
  /// make/undo/check test; the rest skip it, which is most moves at most
  /// nodes.
  static void _addLegalMovesFor(
    Board board,
    Square from,
    Piece piece,
    bool inCheck,
    bool capturesOnly,
    List<Move> out,
  ) {
    // Pseudo-legal moves go straight onto [out]; the ones that fail the
    // filter are then compacted away in place, which keeps the order and
    // avoids a list per piece per node.
    final start = out.length;
    _addPseudoLegalMoves(board, from, piece, out);
    final kingSq = board.kingSquare(piece.side);
    final mustVerify =
        inCheck ||
        piece.type == PieceType.king ||
        kingSq == null ||
        _onOpenLineWith(board, from, kingSq);
    if (!mustVerify && !capturesOnly) return;

    var kept = start;
    for (var i = start; i < out.length; i++) {
      final move = out[i];
      if (capturesOnly && board.pieceAt(move.to) == null) continue;
      if (mustVerify) {
        board.makeMove(move);
        final selfInCheck = isInCheck(board, piece.side);
        board.undoMove();
        if (selfInCheck) continue;
      }
      out[kept++] = move;
    }
    out.length = kept;
  }

  /// True if [a] and [b] share a rank or file with only empty squares
  /// between them — the geometry in which moving [a] could expose [b] to a
  /// ratha.
  static bool _onOpenLineWith(Board board, Square a, Square b) {
    if (a.file != b.file && a.rank != b.rank) return false;
    return _pathClear(board, a, b);
  }

  // -------------------------- pseudo-legal --------------------------

  static void _addPseudoLegalMoves(
    Board board,
    Square from,
    Piece piece,
    List<Move> out,
  ) {
    switch (piece.type) {
      case PieceType.king:
        _stepMoves(board, from, piece, _kingSteps, out);
        if (!board.kingKnightMoveUsed(piece.side)) {
          _stepMoves(board, from, piece, _knightSteps, out);
        }
      case PieceType.counsellor:
        _stepMoves(board, from, piece, _diagonalSteps, out);
      case PieceType.elephant:
        _stepMoves(board, from, piece, _elephantSteps, out);
      case PieceType.knight:
        _stepMoves(board, from, piece, _knightSteps, out);
      case PieceType.rook:
        _slideMoves(board, from, piece, _orthogonalSteps, out);
      case PieceType.pawn:
        _pawnMoves(board, from, piece, out);
    }
  }

  static void _stepMoves(
    Board board,
    Square from,
    Piece piece,
    List<(int, int)> steps,
    List<Move> out,
  ) {
    for (final (df, dr) in steps) {
      final f = from.file + df;
      final r = from.rank + dr;
      if (f < 0 || f >= 8 || r < 0 || r >= 8) continue;
      final occupant = board.pieceAtCoords(f, r);
      if (occupant == null || occupant.side != piece.side) {
        out.add(Move(from: from, to: Square(f, r)));
      }
    }
  }

  static void _slideMoves(
    Board board,
    Square from,
    Piece piece,
    List<(int, int)> directions,
    List<Move> out,
  ) {
    for (final (df, dr) in directions) {
      var f = from.file + df;
      var r = from.rank + dr;
      while (f >= 0 && f < 8 && r >= 0 && r < 8) {
        final occupant = board.pieceAtCoords(f, r);
        if (occupant == null) {
          out.add(Move(from: from, to: Square(f, r)));
        } else {
          if (occupant.side != piece.side) {
            out.add(Move(from: from, to: Square(f, r)));
          }
          break;
        }
        f += df;
        r += dr;
      }
    }
  }

  static void _pawnMoves(
    Board board,
    Square from,
    Piece piece,
    List<Move> out,
  ) {
    // White advances toward rank 0 (decreasing); Black toward rank 7.
    final dr = piece.side == Side.white ? -1 : 1;
    final promoRank = piece.side == Side.white ? 0 : 7;

    final pushRank = from.rank + dr;
    if (pushRank >= 0 && pushRank < 8) {
      if (board.pieceAtCoords(from.file, pushRank) == null) {
        _appendPawnMove(
          out,
          from,
          Square(from.file, pushRank),
          piece.side,
          promoRank,
        );
      }
    }

    for (final df in const [-1, 1]) {
      final cf = from.file + df;
      final cr = from.rank + dr;
      if (cf < 0 || cf >= 8 || cr < 0 || cr >= 8) continue;
      final occupant = board.pieceAtCoords(cf, cr);
      if (occupant != null && occupant.side != piece.side) {
        _appendPawnMove(out, from, Square(cf, cr), piece.side, promoRank);
      }
    }
  }

  static void _appendPawnMove(
    List<Move> moves,
    Square from,
    Square to,
    Side side,
    int promoRank,
  ) {
    if (to.rank != promoRank) {
      moves.add(Move(from: from, to: to));
      return;
    }
    final promo = _promotionPieceFor(to.file, side);
    if (promo == null) {
      return; // enemy king's home square — illegal pawn destination
    }
    moves.add(Move(from: from, to: to, promotion: promo));
  }

  /// Promotion piece for a padati of [side] arriving on the given file, or
  /// null if promotion is forbidden (the file maps to king — i.e. e1 for
  /// white, d8 for black).
  ///
  /// A Chaturang padati becomes whatever piece belongs on that file's back
  /// rank, so what it is worth on promotion depends entirely on the file it
  /// stands on: a rook-file padati is a future ratha, a d-file one a future
  /// mantri, and on one file per side it can never promote at all.
  static PieceType? _promotionPieceFor(int file, Side side) {
    final type = side == Side.white ? blackBackRank[file] : whiteBackRank[file];
    return type == PieceType.king ? null : type;
  }

  // -------------------------- attack queries --------------------------

  /// Does [piece] at [from] attack [target] on the current board?
  /// Note pawns attack diagonally only — the push square is NOT an attack.
  /// The king's passive attack zone is the 8 adjacent squares only; the
  /// knight-leap is an active move, not a threat.
  /// The cheapest piece of [bySide] still attacking [target], ignoring any
  /// piece standing on a square in [vacated].
  ///
  /// [vacated] is how static exchange evaluation walks a capture sequence:
  /// each attacker that has already taken its turn is treated as gone, which
  /// both stops it being counted twice and opens the x-ray behind it. Only
  /// the ratha slides in Chaturang, so an x-ray is always a ratha along a
  /// rank or file — but that case is common enough to matter.
  ///
  /// Returns the attacker's square, or null when the exchange is over.
  static Square? leastValuableAttacker(
    Board board,
    Square target,
    Side bySide,
    Set<Square> vacated,
    int Function(PieceType) valueOf,
  ) {
    Square? best;
    var bestValue = 1 << 30;
    // Ties go to the lowest file, then rank — the order a board scan would
    // find them in — so that which of two equal attackers is taken first,
    // and so which x-rays open behind it, does not depend on this routine's
    // internals.
    void offer(int f, int r, PieceType type) {
      if (f < 0 || f >= 8 || r < 0 || r >= 8) return;
      final sq = Square(f, r);
      if (vacated.contains(sq)) return;
      final p = board.pieceAt(sq);
      if (p == null || p.side != bySide || p.type != type) return;
      final v = valueOf(type);
      final current = best;
      if (v < bestValue ||
          (current != null &&
              v == bestValue &&
              (f < current.file || (f == current.file && r < current.rank)))) {
        bestValue = v;
        best = sq;
      }
    }

    final f = target.file;
    final r = target.rank;
    for (final (df, dr) in _kingSteps) {
      offer(f + df, r + dr, PieceType.king);
    }
    for (final (df, dr) in _knightSteps) {
      offer(f + df, r + dr, PieceType.knight);
    }
    for (final (df, dr) in _diagonalSteps) {
      offer(f + df, r + dr, PieceType.counsellor);
    }
    for (final (df, dr) in _elephantSteps) {
      offer(f + df, r + dr, PieceType.elephant);
    }
    final pawnRank = bySide == Side.white ? r + 1 : r - 1;
    offer(f - 1, pawnRank, PieceType.pawn);
    offer(f + 1, pawnRank, PieceType.pawn);
    for (final (df, dr) in _orthogonalSteps) {
      var tf = f + df;
      var tr = r + dr;
      while (tf >= 0 && tf < 8 && tr >= 0 && tr < 8) {
        final sq = Square(tf, tr);
        // Vacated squares are transparent: that is the x-ray.
        if (!vacated.contains(sq) && board.pieceAt(sq) != null) {
          offer(tf, tr, PieceType.rook);
          break;
        }
        tf += df;
        tr += dr;
      }
    }
    return best;
  }

  static bool _pathClear(Board board, Square from, Square to) {
    final df = (to.file - from.file).sign;
    final dr = (to.rank - from.rank).sign;
    var f = from.file + df;
    var r = from.rank + dr;
    while (f != to.file || r != to.rank) {
      if (board.pieceAt(Square(f, r)) != null) return false;
      f += df;
      r += dr;
    }
    return true;
  }

  // -------------------------- step tables --------------------------

  static const List<(int, int)> _kingSteps = [
    (-1, -1),
    (-1, 0),
    (-1, 1),
    (0, -1),
    (0, 1),
    (1, -1),
    (1, 0),
    (1, 1),
  ];

  static const List<(int, int)> _knightSteps = [
    (1, 2),
    (1, -2),
    (-1, 2),
    (-1, -2),
    (2, 1),
    (2, -1),
    (-2, 1),
    (-2, -1),
  ];

  static const List<(int, int)> _diagonalSteps = [
    (1, 1),
    (1, -1),
    (-1, 1),
    (-1, -1),
  ];

  static const List<(int, int)> _elephantSteps = [
    (2, 2),
    (2, -2),
    (-2, 2),
    (-2, -2),
  ];

  static const List<(int, int)> _orthogonalSteps = [
    (1, 0),
    (-1, 0),
    (0, 1),
    (0, -1),
  ];
}
