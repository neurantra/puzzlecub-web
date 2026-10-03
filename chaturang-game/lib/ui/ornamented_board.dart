import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../engine/board.dart';
import '../engine/move.dart';
import '../engine/square.dart';
import 'board_widget.dart';
import 'appearance.dart';
import 'theme.dart';

/// Lets a hit test through even when the point lies outside this box.
///
/// The raked stage paints wider than it lays out: perspective magnifies the
/// near edge past the board's own bounds. Flutter's default [RenderBox.hitTest]
/// rejects anything outside `size` before the child ever sees it, so taps on
/// the near ranks used to be dropped — and the layout compensated by
/// inflating the whole stage until the magnified edge fitted back inside,
/// paying for it in board width.
///
/// Skipping the bounds check hands the point straight to the transform,
/// which already inverse-maps correctly. The board can then be sized for
/// what it *looks* like rather than for the hit tester.
class _HitTestOverflow extends SingleChildRenderObjectWidget {
  const _HitTestOverflow({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitTestOverflow();
}

class _RenderHitTestOverflow extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Deliberately no `size.contains(position)` guard — see the class doc.
    // The child is a perspective transform; let it decide.
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// A beveled wooden slab in perspective. Pieces counter-rotate toward the
/// viewer; all finishes share the same geometry and hit-test projection.
class OrnamentedBoard extends StatelessWidget {
  const OrnamentedBoard({
    super.key,
    required this.board,
    this.statusText,
    this.lastMoveText,
    this.justMoved,
    this.onMoveAnimationComplete,
    this.selected,
    this.legalDestinations = const {},
    this.onTapSquare,
    this.flipped = false,
    this.previewPieces,
    this.previewSurface,
  });
  final PieceSet? previewPieces;
  final BoardSurface? previewSurface;
  final Board board;
  final String? statusText, lastMoveText;
  final Move? justMoved;
  final ValueChanged<Move>? onMoveAnimationComplete;
  final Square? selected;
  final Set<Square> legalDestinations;
  final ValueChanged<Square>? onTapSquare;
  final bool flipped;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Fixed shallow camera: all finishes share the same readable projection.
      const radians = 10 * math.pi / 180;
      final roomY = 1.04;
      final widthFactor = 1 - .12 * math.sin(radians) / 2;
      final statusHeight = statusText == null ? 0.0 : 48.0;
      final frame = math.min(
        constraints.maxWidth * widthFactor,
        math.max(0.0, constraints.maxHeight - statusHeight) / roomY,
      );
      final stageHeight = frame * roomY;
      final depth = frame * .012;
      final band = frame * .006;
      final headroom = frame * (1 / math.cos(radians) - 1) * .14;
      final playable = frame - 2 * band - headroom;
      final camera = Matrix4.identity()
        ..setEntry(3, 2, -.12 / math.max(frame, 1))
        ..rotateX(radians);
      return SizedBox(
        width: constraints.maxWidth,
        height: stageHeight + statusHeight,
        child: Column(
          children: [
            SizedBox(
              height: stageHeight,
              width: constraints.maxWidth,
              child: _HitTestOverflow(
                child: Transform(
                  alignment: Alignment.center,
                  transform: camera,
                  child: Center(
                    child: SizedBox(
                      width: frame,
                      height: frame,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Thick solid edge behind the top face, with a contact shadow.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: depth,
                            bottom: -depth,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF65462D),
                                    Color(0xFF2D2018),
                                    Color(0xFF795839),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFFBE9860),
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x99000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFC4A16A),
                                    Color(0xFF735438),
                                    Color(0xFFAE8A56),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFFE0C592),
                                  width: 1.3,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: band + headroom / 2,
                            top: band + headroom,
                            width: playable,
                            height: playable,
                            child: BoardWidget(
                              board: board,
                              previewPieces: previewPieces,
                              previewSurface: previewSurface,
                              justMoved: justMoved,
                              onMoveAnimationComplete: onMoveAnimationComplete,
                              selected: selected,
                              legalDestinations: legalDestinations,
                              onTapSquare: onTapSquare,
                              flipped: flipped,
                              pieceLift: radians,
                              pieceScale: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (statusText != null)
              SizedBox(
                height: statusHeight,
                width: constraints.maxWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xF51A3031),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFF62746C)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            statusText!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ChaturangTheme.primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (lastMoveText != null)
                          Text(
                            lastMoveText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ChaturangTheme.secondaryText,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
