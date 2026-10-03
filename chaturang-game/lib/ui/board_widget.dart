import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/appearance_service.dart';
import '../engine/board.dart';
import '../engine/move.dart';
import '../engine/pieces.dart';
import '../engine/square.dart';
import 'appearance.dart';
import 'board_tile.dart';
import 'theme.dart';

/// The royal sprites have a shared bottom anchor and normalized margins.
/// Slight lift beyond the cell gives depth without hiding adjacent pieces.
const double _sculptedOverflow = 1.10;

/// Block edge shown on a flat board, as a fraction of the cell. Strictly
/// this should be zero — see [_TileGlyph] for why it deliberately is not.
const double _tileFlatDepth = 0.16;

/// Additional edge at full rake, as a fraction of the cell.
const double _tileRakeDepth = 0.10;

/// Top face, as a fraction of the cell. Constant across pieces so every
/// emblem is drawn at the same size — it is the block under them that
/// varies, not the artwork.
const double _tileFaceFraction = 0.66;

/// Block height per rank, relative to a major piece.
///
/// A real set is not uniform, and neither were the sculpted models these
/// emblems replace — the raja stood 3.26 to the padati's 1.78. Uniform
/// blocks read as counters; a hierarchy reads as a set. Kept tighter than
/// the modelled ratio because a block only has the cell's height to work
/// with, where a standing piece could overflow into the rank behind.
const Map<PieceType, double> _tileRankHeight = {
  PieceType.king: 1.30,
  PieceType.counsellor: 1.05,
  PieceType.elephant: 1.00,
  PieceType.rook: 1.00,
  PieceType.knight: 0.92,
  PieceType.pawn: 0.75,
};

/// Sprites are authored at one size and downsampled to whatever the cell
/// turns out to be — a 2x reduction on a phone, more on a small board.
/// The default (`FilterQuality.low`) is a plain bilinear tap, which
/// undersamples at those ratios; medium is mipmapped and is the right
/// setting for minification. Not `high`: bicubic is tuned for magnification
/// and costs more for no gain when every device is scaling down.
const FilterQuality _spriteFilter = FilterQuality.medium;

/// SVG asset paths per piece type. Types absent from this map fall back to
/// the placeholder letter glyph until art lands.
const Map<PieceType, String> _pieceAssets = {
  PieceType.king: 'assets/pieces/king.svg',
  PieceType.counsellor: 'assets/pieces/counsellor.svg',
  PieceType.elephant: 'assets/pieces/elephant.svg',
  PieceType.knight: 'assets/pieces/knight.svg',
  PieceType.rook: 'assets/pieces/rook.svg',
  PieceType.pawn: 'assets/pieces/pawn.svg',
};

/// Small piece icon (no shadow, no mirroring) for compact contexts like the
/// captured-pieces display. Sized explicitly by the caller.
///
/// Tinted sets use their flat tint — a luminance ramp turns to mud at this
/// size, so they deliberately fall back to a single color here. A
/// [PieceShading.sculpted] set shows its real sprite instead: that art is a
/// photograph of a lit object, not a ramp, and survives the downscale.
Widget pieceCapturedIcon(Piece piece, {required double size}) {
  final set = AppearanceService.instance.pieceSet;
  final asset = _pieceAssets[piece.type];
  // A whole block at ~28px is a coloured square with a smudge on it, so a
  // tile set shows its emblem alone here.
  final tile = set.tileFor(piece.side);
  if (tile != null && asset != null) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        asset,
        colorFilter: ColorFilter.mode(tile.icon, BlendMode.srcIn),
        fit: BoxFit.contain,
      ),
    );
  }
  final sculpted = set.sculptedAsset(piece.type, piece.side);
  if (sculpted != null) {
    return SizedBox(
      width: size,
      height: size,
      child: _sculptedImage(sculpted, set, piece.side),
    );
  }
  if (asset == null) return SizedBox(width: size, height: size);
  return SizedBox(
    width: size,
    height: size,
    child: SvgPicture.asset(
      asset,
      colorFilter: ColorFilter.mode(set.iconTint(piece.side), BlendMode.srcIn),
      fit: BoxFit.contain,
    ),
  );
}

Widget _sculptedImage(String asset, PieceSet set, Side side) {
  final image = Image.asset(
    asset,
    fit: BoxFit.contain,
    filterQuality: _spriteFilter,
  );
  final filter = set.filterFor(side);
  return filter == null
      ? image
      : ColorFiltered(colorFilter: filter, child: image);
}

/// Renders the 8x8 Chaturang board with selection / legal-destination
/// highlights and a tap callback. White (rank 7) is at the bottom.
///
/// If [justMoved] is set, the moving piece is rendered as a "flying"
/// positioned widget that animates from source to destination square
/// (~280ms ease-out-cubic). When the animation completes, normal cell
/// rendering resumes.
///
/// Colors and shading come from the equipped [PieceSet] and [BoardSurface];
/// the widget listens to [AppearanceService] so a Store change repaints the
/// live board without any plumbing through the screen above it.
class BoardWidget extends StatefulWidget {
  const BoardWidget({
    super.key,
    required this.board,
    this.justMoved,
    this.onMoveAnimationComplete,
    this.selected,
    this.legalDestinations = const {},
    this.onTapSquare,
    this.flipped = false,
    this.previewPieces,
    this.previewSurface,
    this.pieceLift = 0.0,
    this.pieceScale = 1.0,
  });

  final PieceSet? previewPieces;
  final BoardSurface? previewSurface;
  final Board board;

  /// The move that was just applied to [board]. When this changes to a
  /// non-null value (compared by instance identity), the flight animation
  /// fires. Set to a new [Move] instance every time a move is made.
  final Move? justMoved;
  final ValueChanged<Move>? onMoveAnimationComplete;

  final Square? selected;
  final Set<Square> legalDestinations;
  final ValueChanged<Square>? onTapSquare;

  /// When true, the board renders rotated 180° — useful when the local
  /// player is on the dark side and wants their own pieces along the
  /// bottom (standard chess UX convention). Engine logic is untouched;
  /// only the screen-pixel mapping flips. Rank/file labels and the
  /// move-flight animation honor the flip too.
  final bool flipped;

  /// Counter-rotation in radians applied to each piece about its base, so
  /// pieces stand up off a raked board instead of lying in it. Zero on a
  /// flat board.
  ///
  /// Only the artwork lifts — the ground shadow stays in the board plane,
  /// which is what sells the piece as standing on the square rather than
  /// painted onto it. Tap targets are unaffected: the square is still the
  /// hit region no matter where its piece leans.
  final double pieceLift;

  /// Piece size relative to the square. Lifted pieces are drawn smaller so
  /// standing artwork doesn't overlap the rank behind it.
  final double pieceScale;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Move currently in flight, or null when no animation is running. Used to
  /// hide the destination cell's piece (since it's "flying") and overlay the
  /// animated piece.
  Move? _flying;
  Piece? _captured;
  Map<Square, Piece> _previousPieces = {};

  Map<Square, Piece> _snapshot() => {
    for (var rank = 0; rank < 8; rank++)
      for (var file = 0; file < 8; file++)
        if (widget.board.pieceAt(Square(file, rank)) case final Piece piece)
          Square(file, rank): piece,
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _previousPieces = _snapshot();
  }

  @override
  void didUpdateWidget(covariant BoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.justMoved == null) {
      _controller.stop();
      _flying = null;
      _captured = null;
    }
    if (widget.justMoved != null &&
        !identical(widget.justMoved, oldWidget.justMoved)) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _flying = null;
        _captured = null;
        _previousPieces = _snapshot();
        return;
      }
      _captured = _previousPieces[widget.justMoved!.to];
      setState(() => _flying = widget.justMoved);
      final animatedMove = widget.justMoved!;
      _controller.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _flying = null);
          widget.onMoveAnimationComplete?.call(animatedMove);
        }
      });
    }
    _previousPieces = _snapshot();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppearanceService.instance,
      builder: (context, _) {
        final appearance = AppearanceService.instance;
        final pieces = widget.previewPieces ?? appearance.pieceSet;
        final surface = widget.previewSurface ?? appearance.surface;
        return _buildBoard(pieces, surface.harmonizedFor(pieces));
      },
    );
  }

  Widget _buildBoard(PieceSet set, BoardSurface surface) {
    final flying = _flying;
    final flyingPiece = flying != null ? widget.board.pieceAt(flying.to) : null;

    final flipped = widget.flipped;
    return AspectRatio(
      aspectRatio: 1.0,
      child: ColoredBox(
        color: surface.field,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / 8;
            return Stack(
              children: [
                Column(
                  children: [
                    // The outer/inner loops walk *visual* rows and
                    // columns (top-to-bottom, left-to-right on
                    // screen). Logical (file, rank) is derived from
                    // them — identical to the visual coords when not
                    // flipped, inverted on both axes when flipped.
                    for (var visualRow = 0; visualRow < 8; visualRow++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var visualCol = 0; visualCol < 8; visualCol++)
                              Builder(
                                builder: (_) {
                                  final rank = flipped
                                      ? 7 - visualRow
                                      : visualRow;
                                  final file = flipped
                                      ? 7 - visualCol
                                      : visualCol;
                                  final square = Square(file, rank);
                                  return Expanded(
                                    child: _Cell(
                                      square: square,
                                      piece:
                                          (flying != null &&
                                              flying.to == square)
                                          ? null
                                          : widget.board.pieceAt(square),
                                      isSelected: widget.selected == square,
                                      isLegalDest: widget.legalDestinations
                                          .contains(square),
                                      flipped: flipped,
                                      set: set,
                                      surface: surface,
                                      lift: widget.pieceLift,
                                      pieceScale: widget.pieceScale,
                                      onTap: widget.onTapSquare == null
                                          ? null
                                          : () => widget.onTapSquare!(square),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                // Paint all surfaces first, then pieces back-to-front. A tall
                // piece can overlap the next rank without being erased by it.
                for (var visualRow = 0; visualRow < 8; visualRow++)
                  for (var visualCol = 0; visualCol < 8; visualCol++)
                    if (widget.board.pieceAt(
                          Square(
                            flipped ? 7 - visualCol : visualCol,
                            flipped ? 7 - visualRow : visualRow,
                          ),
                        )
                        case final Piece piece)
                      if (flying?.to !=
                          Square(
                            flipped ? 7 - visualCol : visualCol,
                            flipped ? 7 - visualRow : visualRow,
                          ))
                        Positioned(
                          left: visualCol * cellSize,
                          top: visualRow * cellSize,
                          width: cellSize,
                          height: cellSize,
                          child: IgnorePointer(
                            child: _PieceGlyph(
                              piece: piece,
                              set: set,
                              surface: surface,
                              lift: widget.pieceLift,
                              pieceScale: widget.pieceScale,
                            ),
                          ),
                        ),
                if (flying != null && _captured != null)
                  Positioned(
                    left:
                        (flipped ? 7 - flying.to.file : flying.to.file) *
                        cellSize,
                    top:
                        (flipped ? 7 - flying.to.rank : flying.to.rank) *
                        cellSize,
                    width: cellSize,
                    height: cellSize,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final t = _controller.value;
                          return Opacity(
                            opacity: (1 - t * 2).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 1 - t * .35,
                              child: _PieceGlyph(
                                piece: _captured!,
                                set: set,
                                surface: surface,
                                lift: widget.pieceLift,
                                pieceScale: widget.pieceScale,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (flying != null)
                  Positioned(
                    left:
                        (flipped ? 7 - flying.to.file : flying.to.file) *
                        cellSize,
                    top:
                        (flipped ? 7 - flying.to.rank : flying.to.rank) *
                        cellSize,
                    width: cellSize,
                    height: cellSize,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final t = ((_controller.value - .4) / .6).clamp(
                            0.0,
                            1.0,
                          );
                          return Opacity(
                            opacity: math.sin(t * math.pi) * .8,
                            child: Transform.scale(
                              scale: .5 + t * .7,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ChaturangTheme.saffronLight,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (flying != null && flyingPiece != null)
                  _FlyingPiece(
                    controller: _controller,
                    move: flying,
                    piece: flyingPiece,
                    cellSize: cellSize,
                    flipped: flipped,
                    set: set,
                    surface: surface,
                    lift: widget.pieceLift,
                    pieceScale: widget.pieceScale,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FlyingPiece extends StatelessWidget {
  const _FlyingPiece({
    required this.controller,
    required this.move,
    required this.piece,
    required this.cellSize,
    required this.flipped,
    required this.set,
    required this.surface,
    required this.lift,
    required this.pieceScale,
  });

  final AnimationController controller;
  final Move move;
  final Piece piece;
  final double cellSize;
  final bool flipped;
  final PieceSet set;
  final BoardSurface surface;
  final double lift;
  final double pieceScale;

  @override
  Widget build(BuildContext context) {
    // Translate logical (file, rank) to visual (col, row) — inverted
    // on both axes when the board is flipped 180°.
    int col(int file) => flipped ? 7 - file : file;
    int row(int rank) => flipped ? 7 - rank : rank;
    final fromLeft = col(move.from.file) * cellSize;
    final fromTop = row(move.from.rank) * cellSize;
    final toLeft = col(move.to.file) * cellSize;
    final toTop = row(move.to.rank) * cellSize;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(controller.value);
        return Positioned(
          left: fromLeft + (toLeft - fromLeft) * t,
          top:
              fromTop +
              (toTop - fromTop) * t -
              math.sin(t * math.pi) * cellSize * .22,
          width: cellSize,
          height: cellSize,
          child: Transform.scale(
            scale: 1 + math.sin(t * math.pi) * .12,
            child: child!,
          ),
        );
      },
      child: _PieceGlyph(
        piece: piece,
        set: set,
        surface: surface,
        lift: lift,
        pieceScale: pieceScale,
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.square,
    required this.piece,
    required this.isSelected,
    required this.isLegalDest,
    required this.onTap,
    required this.flipped,
    required this.set,
    required this.surface,
    required this.lift,
    required this.pieceScale,
  });

  final Square square;
  final Piece? piece;
  final bool isSelected;
  final bool isLegalDest;
  final VoidCallback? onTap;

  /// Same flag the parent passes through — drives which corner of the
  /// cell gets the rank/file coordinate labels. Without it, flipped
  /// boards would label the wrong edges.
  final bool flipped;

  final PieceSet set;
  final BoardSurface surface;
  final double lift;
  final double pieceScale;

  @override
  Widget build(BuildContext context) {
    // Highlight rules:
    //   - Selected piece's own square: warm tint (matches the palette of
    //     the piece you're holding).
    //   - Legal destination: green tint so it reads as distinctly
    //     different from the selected square — eye picks out the target
    //     squares immediately without confusing them with the source.
    //   - Legal destination that holds a capturable enemy piece: keep
    //     the capture-ring overlay so the player can tell a move apart
    //     from a capture at a glance.
    // Both tints come from the surface so they stay legible on dark
    // boards, where the parchment-tuned values would disappear.
    final Color? backgroundTint = isSelected
        ? surface.selection
        : isLegalDest
        ? surface.legal
        : null;

    final content = LayoutBuilder(
      builder: (context, constraints) {
        // Inside-board coordinates: rank digit on the left-file squares,
        // file letter on the bottom-rank squares. Sized off the cell so
        // they stay proportional at any board scale.
        final coordSize = constraints.maxHeight * 0.22;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (piece != null)
              Positioned.fill(
                child: _PieceNameTooltip(
                  piece: piece!,
                  child: const SizedBox.expand(),
                ),
              ),
            if (isLegalDest && piece == null)
              FractionallySizedBox(
                widthFactor: .24,
                heightFactor: .24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surface.coord.withValues(alpha: .65),
                  ),
                ),
              ),
            if (isLegalDest && piece != null)
              Positioned.fill(child: _CaptureRing(color: surface.captureRing)),
            // Rank label sits on the visually leftmost column —
            // file 0 normally, file 7 when flipped.
            if (square.file == (flipped ? 7 : 0))
              Positioned(
                top: 2,
                left: 3,
                child: _CoordLabel(
                  text: '${square.rank + 1}',
                  size: coordSize,
                  color: surface.coord,
                ),
              ),
            // File letter sits on the visually bottom row — rank 7
            // normally, rank 0 when flipped.
            if (square.rank == (flipped ? 0 : 7))
              Positioned(
                bottom: 1,
                right: 3,
                child: _CoordLabel(
                  text: String.fromCharCode(0x61 + square.file),
                  size: coordSize,
                  color: surface.coord,
                ),
              ),
          ],
        );
      },
    );

    final body = BoardTile(
      surface: surface,
      file: square.file,
      rank: square.rank,
      tint: backgroundTint,
      child: content,
    );

    return Semantics(
      label:
          '${square.algebraic}, ${piece == null ? "empty" : "${piece!.side.name} ${piece!.type.englishName}"}${isLegalDest ? ", legal destination" : ""}',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: ExcludeSemantics(child: body),
      ),
    );
  }
}

/// Long-press a piece to see what it is — "Ashva (Knight)".
///
/// Chaturang's pieces do not all map onto chess intuitions (the Gaja leaps
/// two diagonally; the Mantri is far weaker than a Queen), and a sculpted
/// set makes that worse, not better: a carved elephant is less self-evident
/// than a labelled diagram. The Rules screen carries the full movement
/// notes; this is the in-place reminder.
///
/// Long-press rather than tap because tap is how a piece is moved. The
/// board's own rake gesture is a vertical drag, which the tooltip's
/// long-press recognizer loses to, so dragging the board still works.
class _PieceNameTooltip extends StatelessWidget {
  const _PieceNameTooltip({required this.piece, required this.child});

  final Piece piece;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: piece.type.label,
      triggerMode: TooltipTriggerMode.longPress,
      preferBelow: false,
      verticalOffset: 22,
      waitDuration: Duration.zero,
      showDuration: const Duration(seconds: 2),
      decoration: BoxDecoration(
        color: ChaturangTheme.charcoal.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ChaturangTheme.saffron.withValues(alpha: 0.55),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      textStyle: TextStyle(
        fontFamily: 'RoyalSans',
        color: ChaturangTheme.saffronLight,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      child: child,
    );
  }
}

/// A piece drawing raised onto an extruded block.
///
/// A small base depth and projected edge preserve the relief in the fixed camera.
///
/// Everything is sized off the cell rather than in absolute pixels — the
/// same tile has to work at a 33pt phone cell and a 115pt iPad one.
class _TileGlyph extends StatelessWidget {
  const _TileGlyph({
    required this.asset,
    required this.type,
    required this.finish,
    required this.lift,
    required this.pieceScale,
  });

  final String asset;
  final PieceType type;
  final TileFinish finish;
  final double lift;
  final double pieceScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxHeight;
        final depth =
            cell *
            (_tileFlatDepth + _tileRakeDepth * math.sin(lift)) *
            (_tileRankHeight[type] ?? 1.0);
        // The block is laid out INSIDE its own box: a square top face with
        // the edge below it, together no taller than the cell. Letting the
        // edge hang past the box instead means the cell's clip eats most of
        // it — which is exactly what it did, leaving 7px of a 24px edge.
        //
        // The box is then anchored to the BOTTOM of the cell, not centred:
        // the base is where the block meets the board, so it has to stay put
        // while the block grows upward. Centring it would sink a tall piece
        // half its extra height into the square instead.
        final face = cell * _tileFaceFraction;
        final radius = BorderRadius.circular(face * 0.16);

        Widget tile = SizedBox(
          width: face,
          height: face + depth,
          child: Stack(
            children: [
              // Edge first, and it carries the contact shadow: hanging the
              // shadow off the top face instead paints it straight over the
              // edge and turns the block back into a dark smear.
              if (depth > 0.5)
                Positioned(
                  left: 0,
                  right: 0,
                  top: depth,
                  height: face,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      // Graded so the edge turns away from the light rather
                      // than reading as a flat second rectangle behind the
                      // face — that flatness is what makes a fake extrusion
                      // look like two stacked cards.
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          finish.side,
                          Color.lerp(finish.side, Colors.black, 0.35)!,
                        ],
                      ),
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.40),
                          blurRadius: face * 0.10,
                          offset: Offset(0, face * 0.05),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: face,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        finish.face,
                        Color.lerp(finish.face, Colors.black, 0.18)!,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: math.max(0.5, face * 0.03),
                    ),
                    boxShadow: [
                      // Tight shadow of the top rim onto the edge just below
                      // it — the lip that reads as a real overhang rather
                      // than a printed outline.
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.38),
                        blurRadius: face * 0.035,
                        offset: Offset(0, face * 0.03),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(face * 0.11),
                    child: SvgPicture.asset(
                      asset,
                      colorFilter: ColorFilter.mode(
                        finish.emblem,
                        BlendMode.srcIn,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        if (lift != 0.0 || pieceScale != 1.0) {
          tile = Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..rotateX(-lift)
              ..scaleByDouble(pieceScale, pieceScale, 1.0, 1.0),
            child: tile,
          );
        }
        return Align(alignment: Alignment.bottomCenter, child: tile);
      },
    );
  }
}

class _PieceGlyph extends StatelessWidget {
  const _PieceGlyph({
    required this.piece,
    required this.set,
    required this.surface,
    required this.lift,
    required this.pieceScale,
  });

  final Piece piece;
  final PieceSet set;
  final BoardSurface surface;
  final double lift;
  final double pieceScale;

  @override
  Widget build(BuildContext context) {
    final sculpted = set.sculptedAsset(piece.type, piece.side);
    final asset = sculpted ?? _pieceAssets[piece.type];

    final tile = set.tileFor(piece.side);
    if (tile != null && asset != null) {
      return _TileGlyph(
        asset: asset,
        type: piece.type,
        finish: tile,
        lift: lift,
        pieceScale: pieceScale,
      );
    }
    if (asset == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Text(
              piece.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: set.iconTint(piece.side),
                fontWeight: FontWeight.w900,
                fontFamily: 'RoyalSans',
                fontSize: constraints.maxHeight * 0.72,
                height: 1.0,
              ),
            ),
          );
        },
      );
    }

    /// The SVG art under an arbitrary filter — a flat tint, or the ramp that
    /// maps the drawing's own luminance onto the set's two-point palette.
    /// Both sides share one file here, so black is mirrored on the way out.
    Widget tintedArt(ColorFilter filter) {
      Widget svg = SvgPicture.asset(
        asset,
        colorFilter: filter,
        fit: BoxFit.contain,
      );
      if (piece.side == Side.black) {
        svg = Transform.scale(scaleX: -1, child: svg);
      }
      return svg;
    }

    /// The piece reduced to one flat color — the shape the ground shadow and
    /// the halo are both cut from. Works the same on a sprite as on an SVG:
    /// `srcIn` keeps the alpha and replaces every color under it.
    Widget silhouette(Color color) {
      if (sculpted == null) {
        return tintedArt(ColorFilter.mode(color, BlendMode.srcIn));
      }
      return Image.asset(
        sculpted,
        fit: BoxFit.contain,
        filterQuality: _spriteFilter,
        // Each side has its own generated asset and lighting.
        color: color,
        colorBlendMode: BlendMode.srcIn,
      );
    }

    // A sculpted set draws its sprite untouched; there is nothing to tint.
    final filter = set.filterFor(piece.side);
    Widget art = sculpted != null
        ? _sculptedImage(sculpted, set, piece.side)
        : tintedArt(filter!);

    // Sculpted sprites share one camera frame across all six pieces so the
    // modelled height differences survive, which leaves every piece but the
    // raja short of its cell. Scaling past the cell and anchoring at the
    // bottom restores the intended size; the tall pieces overflow upward
    // into the square behind, which is what a real set does when you look
    // across a board.
    if (sculpted != null) {
      art = Transform.scale(
        scale: _sculptedOverflow,
        alignment: Alignment.bottomCenter,
        child: art,
      );
    }

    if (lift != 0.0 || pieceScale != 1.0) {
      art = Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..rotateX(-lift)
          ..scaleByDouble(pieceScale, pieceScale, 1.0, 1.0),
        child: art,
      );
    }

    /// Soft rim light that separates the piece from a board of similar
    /// value. Null on surfaces that already contrast with every set.
    final halo = surface.haloFor(set, piece.side);
    Widget haloLayer(double size) => ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: size * 0.026, sigmaY: size * 0.026),
      child: silhouette(halo!),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxHeight;
        switch (set.groundShadow) {
          case GroundShadow.sticker:
            final shadowBlur = size * 0.04;
            final shadowOffsetY = size * 0.06;
            return Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(0, shadowOffsetY),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: shadowBlur,
                          sigmaY: shadowBlur,
                        ),
                        child: silhouette(Colors.black.withValues(alpha: 0.35)),
                      ),
                    ),
                  ),
                  if (halo != null) Positioned.fill(child: haloLayer(size)),
                  Positioned.fill(child: art),
                ],
              ),
            );
          case GroundShadow.none:
            // Only reachable for a set whose art draws its own shadow; the
            // tile path returns before this switch.
            return art;
          case GroundShadow.projected:
            // Squashed onto the board plane and leaned away from the light.
            // Only the *shadow* is clipped to the cell — it is the layer that
            // would otherwise smear onto a neighbouring square. The art is
            // left unclipped so a sculpted raja can stand taller than its
            // square, the way a real piece does when you look across a board.
            //
            // The inset is dropped for sculpted art too: its sprite already
            // carries margin from the shared render frame, and padding it
            // again is what leaves the board looking half-empty.
            final inset = sculpted != null
                ? EdgeInsets.zero
                : const EdgeInsets.all(4);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..translateByDouble(0.0, size * 0.01, 0.0, 1.0)
                        ..scaleByDouble(0.92, 0.085, 1.0, 1.0)
                        ..setEntry(0, 1, -0.18),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: size * 0.022,
                          sigmaY: size * 0.022,
                        ),
                        child: silhouette(Colors.black.withValues(alpha: 0.42)),
                      ),
                    ),
                  ),
                ),
                if (halo != null)
                  Positioned.fill(
                    child: Padding(padding: inset, child: haloLayer(size)),
                  ),
                Positioned.fill(
                  child: Padding(padding: inset, child: art),
                ),
              ],
            );
        }
      },
    );
  }
}

/// A small file/rank coordinate mark tucked into a board-edge square's
/// corner. Drawn in the surface's coordinate color at low opacity so it
/// reads as an unobtrusive engraving without competing with the pieces.
class _CoordLabel extends StatelessWidget {
  const _CoordLabel({
    required this.text,
    required this.size,
    required this.color,
  });

  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'RoyalSans',
        color: color.withValues(alpha: 0.92),
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
    );
  }
}

class _CaptureRing extends StatelessWidget {
  const _CaptureRing({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxHeight * 0.86;
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2.5),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
