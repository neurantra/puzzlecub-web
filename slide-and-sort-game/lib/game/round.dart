import '../web_bridge.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'puzzle_board.dart';
import 'solver.dart';

@immutable
class PlayOptions {
  const PlayOptions({
    this.kind = PuzzleKind.alphabets,
    this.againstAI = false,
    this.timed = false,
    this.limited = false,
  });
  final PuzzleKind kind;
  final bool againstAI, timed, limited;
  static const seconds = 300;
  static const moves = 150;
}

enum RoundOutcome { playing, solved, friendFinished, timeUp, movesUp }

/// One clock for the player and a real solver-driven opponent, on identical boards.
/// UI lifecycle pauses this clock; no background time or AI moves are consumed.
class AlphabetRound extends ChangeNotifier {
  AlphabetRound(this.options, {Random? random, PuzzleBoard? initial}) {
    board =
        initial ??
        PuzzleBoard.solved(
          kind: options.kind,
        ).shuffled(moves: 32, random: random);
    if (board.isSolved && initial == null) {
      board = board.move(board.symbolCount - 1);
    }
    friendBoard = board;
    _friendMoves = options.againstAI ? AlphaSolver(board).solve() : [];
  }
  final PlayOptions options;
  late PuzzleBoard board, friendBoard;
  late List<int> _friendMoves;
  int moves = 0, seconds = 0, friendMoves = 0;
  bool paused = false;
  RoundOutcome outcome = RoundOutcome.playing;
  bool get active => outcome == RoundOutcome.playing;
  int get remainingSeconds => max(0, PlayOptions.seconds - seconds);
  int get remainingMoves => max(0, PlayOptions.moves - moves);
  bool get friendAtLimit => options.limited && friendMoves >= PlayOptions.moves;

  bool slide(int index) {
    if (!active || paused || !board.canMove(index)) return false;
    board = board.move(index);
    moves++;
    if (board.isSolved) {
      outcome = RoundOutcome.solved;
    } else if (options.limited && moves >= PlayOptions.moves) {
      outcome = RoundOutcome.movesUp;
    }
    reportGameAction(board.isSolved);
    notifyListeners();
    return true;
  }

  void tick() {
    if (!active || paused) return;
    seconds++;
    // Time expires for both players before a move at the deadline.
    if (options.timed && seconds >= PlayOptions.seconds) {
      outcome = RoundOutcome.timeUp;
    } else if (options.againstAI &&
        !friendAtLimit &&
        friendMoves < _friendMoves.length) {
      friendBoard = friendBoard.move(_friendMoves[friendMoves++]);
      if (friendBoard.isSolved) outcome = RoundOutcome.friendFinished;
    }
    notifyListeners();
  }

  void pause(bool value) {
    paused = value;
    notifyListeners();
  }
}
