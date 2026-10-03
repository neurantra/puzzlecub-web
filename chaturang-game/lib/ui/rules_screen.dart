import 'package:flutter/material.dart';

import '../engine/pieces.dart';
import 'board_widget.dart';
import 'theme.dart';
import 'army_screen.dart';

/// "How to play" — concise Chaturang rules, organized by setup → piece
/// movement → special rules → win conditions. Reachable via the Rules
/// action button on the board screen.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaturangTheme.deepMaroon,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ChaturangTheme.parchment),
        title: Text(
          'How to Play',
          style: TextStyle(
            fontFamily: 'RoyalSans',
            color: ChaturangTheme.parchment,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const ArmyScreen()),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Meet the army'),
              ),
              const SizedBox(height: 16),
              _Paragraph(
                "Chaturang is an 8th-century Indian game widely considered "
                "the earliest known form of chess. Its rules differ from "
                "modern chess in several important ways — pieces are weaker, "
                "there is no castling, and the King has a once-per-game "
                "special leap.",
              ),
              const SizedBox(height: 20),
              _SectionHeading('Setup'),
              _Paragraph(
                "Played on an uncheckered 8×8 board (the Ashtāpada). The two "
                "Kings start diagonally opposite — Black's King at e1 and "
                "White's King at d8 — not on the same file* as in modern chess.",
              ),
              const SizedBox(height: 4),
              _Paragraph(
                "Each side's back rank* holds Rook, Knight, Elephant, "
                "Counsellor and King, with pawns directly in front.",
              ),
              const SizedBox(height: 20),
              _SectionHeading('Piece Movement'),
              const SizedBox(height: 8),
              _PieceRule(
                type: PieceType.king,
                description:
                    "One square in any direction. Once per game per side, the "
                    "King may also make a Knight-like leap — useful for "
                    "escaping a tight spot, including escaping check.",
              ),
              _PieceRule(
                type: PieceType.counsellor,
                description:
                    "Exactly one square diagonally. The weakest of the major "
                    "pieces — much less powerful than a modern Queen.",
              ),
              _PieceRule(
                type: PieceType.elephant,
                description:
                    "Jumps exactly two squares diagonally, leaping over the "
                    "intervening square regardless of what's there. Only "
                    "reaches eight specific squares from any position.",
              ),
              _PieceRule(
                type: PieceType.knight,
                description:
                    "Moves in an L-shape — two squares in one direction, one "
                    "square perpendicular — exactly like the modern Knight. "
                    "Jumps over intervening pieces.",
              ),
              _PieceRule(
                type: PieceType.rook,
                description:
                    "Moves any distance horizontally or vertically, exactly "
                    "like the modern Rook. The most powerful long-range "
                    "piece in Chaturang.",
              ),
              _PieceRule(
                type: PieceType.pawn,
                description:
                    "Moves one square straight forward; captures one square "
                    "diagonally forward. No double-step first move, no en "
                    "passant.",
              ),
              const SizedBox(height: 16),
              _SectionHeading('Pawn Promotion'),
              _Paragraph(
                "When a pawn reaches the opposite back rank, it promotes — "
                "but only to the piece that originally stood on that file in "
                "the opening:",
              ),
              const SizedBox(height: 6),
              _PromotionTable(),
              const SizedBox(height: 8),
              _Paragraph(
                "Pawns cannot move onto e1 (White's enemy-king home) or d8 "
                "(Black's enemy-king home) — those squares have no valid "
                "promotion piece.",
              ),
              const SizedBox(height: 20),
              _SectionHeading('Winning the Game'),
              _Paragraph(
                "Checkmate ends the game — when the opposing King is "
                "attacked and cannot escape via any legal move.",
              ),
              const SizedBox(height: 4),
              _Paragraph(
                "If a player has no legal moves but is not in check, the "
                "result is stalemate — a draw.",
              ),
              const SizedBox(height: 28),
              const _Footnote(
                "* File = vertical column (a–h).  "
                "Rank = horizontal row (1–8).",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: ChaturangTheme.saffron.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: ChaturangTheme.secondaryText,
          fontSize: 12,

          fontFamily: 'RoyalSans',
          height: 1.4,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'RoyalSans',
          color: ChaturangTheme.saffronLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: ChaturangTheme.secondaryText,
        fontSize: 15,
        height: 1.4,
        fontFamily: 'RoyalSans',
      ),
    );
  }
}

class _PieceRule extends StatelessWidget {
  const _PieceRule({required this.type, required this.description});

  final PieceType type;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show the piece as saffron — same side that opens the app's view.
          pieceCapturedIcon(Piece(type, Side.white), size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: TextStyle(
                    fontFamily: 'RoyalSans',
                    color: ChaturangTheme.saffronLight,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: ChaturangTheme.secondaryText,
                    fontSize: 14,
                    height: 1.35,
                    fontFamily: 'RoyalSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionTable extends StatelessWidget {
  static const List<(String, String)> _rows = [
    ('a or h file', 'Rook'),
    ('b or g file', 'Knight'),
    ('c or f file', 'Elephant'),
    ('d8 → forbidden  ·  d1 (White only)', 'Counsellor'),
    ('e1 → forbidden  ·  e8 (Black only)', 'Counsellor'),
  ];

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: ChaturangTheme.secondaryText,
      fontSize: 14,
      height: 1.4,
      fontFamily: 'RoyalSans',
    );
    return Container(
      decoration: BoxDecoration(
        color: ChaturangTheme.charcoal.withValues(alpha: 0.35),
        border: Border.all(
          color: ChaturangTheme.saffron.withValues(alpha: 0.40),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (file, piece) in _rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(file, style: textStyle)),
                  const Icon(
                    Icons.arrow_right_alt,
                    color: ChaturangTheme.saffronLight,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    piece,
                    style: textStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ChaturangTheme.saffronLight,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
