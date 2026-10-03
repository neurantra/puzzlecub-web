/// Piece colors and types for Chaturang.
///
/// "Side" is used instead of "Color" to avoid collision with Flutter's
/// `dart:ui` Color class when the engine is later consumed by the UI.
enum Side {
  white,
  black;

  Side get opposite => this == white ? black : white;
}

enum PieceType {
  king('K', 'Raja', 'King'),
  counsellor('C', 'Mantri', 'Counsellor'),
  elephant('E', 'Gaja', 'Elephant'),
  knight('N', 'Ashva', 'Knight'),
  rook('R', 'Ratha', 'Chariot'),
  pawn('P', 'Padati', 'Soldier');

  const PieceType(this.letter, this.sanskritName, this.englishName);

  final String letter;

  /// The piece's Sanskrit name, as used throughout the rules screen.
  final String sanskritName;

  /// The nearest modern-chess equivalent. Held separately from
  /// [sanskritName] so a caller can show either alone; [label] is the
  /// combined form used wherever a player needs both.
  final String englishName;

  /// e.g. "Ashva (Knight)". The single source for piece naming — the rules
  /// screen and the board's long-press label both read it, so they cannot
  /// drift apart.
  String get label => '$sanskritName ($englishName)';
}

class Piece {
  const Piece(this.type, this.side);

  final PieceType type;
  final Side side;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Piece && other.type == type && other.side == side);

  @override
  int get hashCode => Object.hash(type, side);

  @override
  String toString() =>
      side == Side.white ? type.letter : type.letter.toLowerCase();
}
