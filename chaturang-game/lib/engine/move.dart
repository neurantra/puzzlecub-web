import 'pieces.dart';
import 'square.dart';

/// A move from one square to another, with an optional promotion.
///
/// Moves carry intent only; the board records capture and flag state in its
/// own history for undo purposes. The board is responsible for detecting
/// whether a king move follows the once-per-game knight pattern.
class Move {
  const Move({required this.from, required this.to, this.promotion});

  final Square from;
  final Square to;
  final PieceType? promotion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Move &&
          other.from == from &&
          other.to == to &&
          other.promotion == promotion);

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() =>
      '$from-$to${promotion != null ? '=${promotion!.letter}' : ''}';
}
