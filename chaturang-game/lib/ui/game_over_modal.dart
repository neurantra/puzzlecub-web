import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/cross_promo.dart';
import '../data/vault_availability.dart';
import '../engine/game_state.dart';
import '../engine/pieces.dart';
import 'theme.dart';

/// Visual tone of a game outcome, from the human player's perspective.
enum _Tone { win, loss, draw }

/// Shows the end-of-game modal: an outcome headline phrased from the
/// human player's point of view, the move count, and elapsed wall time.
///
/// Returns true if the player chose "Rematch", false if they dismissed
/// the modal to look at the final board.
Future<bool> showGameOverModal(
  BuildContext context, {
  required GameResult result,
  required Side humanSide,
  required int fullMoves,
  required Duration elapsed,
  String opponentLabel = 'the AI',
  bool allowRematch = true,
  bool opponentIsHuman = false,
  VoidCallback? onViewMoves,
}) async {
  final rematch = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.66),
    builder: (context) => _GameOverDialog(
      result: result,
      humanSide: humanSide,
      fullMoves: fullMoves,
      elapsed: elapsed,
      opponentLabel: opponentLabel,
      allowRematch: allowRematch,
      opponentIsHuman: opponentIsHuman,
      onViewMoves: onViewMoves,
    ),
  );
  return rematch ?? false;
}

/// Capitalizes the first character of [s], leaving the rest as-is.
/// Used so an opponent label like "your opponent" reads "Your opponent"
/// when it starts a sentence ("Your opponent ran out of time.") without
/// distorting capitalized labels like "the AI".
String _startOfSentence(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Formats a play duration as hh:mm:ss.
String _formatElapsed(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = (total ~/ 3600).toString().padLeft(2, '0');
  final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

class _Outcome {
  const _Outcome(this.headline, this.detail, this.tone);
  final String headline;
  final String detail;
  final _Tone tone;
}

/// Maps a [GameResult] to display copy written from the human player's
/// point of view (so "you" wins/loses, never an abstract side name).
_Outcome _outcomeFor(
  GameResult result,
  Side humanSide,
  int fullMoves,
  String opp,
  bool opponentIsHuman,
) {
  final movePhrase = fullMoves == 1 ? '1 move' : '$fullMoves moves';
  final oppCap = _startOfSentence(opp);
  // When the opponent is a real human (online play), wins via opponent
  // forfeit OR opponent disconnect get the muted, draw-style visual
  // tone (handshake icon, parchment color) and 'Game ended' headline
  // — 'Victory' + trophy reads as gloating when the player didn't
  // actually out-play their opponent; they just stayed connected /
  // didn't quit. Checkmate keeps the celebratory framing in both
  // modes because that one IS earned.
  //
  // Online v1 also isn't timed, so a Timeout result there always
  // means 'opponent went silent past the disconnect grace window' —
  // the copy reflects that ('went offline' instead of 'ran out of
  // time').
  final timeoutWinHeadline = opponentIsHuman ? 'Game ended' : 'Victory';
  final timeoutWinDetail = opponentIsHuman
      ? 'Your opponent went offline. You won by default.'
      : '$oppCap ran out of time.';
  final timeoutLoseHeadline = opponentIsHuman
      ? 'Connection lost'
      : 'Out of Time';
  final timeoutLoseDetail = opponentIsHuman
      ? 'You lost the connection to the room.'
      : 'Your clock ran out.';
  final forfeitWinHeadline = opponentIsHuman ? 'Game ended' : 'Victory';
  final forfeitWinDetail = opponentIsHuman
      ? '$oppCap forfeited the game. You won by default.'
      : '$oppCap forfeited the game.';
  final softWinTone = opponentIsHuman ? _Tone.draw : _Tone.win;
  return switch (result) {
    Checkmate(:final winner) =>
      winner == humanSide
          ? _Outcome(
              'Victory',
              'You checkmated $opp in $movePhrase.',
              _Tone.win,
            )
          : _Outcome(
              'Checkmate',
              'You were checkmated in $movePhrase.',
              _Tone.loss,
            ),
    Timeout(:final winner) =>
      winner == humanSide
          ? _Outcome(timeoutWinHeadline, timeoutWinDetail, softWinTone)
          : _Outcome(timeoutLoseHeadline, timeoutLoseDetail, _Tone.loss),
    Forfeit(:final winner) =>
      winner == humanSide
          ? _Outcome(forfeitWinHeadline, forfeitWinDetail, softWinTone)
          : _Outcome('Forfeited', 'You forfeited the game.', _Tone.loss),
    Stalemate() => const _Outcome(
      'Stalemate',
      'No legal moves — the game is a draw.',
      _Tone.draw,
    ),
    DrawByAgreement() => const _Outcome(
      'Draw',
      'The game ended in a draw by agreement.',
      _Tone.draw,
    ),
    MoveLimitDraw() => const _Outcome(
      'Draw',
      'The move limit was reached — a draw.',
      _Tone.draw,
    ),
    RepetitionDraw() => const _Outcome(
      'Draw',
      'The same position came up three times — a draw.',
      _Tone.draw,
    ),
    InsufficientMaterial() => const _Outcome(
      'Draw',
      'Neither side has enough material to mate — a draw.',
      _Tone.draw,
    ),
    Ongoing() => const _Outcome('', '', _Tone.draw), // not reachable
  };
}

class _GameOverDialog extends StatelessWidget {
  const _GameOverDialog({
    required this.result,
    required this.humanSide,
    required this.fullMoves,
    required this.elapsed,
    required this.opponentLabel,
    required this.allowRematch,
    required this.opponentIsHuman,
    required this.onViewMoves,
  });

  final GameResult result;
  final Side humanSide;
  final int fullMoves;
  final Duration elapsed;
  final String opponentLabel;
  final bool allowRematch;
  final bool opponentIsHuman;

  /// Optional 'View moves' callback. When non-null, the dialog renders
  /// a third button (above the View board / Rematch row) that calls it.
  /// BoardScreen wires this to a sheet showing the move history.
  final VoidCallback? onViewMoves;

  @override
  Widget build(BuildContext context) {
    final outcome = _outcomeFor(
      result,
      humanSide,
      fullMoves,
      opponentLabel,
      opponentIsHuman,
    );
    final (Color accent, IconData icon) = switch (outcome.tone) {
      _Tone.win => (ChaturangTheme.saffronLight, Icons.emoji_events),
      _Tone.loss => (ChaturangTheme.terracotta, Icons.flag_outlined),
      _Tone.draw => (ChaturangTheme.parchment, Icons.handshake_outlined),
    };

    return Dialog(
      backgroundColor: ChaturangTheme.deepMaroon,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 46),
            const SizedBox(height: 10),
            Text(
              outcome.headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'RoyalSans',
                color: accent,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              outcome.detail,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ChaturangTheme.secondaryText,
                fontSize: 14,
                fontFamily: 'RoyalSans',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              color: ChaturangTheme.saffron.withValues(alpha: 0.4),
              height: 1,
            ),
            const SizedBox(height: 14),
            _StatLine(icon: Icons.tag, label: 'Moves', value: '$fullMoves'),
            const SizedBox(height: 8),
            _StatLine(
              icon: Icons.schedule,
              label: 'Time elapsed',
              value: _formatElapsed(elapsed),
            ),
            const SizedBox(height: 20),
            if (onViewMoves != null && fullMoves > 0) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onViewMoves,
                  icon: Icon(
                    Icons.list_alt_outlined,
                    color: ChaturangTheme.saffronLight,
                    size: 18,
                  ),
                  label: Text(
                    'View moves',
                    style: TextStyle(
                      fontFamily: 'RoyalSans',
                      color: ChaturangTheme.parchment,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: ChaturangTheme.saffronLight.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: ChaturangTheme.parchment,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      allowRematch ? 'View board' : 'Done',
                      style: TextStyle(
                        fontFamily: 'RoyalSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (allowRematch) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: ChaturangTheme.charcoal,
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Rematch',
                        style: TextStyle(
                          fontFamily: 'RoyalSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const _PuzzleCubFootnote(),
          ],
        ),
      ),
    );
  }
}

/// One quiet line about the sibling game, under the buttons.
///
/// The Store was the only place PuzzleCub was mentioned, so a player who
/// never opened it never learned the other game existed. This is the one
/// other moment where coins are already on the player's mind — they have
/// just been awarded some — which makes "they also work over there" a
/// remark rather than an ask.
///
/// Deliberately a footnote and not a card: it sits below the actions, in
/// muted text, at the end of a modal whose job is the result of the game.
/// Anything more prominent here competes with Rematch, which is what the
/// player actually came for.
class _PuzzleCubFootnote extends StatelessWidget {
  const _PuzzleCubFootnote();

  @override
  Widget build(BuildContext context) {
    if (!VaultAvailability.instance.isLive) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextButton(
        onPressed: () async {
          final uri = Uri.parse(CrossPromo.storeUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Your coins also work in ${CrossPromo.appName}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ChaturangTheme.secondaryText,
            fontSize: 12,
            decoration: TextDecoration.underline,
            decorationColor: ChaturangTheme.secondaryText,
          ),
        ),
      ),
    );
  }
}

/// A single labelled stat row inside the modal (icon · label · value).
class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ChaturangTheme.saffronLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: ChaturangTheme.secondaryText,
              fontSize: 14,
              fontFamily: 'RoyalSans',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: ChaturangTheme.parchment,
            fontSize: 16,
            fontFamily: 'RoyalSans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
