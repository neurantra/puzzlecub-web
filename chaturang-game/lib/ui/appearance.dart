import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../engine/pieces.dart';
import 'theme.dart';

/// Anything the Store can sell. Both axes of the appearance system —
/// [PieceSet] and [BoardSurface] — implement this so the catalog UI can
/// render them through one code path.
abstract class StoreItem {
  String get id;
  String get name;
  String get blurb;

  /// Price in coins. Zero means free — owned from the first launch and
  /// never shown with a Buy button.
  int get price;
}

// ---------------------------------------------------------------------------
// Piece sets
// ---------------------------------------------------------------------------

/// How a set colors the piece SVGs.
enum PieceShading {
  /// Flat single-tint silhouette via `BlendMode.srcIn` — the 1.1 look.
  /// Discards everything inside the artwork, which is why the sculpted
  /// detail in `rook.svg` / `pawn.svg` never reached the screen.
  flat,

  /// Luminance mapped onto a two-point ramp, preserving the modelled form
  /// baked into the art.
  ramp,

  /// Dimensional royal artwork, one sprite per piece and side. The standard
  /// finish preserves its ivory/ebony and gold; cosmetic finishes apply a
  /// luminance ramp while retaining sculptural shading.
  sculpted,

  /// The piece drawing sits on top of an extruded block, like an inlaid
  /// tile. Reads the same SVGs as [flat] does, but against a contrasting
  /// face instead of the board — which is what lets the drawing's own
  /// detail survive at cell size. A 3D render spends most of its pixels on
  /// shading; flat art spends all of them on shape.
  tile,
}

/// How a piece is grounded on its square.
enum GroundShadow {
  /// Offset blurred copy of the whole silhouette. Reads as a sticker
  /// shadow rather than contact with the board, but it tracks the piece
  /// exactly and so can never drift onto empty board.
  sticker,

  /// The silhouette squashed onto the board plane and leaned away from the
  /// light. Physically honest for pieces that stand on a base; pieces
  /// without one (knight, counsellor — see BACKLOG.md) render a soft smear
  /// instead of a footprint.
  projected,

  /// The art draws its own. A tile is a solid block with a real edge, so it
  /// casts a hard-edged shadow off that edge rather than a blurred copy of
  /// a silhouette — and a squashed *square* silhouette reads as a smudge.
  none,
}

/// Per-side finish for a [PieceShading.tile] set.
@immutable
class TileFinish {
  const TileFinish({
    required this.face,
    required this.side,
    required this.emblem,
    required this.icon,
  });

  /// Top of the block, under the emblem.
  final Color face;

  /// The extruded edge. Only visible on a raked board — looking straight
  /// down at a flat one you are looking along the block's own axis.
  final Color side;

  /// The piece drawing itself, tinted flat onto [face].
  final Color emblem;

  /// Tint for the captured-piece row, which draws the emblem alone with no
  /// block behind it. Cannot just be [face]: an ebony face is near-black and
  /// the captures bar sits on deep maroon, so the piece would vanish.
  final Color icon;
}

/// Per-side colors for a [PieceSet].
@immutable
class PieceTone {
  const PieceTone({
    required this.flat,
    required this.shadow,
    required this.light,
  });

  /// Single tint used by [PieceShading.flat], and by small icons at any
  /// shading — a full ramp turns to mud at the ~28px captured-piece size.
  final Color flat;

  /// Dark end of the ramp: where the artwork's blackest pixels land.
  final Color shadow;

  /// Light end of the ramp: where the artwork's whitest pixels land.
  final Color light;
}

@immutable
class PieceSet implements StoreItem {
  const PieceSet({
    required this.id,
    required this.name,
    required this.blurb,
    required this.price,
    required this.shading,
    required this.groundShadow,
    required this.white,
    required this.black,
    this.assetPrefix,
    this.tintSculpted = false,
    this.tileWhite,
    this.tileBlack,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String blurb;
  @override
  final int price;

  final PieceShading shading;
  final GroundShadow groundShadow;
  final PieceTone white;
  final PieceTone black;

  /// Asset directory holding the per-side sprites, for
  /// [PieceShading.sculpted] sets. Null on the SVG sets, which share one
  /// piece of art between both sides and separate them by tint instead.
  final String? assetPrefix;

  /// A material finish applied without removing the rendered highlights.
  final bool tintSculpted;

  /// Block colors for [PieceShading.tile], null on every other set.
  final TileFinish? tileWhite;
  final TileFinish? tileBlack;

  PieceTone toneFor(Side side) => side == Side.white ? white : black;

  /// The block finish for [side], or null when this set does not draw tiles.
  TileFinish? tileFor(Side side) => side == Side.white ? tileWhite : tileBlack;

  /// The pre-rendered sprite for [type] on [side], or null when this set
  /// draws tinted SVGs instead.
  String? sculptedAsset(PieceType type, Side side) {
    final prefix = assetPrefix;
    if (prefix == null) return null;
    return '$prefix${type.name}_${side.name}.png';
  }

  /// Filter applied to the piece art when drawn at board size, or null for
  /// [PieceShading.sculpted] — that art already carries its own baked
  /// lighting and is drawn untouched.
  ColorFilter? filterFor(Side side) {
    final tone = toneFor(side);
    return switch (shading) {
      PieceShading.flat => ColorFilter.mode(tone.flat, BlendMode.srcIn),
      PieceShading.ramp => rampFilter(tone.shadow, tone.light),
      PieceShading.sculpted =>
        tintSculpted ? rampFilter(tone.shadow, tone.light) : null,
      // The emblem is tinted by the tile renderer against its own face
      // color, which this filter knows nothing about.
      PieceShading.tile => null,
    };
  }

  /// Flat tint for compact contexts (captured-piece row, rules screen).
  Color iconTint(Side side) => toneFor(side).flat;
}

/// Maps pixel luminance onto a two-point color ramp: the artwork's darkest
/// pixels land on [shadow], its brightest on [light], everything between is
/// interpolated. Unlike `BlendMode.srcIn` this preserves the modelling
/// already present in the art.
///
/// `ColorFilter.matrix` is row-major 4x5 over unpremultiplied RGBA with the
/// translation column in 0..255 space — the same convention the frame filter
/// in `ornamented_board.dart` uses.
ColorFilter rampFilter(Color shadow, Color light) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722; // Rec.709 luminance
  List<double> row(double from, double to) {
    final d = (to - from) / 255.0;
    return <double>[lr * d, lg * d, lb * d, 0, from];
  }

  return ColorFilter.matrix(<double>[
    ...row(shadow.r * 255, light.r * 255),
    ...row(shadow.g * 255, light.g * 255),
    ...row(shadow.b * 255, light.b * 255),
    0,
    0,
    0,
    1,
    0,
  ]);
}

/// The same modeled geometry is included for everyone. Store items change
/// materials, never piece shape, depth, animation or camera availability.
const PieceSet kSculptedPieces = PieceSet(
  id: 'pieces.sculpted',
  name: 'Ivory & Ebony',
  blurb: 'The complete carved 3D set. Included with every game.',
  price: 0,
  shading: PieceShading.sculpted,
  groundShadow: GroundShadow.projected,
  assetPrefix: 'assets/pieces/royal/',
  white: PieceTone(
    flat: Color(0xFFCFC5AE),
    shadow: Color(0xFF6E6A5E),
    light: Color(0xFFE8E3D7),
  ),
  black: PieceTone(
    flat: Color(0xFF3E3734),
    shadow: Color(0xFF121213),
    light: Color(0xFFB8B8B4),
  ),
);

/// Compatibility name for code that formerly selected the flat free set.
const PieceSet kClassicPieces = kSculptedPieces;

const PieceSet kSandalwoodPieces = PieceSet(
  id: 'pieces.sandalwood',
  name: 'Sandalwood & Rosewood',
  blurb: 'Honey-colored wood and polished rosewood on the same carved pieces.',
  price: 400,
  shading: PieceShading.sculpted,
  groundShadow: GroundShadow.projected,
  assetPrefix: 'assets/pieces/royal/',
  tintSculpted: true,
  white: PieceTone(
    flat: Color(0xFFD6AA69),
    shadow: Color(0xFF593418),
    light: Color(0xFFF5DAB0),
  ),
  black: PieceTone(
    flat: Color(0xFF783D27),
    shadow: Color(0xFF382116),
    light: Color(0xFFE3AA72),
  ),
);

/// Preserve the old purchase id while replacing the flat tile geometry.
const PieceSet kInlaidTiles = PieceSet(
  id: 'pieces.tiles',
  name: 'Jade & Onyx',
  blurb: 'Celadon jade and deep green onyx, with sculpted highlights.',
  price: 500,
  shading: PieceShading.sculpted,
  groundShadow: GroundShadow.projected,
  assetPrefix: 'assets/pieces/royal/',
  tintSculpted: true,
  white: PieceTone(
    flat: Color(0xFFB8D6BA),
    shadow: Color(0xFF345C4B),
    light: Color(0xFFE5F2D9),
  ),
  black: PieceTone(
    flat: Color(0xFF254D42),
    shadow: Color(0xFF163E34),
    light: Color(0xFF9CBEA4),
  ),
);

const PieceSet kBronzePieces = PieceSet(
  id: 'pieces.bronze',
  name: 'Champagne & Bronze',
  blurb: 'Warm metallic finishes on the full carved set.',
  price: 600,
  shading: PieceShading.sculpted,
  groundShadow: GroundShadow.projected,
  assetPrefix: 'assets/pieces/royal/',
  tintSculpted: true,
  white: PieceTone(
    flat: Color(0xFFE4CB94),
    shadow: Color(0xFF6C532D),
    light: Color(0xFFFFE8AC),
  ),
  black: PieceTone(
    flat: Color(0xFF795533),
    shadow: Color(0xFF4C3020),
    light: Color(0xFFDBAC66),
  ),
);

const List<PieceSet> kPieceSets = [
  kSculptedPieces,
  kSandalwoodPieces,
  kInlaidTiles,
  kBronzePieces,
];

// ---------------------------------------------------------------------------
// Board surfaces
// ---------------------------------------------------------------------------

/// How square boundaries are drawn.
enum SquareEdge {
  /// Hairline grid on a flat field — the 1.1 look.
  hairline,

  /// Bevelled inlay: lit top-left edges, shaded bottom-right, with a faint
  /// diagonal gradient across the face so the playfield reads as carved
  /// rather than printed.
  bevel,
}

enum BoardPattern { grain, marble, checker, lattice, slate }

@immutable
class BoardSurface implements StoreItem {
  const BoardSurface({
    required this.id,
    required this.name,
    required this.blurb,
    required this.price,
    required this.field,
    required this.edge,
    required this.coord,
    required this.selection,
    required this.legal,
    required this.captureRing,
    this.highlightMix = 0.10,
    this.shadowMix = 0.06,
    this.pieceHalo,
    this.pattern = BoardPattern.grain,
    this.alternateField,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String blurb;
  @override
  final int price;

  /// Base color of a square.
  final Color field;
  final BoardPattern pattern;
  final Color? alternateField;

  Color fieldAt(int file, int rank) =>
      alternateField != null && (file + rank).isOdd ? alternateField! : field;

  /// Keep the chosen hue/material, but place both square tones between the
  /// armies in luminance. The geometric midpoint balances contrast ratios.
  /// This is a rendering choice; it never changes equipped items or ownership.
  BoardSurface harmonizedFor(PieceSet pieces) {
    final whiteL = pieces.white.flat.computeLuminance();
    final blackL = pieces.black.flat.computeLuminance();
    final target = math.sqrt((whiteL + .05) * (blackL + .05)) - .05;
    final hue = HSLColor.fromColor(field);
    Color atLuminance(double value) {
      var low = 0.0;
      var high = 1.0;
      for (var step = 0; step < 20; step++) {
        final mid = (low + high) / 2;
        final color = hue
            .withSaturation(hue.saturation.clamp(0.0, .28))
            .withLightness(mid)
            .toColor();
        if (color.computeLuminance() < value) {
          low = mid;
        } else {
          high = mid;
        }
      }
      return hue
          .withSaturation(hue.saturation.clamp(0.0, .28))
          .withLightness((low + high) / 2)
          .toColor();
    }

    final base = atLuminance(target);
    return BoardSurface(
      id: id,
      name: name,
      blurb: blurb,
      price: price,
      field: atLuminance(target + .012),
      alternateField: atLuminance(target - .012),
      pattern: pattern,
      edge: edge,
      coord: base.computeLuminance() > .18
          ? const Color(0xFF182322)
          : const Color(0xFFF9F4E8),
      selection: const Color(0x709FE7D0),
      legal: const Color(0x8061B899),
      captureRing: const Color(0xFFECC17A),
      pieceHalo: pieceHalo,
      highlightMix: highlightMix,
      shadowMix: shadowMix,
    );
  }

  final SquareEdge edge;

  /// Coordinate label color (the a-h / 1-8 marks on the board edge).
  final Color coord;

  /// Tint over the selected piece's own square.
  final Color selection;

  /// Tint over a legal destination square.
  final Color legal;

  /// Ring drawn over a capturable enemy piece.
  final Color captureRing;

  /// How far the lit face is lerped toward white, and the shaded face
  /// toward charcoal. Ignored for [SquareEdge.hairline].
  final double highlightMix;
  final double shadowMix;

  /// Rim light available to pieces that would otherwise disappear into
  /// this field, or null on surfaces that contrast with everything.
  ///
  /// Piece sets and surfaces are independent axes, so nothing stops a
  /// player equipping dark pieces on a dark board — where one side simply
  /// vanishes. Rather than forbid combinations or hand-tune every pair,
  /// a dark surface declares a contrasting rim here and [haloFor] applies
  /// it only to the side that needs it. Sets that don't exist yet are
  /// covered automatically.
  final Color? pieceHalo;

  /// Luminance gap below which a piece is judged to be disappearing into
  /// the field. Sized so today's sandalwood-on-rosewood case (gap ~0.02)
  /// gets a rim while its ivory side (gap ~0.27) is left clean.
  static const double _haloThreshold = 0.18;

  /// The rim light [side] needs against this field under [set], or null
  /// when the piece already stands out on its own.
  Color? haloFor(PieceSet set, Side side) {
    final halo = pieceHalo;
    if (halo == null) return null;
    final gap =
        (field.computeLuminance() - set.toneFor(side).flat.computeLuminance())
            .abs();
    return gap < _haloThreshold ? halo : null;
  }

  Color get faceLight => Color.lerp(field, Colors.white, highlightMix)!;
  Color get faceDark => Color.lerp(field, ChaturangTheme.charcoal, shadowMix)!;
}

/// Quiet contrasting walnut inlays keep both armies readable.
const BoardSurface kParchmentSurface = BoardSurface(
  id: 'board.parchment',
  name: 'Royal Walnut',
  blurb: 'An inlaid 3D walnut board. Included with every game.',
  price: 0,
  field: Color(0xFFE0D6BE),
  alternateField: Color(0xFF9C9C86),
  edge: SquareEdge.bevel,
  coord: ChaturangTheme.charcoal,
  selection: Color(0x52C97B2A),
  legal: Color(0x6B6B9D5C),
  captureRing: Color(0xA62A1F14),
);

// NOTE: prices below are provisional — the catalog and pricing pass is
// still open. Surfaces are near-free to author (a field color plus two
// mix factors), which is what makes a real catalog affordable.
const BoardSurface kMarbleSurface = BoardSurface(
  id: 'board.marble',
  name: 'Marble Inlay',
  pattern: BoardPattern.marble,
  blurb: 'Cool pale stone with a crisp bevelled edge.',
  price: 200,
  field: Color(0xFFE6E2D8),
  edge: SquareEdge.bevel,
  coord: Color(0xFF3A342A),
  selection: Color(0x52B8862F),
  legal: Color(0x6B5C8F52),
  captureRing: Color(0xA62A2620),
  highlightMix: 0.14,
  shadowMix: 0.09,
);

const BoardSurface kRosewoodSurface = BoardSurface(
  id: 'board.rosewood',
  name: 'Rosewood Check',
  pattern: BoardPattern.checker,
  alternateField: Color(0xFFB99B77),
  blurb: 'Deep polished hardwood; pieces read bright against it.',
  price: 250,
  field: Color(0xFF7A4A32),
  edge: SquareEdge.bevel,
  coord: Color(0xFFF0DCC0),
  selection: Color(0x66E19945),
  legal: Color(0x7A8FC47A),
  captureRing: Color(0xC6F0DCC0),
  highlightMix: 0.16,
  shadowMix: 0.16,
  pieceHalo: Color(0x59F5E3C6),
);

const BoardSurface kMughalBlueSurface = BoardSurface(
  id: 'board.mughal',
  name: 'Mughal Blue',
  pattern: BoardPattern.lattice,
  blurb: 'Glazed indigo tilework from the Deccan courts.',
  price: 250,
  field: Color(0xFF2E5A78),
  edge: SquareEdge.bevel,
  coord: Color(0xFFE8DCC0),
  selection: Color(0x66E19945),
  legal: Color(0x7A7FC49A),
  captureRing: Color(0xC6E8DCC0),
  highlightMix: 0.18,
  shadowMix: 0.18,
  pieceHalo: Color(0x59EFE4CC),
);

const BoardSurface kSlateSurface = BoardSurface(
  id: 'board.slate',
  name: 'Slate',
  pattern: BoardPattern.slate,
  blurb: 'Matte dark stone — the quietest board in the set.',
  price: 200,
  field: Color(0xFF4A4A48),
  edge: SquareEdge.bevel,
  coord: Color(0xFFE0DED8),
  selection: Color(0x66E19945),
  legal: Color(0x7A8FC47A),
  captureRing: Color(0xC6E0DED8),
  highlightMix: 0.16,
  shadowMix: 0.18,
  pieceHalo: Color(0x59EDEBE4),
);

const List<BoardSurface> kBoardSurfaces = <BoardSurface>[
  kParchmentSurface,
  kMarbleSurface,
  kRosewoodSurface,
  kMughalBlueSurface,
  kSlateSurface,
];
