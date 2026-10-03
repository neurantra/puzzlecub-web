import 'move.dart';

/// What kind of bound a stored score represents.
///
/// - [exact] : the search at this node fully explored its move list — the
///             stored score is the true minimax value at the stored depth.
/// - [lowerBound] : the search produced a beta cutoff. The real score is at
///                  least this value; could be higher.
/// - [upperBound] : every move failed low (no move beat alpha). The real
///                  score is at most this value; could be lower.
enum ScoreType { exact, lowerBound, upperBound }

/// One slot in the transposition table.
class TtEntry {
  const TtEntry({
    required this.key,
    required this.depth,
    required this.score,
    required this.scoreType,
    required this.bestMove,
  });

  /// Full 64-bit Zobrist key for collision validation — the table is indexed
  /// by `key & mask`, but multiple positions can hash to the same slot, so
  /// we verify on probe.
  final BigInt key;

  /// Remaining ply depth searched below this position when the entry was
  /// stored. Probes at a depth greater than this can't trust the cached
  /// score (must research deeper).
  final int depth;

  /// Score from the side-to-move's perspective at this node.
  final int score;

  final ScoreType scoreType;

  /// The best move found here. Useful for move-ordering even when the
  /// stored score itself isn't usable (depth too shallow).
  final Move? bestMove;
}

/// Hash table mapping Zobrist position keys to search results.
///
/// Always-replace scheme: every store overwrites the existing slot. Simple
/// and effective; smarter replacement policies (depth-preferred, two-tier
/// "always + deep") can come later if we measure a benefit.
///
/// Sized as a power of two so we can mask the key instead of mod-ing it
/// (faster). Default 2^18 = 262,144 entries ≈ 12MB at ~50 bytes per entry.
class TranspositionTable {
  TranspositionTable({int sizeBits = 18})
    : _mask = (1 << sizeBits) - 1,
      _entries = List<TtEntry?>.filled(1 << sizeBits, null);

  final int _mask;
  final List<TtEntry?> _entries;

  int get size => _entries.length;

  /// Returns the entry stored for [key], or null on miss / hash collision.
  TtEntry? probe(BigInt key) {
    final entry = _entries[(key & BigInt.from(_mask)).toInt()];
    if (entry == null || entry.key != key) return null;
    return entry;
  }

  /// Stores an entry. Always replaces whatever was in the slot.
  void store({
    required BigInt key,
    required int depth,
    required int score,
    required ScoreType scoreType,
    required Move? bestMove,
  }) {
    _entries[(key & BigInt.from(_mask)).toInt()] = TtEntry(
      key: key,
      depth: depth,
      score: score,
      scoreType: scoreType,
      bestMove: bestMove,
    );
  }

  /// Wipes the table — used between searches if state pollution is a
  /// concern. (Our Searcher allocates a fresh TT per call, so this is only
  /// useful for tests right now.)
  void clear() {
    for (var i = 0; i < _entries.length; i++) {
      _entries[i] = null;
    }
  }
}
