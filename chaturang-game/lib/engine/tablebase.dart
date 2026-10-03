import 'dart:typed_data';

import 'board.dart';
import 'pieces.dart';
import 'square.dart';

/// Per-position outcome stored in a tablebase, from the side-to-move's
/// perspective at that position.
class TbOutcome {
  TbOutcome._();

  /// Drawn or undetermined position.
  static const int draw = 0;

  /// The side to move at this position has a forced win.
  static const int sideToMoveWins = 1;

  /// The side to move at this position has a forced loss (best play).
  static const int sideToMoveLoses = 2;

  /// Position is not legal (e.g. pieces overlap, side-to-move has the
  /// enemy king in check, etc.).
  static const int invalid = 3;
}

/// Perfect-play tablebase for the King + Rook vs. King (KR-K) endgame.
///
/// Built by retrograde analysis: enumerate every reachable (wk, wr, bk,
/// side-to-move, white-leap-flag, black-leap-flag) tuple, mark terminal
/// positions, then iterate forward until convergence. Anything that
/// hasn't been labeled by convergence is a draw.
///
/// The KR-K tablebase covers ~2M positions and is ~2MB in memory at
/// 1 byte per entry. Color-symmetric: positions where Black has the
/// rook are probed via [Tablebase.probe], which detects the side with
/// material and color-flips on the fly.
///
/// Future slices will add more endgames (KP-K, 4-piece configurations,
/// etc.). Each is an additional Uint8List of similar size.
class Tablebase {
  Tablebase({required Uint8List krkData}) : _krk = krkData;

  /// Raw byte array, indexed by [_indexKrk]. One byte per position.
  final Uint8List _krk;

  /// Read-only access for tests and serialization.
  Uint8List get krkData => _krk;

  /// Probe the tablebase for [board]. Returns null when the position
  /// doesn't match a supported material configuration. Otherwise returns
  /// a [TbOutcome] constant from the side-to-move's perspective.
  ///
  /// Color-flips for KrK (black has the rook) automatically.
  int? probe(Board board) {
    // KR-K is exactly three pieces; the count is maintained by the board,
    // so nearly every node — this is asked at all of them — answers here
    // without the scan below.
    if (board.pieceCount != 3) return null;

    // Find the kings and detect which side has a non-king piece (and
    // what type). Returns null on anything that isn't KR-K (with either
    // color holding the rook).
    Square? whiteKing;
    Square? blackKing;
    Side? rookSide;
    Square? rookSquare;
    var otherPieceCount = 0;

    for (var f = 0; f < 8; f++) {
      for (var r = 0; r < 8; r++) {
        final p = board.pieceAt(Square(f, r));
        if (p == null) continue;
        if (p.type == PieceType.king) {
          if (p.side == Side.white) {
            if (whiteKing != null) return null; // two white kings??
            whiteKing = Square(f, r);
          } else {
            if (blackKing != null) return null;
            blackKing = Square(f, r);
          }
        } else if (p.type == PieceType.rook) {
          if (rookSquare != null) return null; // 2+ rooks
          rookSide = p.side;
          rookSquare = Square(f, r);
        } else {
          otherPieceCount++;
        }
      }
    }
    if (whiteKing == null ||
        blackKing == null ||
        rookSquare == null ||
        otherPieceCount > 0) {
      return null;
    }

    if (rookSide == Side.white) {
      return _probeKrk(
        wk: _sqToIdx(whiteKing),
        wr: _sqToIdx(rookSquare),
        bk: _sqToIdx(blackKing),
        stm: board.sideToMove == Side.white ? 0 : 1,
        wf: board.kingKnightMoveUsed(Side.white) ? 1 : 0,
        bf: board.kingKnightMoveUsed(Side.black) ? 1 : 0,
      );
    } else {
      // Black has the rook — flip colors so we can reuse the KR-K table.
      // After flipping:
      //   - swap the two kings' identities
      //   - the (originally black) rook is now treated as the white rook
      //   - side to move flips
      //   - leap flags flip
      return _probeKrk(
        wk: _sqToIdx(blackKing), // "white king" in the flipped world
        wr: _sqToIdx(rookSquare),
        bk: _sqToIdx(whiteKing),
        stm: board.sideToMove == Side.black ? 0 : 1,
        wf: board.kingKnightMoveUsed(Side.black) ? 1 : 0,
        bf: board.kingKnightMoveUsed(Side.white) ? 1 : 0,
      );
    }
  }

  int _probeKrk({
    required int wk,
    required int wr,
    required int bk,
    required int stm,
    required int wf,
    required int bf,
  }) {
    final idx = _indexKrk(wk, wr, bk, stm, wf, bf);
    return _krk[idx];
  }

  // ---------------------------------------------------------------------
  // Static helpers for index encoding and the generator.
  // ---------------------------------------------------------------------

  /// Number of bytes in a full KR-K tablebase.
  static const int krkSize = 64 * 64 * 64 * 2 * 2 * 2;

  /// Encode a (wk, wr, bk, stm, wf, bf) tuple to a flat index in
  /// [0, krkSize). wk/wr/bk are square indices (0..63), stm/wf/bf are
  /// 0 or 1.
  static int _indexKrk(int wk, int wr, int bk, int stm, int wf, int bf) {
    return ((((wk * 64 + wr) * 64 + bk) * 2 + stm) * 2 + wf) * 2 + bf;
  }

  /// Square → tablebase-index conversion. Internal to the format.
  static int _sqToIdx(Square s) => s.file * 8 + s.rank;
}

/// Builds the KR-K tablebase from scratch via retrograde analysis.
///
/// Slice 4e-2: specialized solver that works directly on integer
/// coordinates — no Board class, no MoveGenerator, no Zobrist
/// maintenance. All move generation and legality checks are inlined
/// using precomputed attack tables. Pass 1 builds a successor table
/// once; pass 2 (retrograde iterations) does pure integer lookups.
///
/// Target time: <30s on a modern laptop. Algorithm:
///
///   1. Pass 1 — for each of the 2M position indices:
///        - Skip overlapping pieces → INVALID
///        - Skip positions where side-that-just-moved is in check
///          (their previous move was illegal) → INVALID
///        - Generate legal moves inline; for each, append the
///          successor index to a flat data array (or -1 sentinel if
///          the move captures the rook, reducing the game to KvK).
///        - No moves + in check → LOSES (mate)
///        - No moves + not in check → DRAW (stalemate)
///
///   2. Pass 2 — iterate until convergence:
///        - For each UNKNOWN position, look up its successors in the
///          flat array.
///        - Any successor with LOSES (opponent loses) → mark WINS.
///        - All successors with WINS (opponent wins everywhere) →
///          mark LOSES. KvK successors don't count toward LOSES.
///        - Anything still UNKNOWN stays as DRAW (correct since the
///          side to move has no winning line and no losing line).
Uint8List computeKrkTablebase() => _KrkSolver().solve();

class _KrkSolver {
  /// Precomputed neighbors[64] — for each square, the list of (up to 8)
  /// king-adjacent squares.
  late final List<List<int>> _kingNeighbors;

  /// Precomputed leaps[64] — knight-shape destinations from each square.
  late final List<List<int>> _knightLeaps;

  /// Precomputed rookRays[64][4] — squares along each of the four
  /// orthogonal rays from each starting square.
  late final List<List<List<int>>> _rookRays;

  /// The output tablebase byte array.
  late final Uint8List _tb;

  /// Successor table built in pass 1: succOffsets[i] .. succOffsets[i+1]
  /// is the range of indices in succData that are successors of position i.
  /// Each successor is either a position index (0 .. krkSize-1) or -1
  /// (sentinel: this move captures the rook, transitioning to KvK = draw).
  late Int32List _succOffsets;
  late Int32List _succData;

  Uint8List solve() {
    _precomputeAttackTables();
    _classifyAndBuildSuccessors();
    _retrogradeIterate();
    return _tb;
  }

  void _precomputeAttackTables() {
    _kingNeighbors = List.generate(64, (sq) {
      final f = sq >> 3, r = sq & 7;
      final out = <int>[];
      for (var df = -1; df <= 1; df++) {
        for (var dr = -1; dr <= 1; dr++) {
          if (df == 0 && dr == 0) continue;
          final nf = f + df, nr = r + dr;
          if (nf < 0 || nf >= 8 || nr < 0 || nr >= 8) continue;
          out.add(nf * 8 + nr);
        }
      }
      return out;
    });

    _knightLeaps = List.generate(64, (sq) {
      final f = sq >> 3, r = sq & 7;
      final out = <int>[];
      for (final off in const [
        [1, 2],
        [1, -2],
        [-1, 2],
        [-1, -2],
        [2, 1],
        [2, -1],
        [-2, 1],
        [-2, -1],
      ]) {
        final nf = f + off[0], nr = r + off[1];
        if (nf < 0 || nf >= 8 || nr < 0 || nr >= 8) continue;
        out.add(nf * 8 + nr);
      }
      return out;
    });

    const dirs = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ];
    _rookRays = List.generate(64, (sq) {
      final f = sq >> 3, r = sq & 7;
      return List.generate(4, (di) {
        final df = dirs[di][0], dr = dirs[di][1];
        final out = <int>[];
        var nf = f + df, nr = r + dr;
        while (nf >= 0 && nf < 8 && nr >= 0 && nr < 8) {
          out.add(nf * 8 + nr);
          nf += df;
          nr += dr;
        }
        return out;
      });
    });
  }

  // Is `target` attacked by a king sitting on `kingSq`?
  bool _kingAttacks(int kingSq, int target) {
    if (kingSq == target) return false;
    final df = ((kingSq >> 3) - (target >> 3)).abs();
    final dr = ((kingSq & 7) - (target & 7)).abs();
    return df <= 1 && dr <= 1;
  }

  // Is `target` attacked by a rook on `rookSq`, with at most one possible
  // blocker on `blocker` (-1 if none)?
  bool _rookAttacks(int rookSq, int target, int blocker) {
    if (rookSq == target) return false;
    final rf = rookSq >> 3, rr = rookSq & 7;
    final tf = target >> 3, tr = target & 7;
    if (rf == tf) {
      if (blocker != -1) {
        final bf = blocker >> 3, br = blocker & 7;
        if (bf == rf) {
          final low = rr < tr ? rr : tr;
          final high = rr < tr ? tr : rr;
          if (br > low && br < high) return false;
        }
      }
      return true;
    }
    if (rr == tr) {
      if (blocker != -1) {
        final bf = blocker >> 3, br = blocker & 7;
        if (br == rr) {
          final low = rf < tf ? rf : tf;
          final high = rf < tf ? tf : rf;
          if (bf > low && bf < high) return false;
        }
      }
      return true;
    }
    return false;
  }

  int _encode(int wk, int wr, int bk, int stm, int wf, int bf) {
    return ((((wk * 64 + wr) * 64 + bk) * 2 + stm) * 2 + wf) * 2 + bf;
  }

  /// Generates legal-move successor indices for a KR-K position. Returns
  /// null if the position is INVALID (overlapping pieces or side that
  /// just moved was left in check). Each appended entry is either a
  /// successor position index or -1 (rook-captured / KvK draw sentinel).
  ///
  /// Note: this is the only place that knows about Chaturang KR-K move
  /// rules. The general engine's MoveGenerator does the same checks for
  /// arbitrary positions; here we inline them for the 2-3 known pieces.
  List<int>? _generateSuccessors(
    int wk,
    int wr,
    int bk,
    int stm,
    int wf,
    int bf,
  ) {
    if (wk == wr || wk == bk || wr == bk) return null;

    // Validity: side that just moved cannot be in check.
    if (stm == 0) {
      // White to move ⇒ black just moved ⇒ bk must not be in check.
      if (_kingAttacks(wk, bk)) return null;
      if (_rookAttacks(wr, bk, wk)) return null;
    } else {
      // Black to move ⇒ white just moved ⇒ wk must not be in check.
      // Only bk can attack wk (king adjacency); black has no other piece.
      if (_kingAttacks(bk, wk)) return null;
    }

    final out = <int>[];
    if (stm == 0) {
      _whiteMoves(wk, wr, bk, wf, bf, out);
    } else {
      _blackMoves(wk, wr, bk, wf, bf, out);
    }
    return out;
  }

  void _whiteMoves(int wk, int wr, int bk, int wf, int bf, List<int> out) {
    // White king — single-square steps.
    for (final newWk in _kingNeighbors[wk]) {
      if (newWk == wr) continue; // can't capture own rook
      if (newWk == bk) continue; // can't capture enemy king
      if (_kingAttacks(bk, newWk)) continue; // walking into check
      out.add(_encode(newWk, wr, bk, 1, wf, bf));
    }
    // White king — once-per-game knight leap.
    if (wf == 0) {
      for (final newWk in _knightLeaps[wk]) {
        if (newWk == wr) continue;
        if (newWk == bk) continue;
        if (_kingAttacks(bk, newWk)) continue;
        out.add(_encode(newWk, wr, bk, 1, 1, bf));
      }
    }
    // White rook — slide in 4 directions, stop at first occupant.
    for (var dir = 0; dir < 4; dir++) {
      final ray = _rookRays[wr][dir];
      for (var i = 0; i < ray.length; i++) {
        final newWr = ray[i];
        if (newWr == wk) break; // blocked by own king
        if (newWr == bk) break; // can't capture king (illegal in legal play)
        out.add(_encode(wk, newWr, bk, 1, wf, bf));
      }
    }
  }

  void _blackMoves(int wk, int wr, int bk, int wf, int bf, List<int> out) {
    // Black king — single-square steps.
    for (final newBk in _kingNeighbors[bk]) {
      if (newBk == wk) continue; // can't capture white king
      if (newBk == wr) {
        // Captures the rook → KvK. Move is legal only if newBk isn't
        // simultaneously defended by wk.
        if (_kingAttacks(wk, newBk)) continue;
        out.add(-1);
        continue;
      }
      if (_kingAttacks(wk, newBk)) continue; // walking into wk's attack
      // wr attacks newBk? Old bk is now empty; only wk could be a blocker.
      if (_rookAttacks(wr, newBk, wk)) continue;
      out.add(_encode(wk, wr, newBk, 0, wf, bf));
    }
    // Black king — once-per-game knight leap.
    if (bf == 0) {
      for (final newBk in _knightLeaps[bk]) {
        if (newBk == wk) continue;
        if (newBk == wr) {
          if (_kingAttacks(wk, newBk)) continue;
          out.add(-1);
          continue;
        }
        if (_kingAttacks(wk, newBk)) continue;
        if (_rookAttacks(wr, newBk, wk)) continue;
        out.add(_encode(wk, wr, newBk, 0, wf, 1));
      }
    }
  }

  void _classifyAndBuildSuccessors() {
    _tb = Uint8List(Tablebase.krkSize);
    final temp = <int>[];
    _succOffsets = Int32List(Tablebase.krkSize + 1);

    var offset = 0;
    for (var idx = 0; idx < Tablebase.krkSize; idx++) {
      _succOffsets[idx] = offset;
      // Decode (the encoding is: ((((wk*64+wr)*64+bk)*2+stm)*2+wf)*2+bf)
      final bf = idx & 1;
      final wf = (idx >> 1) & 1;
      final stm = (idx >> 2) & 1;
      final bk = (idx >> 3) & 63;
      final wr = (idx >> 9) & 63;
      final wk = idx >> 15;

      final succs = _generateSuccessors(wk, wr, bk, stm, wf, bf);
      if (succs == null) {
        _tb[idx] = TbOutcome.invalid;
        continue;
      }
      if (succs.isEmpty) {
        // No legal moves: mate if side-to-move is in check, else stalemate.
        bool inCheck;
        if (stm == 0) {
          // White to move. wk is in check iff attacked by bk (only piece).
          inCheck = _kingAttacks(bk, wk);
        } else {
          // Black to move. bk is in check iff attacked by wk or wr.
          inCheck = _kingAttacks(wk, bk) || _rookAttacks(wr, bk, wk);
        }
        _tb[idx] = inCheck ? TbOutcome.sideToMoveLoses : TbOutcome.draw;
        continue;
      }
      temp.addAll(succs);
      offset += succs.length;
    }
    _succOffsets[Tablebase.krkSize] = offset;
    _succData = Int32List.fromList(temp);
  }

  void _retrogradeIterate() {
    // Up to 64 passes; in practice KR-K converges in ~30.
    for (var pass = 0; pass < 64; pass++) {
      var changed = false;
      for (var idx = 0; idx < Tablebase.krkSize; idx++) {
        if (_tb[idx] != TbOutcome.draw) continue; // already settled
        final start = _succOffsets[idx];
        final end = _succOffsets[idx + 1];
        if (start == end) continue; // pass-1-terminal, already handled

        var anyWinForUs = false;
        var allLoseForUs = true;
        for (var i = start; i < end; i++) {
          final s = _succData[i];
          if (s == -1) {
            // KvK successor = draw → can't make us lose; doesn't make us win.
            allLoseForUs = false;
            continue;
          }
          final r = _tb[s];
          if (r == TbOutcome.sideToMoveLoses) {
            anyWinForUs = true;
            break;
          } else if (r != TbOutcome.sideToMoveWins) {
            // Draw or still-unknown: not a guaranteed loss for us.
            allLoseForUs = false;
          }
        }
        if (anyWinForUs) {
          _tb[idx] = TbOutcome.sideToMoveWins;
          changed = true;
        } else if (allLoseForUs) {
          _tb[idx] = TbOutcome.sideToMoveLoses;
          changed = true;
        }
      }
      if (!changed) break;
    }
  }
}
