/// Optional cap on total full moves before a game auto-draws.
///
/// Chess and Chaturang have no hard move-count rule (chess uses the
/// 50-move and 75-move *no-progress* rules; Chaturang has neither),
/// but a "X full moves and we call it" mode is a recognizable casual
/// game format. When the limit is reached without a checkmate, the
/// game ends as a [MoveLimitDraw] regardless of position.
///
/// Counted as *full moves*, not plies: 50 full moves = 50 white + 50
/// black = 100 plies total.
enum MoveLimit {
  unlimited(0),
  short(30),
  standard(50),
  long(100);

  const MoveLimit(this.fullMoves);

  /// Cap in full moves (0 = no cap).
  final int fullMoves;

  /// Cap converted to plies (each full move = 2 plies). 0 when unlimited.
  int get maxPlies => fullMoves * 2;

  /// Display label for the Settings segmented row.
  String get label => switch (this) {
    MoveLimit.unlimited => 'Off',
    MoveLimit.short => '30',
    MoveLimit.standard => '50',
    MoveLimit.long => '100',
  };
}
