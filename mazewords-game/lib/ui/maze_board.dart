import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../domain/maze.dart';
import '../domain/maze_theme.dart';
import 'style.dart';

/// The hit plane and painted floor share the same inset. Depth is rendered
/// underneath the wall/letter faces, never by distorting the touch coordinates.
class MazeBoard extends StatefulWidget {
  const MazeBoard({
    super.key,
    required this.maze,
    this.theme = MazeTheme.hedge,
    this.path = const [],
    this.hint,
    this.tapToSelect = false,
    this.tapTargets = const {},
    this.onStart,
    this.onStep,
    this.onEnd,
    this.onCancel,
    this.interactive = true,
  });
  final Maze maze;
  final MazeTheme theme;
  final List<int> path;
  final int? hint;
  final bool tapToSelect;
  final Set<int> tapTargets;
  final ValueChanged<int>? onStart;
  final ValueChanged<int>? onStep;
  final VoidCallback? onEnd;
  final VoidCallback? onCancel;
  final bool interactive;
  @override
  State<MazeBoard> createState() => _MazeBoardState();
}

class _MazeBoardState extends State<MazeBoard> {
  Offset? _last;
  int? _pointer;
  int? _cell(Offset point, Size size) {
    final board = boardRect(size);
    if (!board.contains(point)) return null;
    final x = ((point.dx - board.left) / board.width * widget.maze.width)
        .floor();
    final y = ((point.dy - board.top) / board.height * widget.maze.height)
        .floor();
    return y * widget.maze.width + x;
  }

  void _move(Offset point, Size size) {
    final from = _last;
    if (from == null) return;
    // Sample the actual finger segment, not a pathfinder: cannot cut corners
    // or teleport through walls when pointer events skip a cell.
    final cellSize = boardRect(size).width / widget.maze.width;
    final steps = math.max(
      1,
      ((point - from).distance / (cellSize / 5)).ceil(),
    );
    for (var n = 1; n <= steps; n++) {
      final cell = _cell(Offset.lerp(from, point, n / steps)!, size);
      if (cell != null) widget.onStep?.call(cell);
    }
    _last = point;
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, bounds) {
        final size = Size(bounds.maxWidth, bounds.maxHeight);
        return Semantics(
          label: widget.tapToSelect
              ? 'Tap letters to build a word. Highlighted letters are reachable through empty corridors. Press Submit when ready.'
              : 'Trace through open corridors and lift your finger to submit.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: !widget.interactive || !widget.tapToSelect
                ? null
                : (event) {
                    final cell = _cell(event.localPosition, size);
                    if (cell != null) widget.onStart?.call(cell);
                  },
            child: Listener(
              onPointerDown: !widget.interactive || widget.tapToSelect
                  ? null
                  : (event) {
                      if (_pointer != null) return;
                      final cell = _cell(event.localPosition, size);
                      if (cell == null) return;
                      _pointer = event.pointer;
                      _last = event.localPosition;
                      widget.onStart?.call(cell);
                    },
              onPointerMove: !widget.interactive || widget.tapToSelect
                  ? null
                  : (event) {
                      if (event.pointer == _pointer) {
                        _move(event.localPosition, size);
                      }
                    },
              onPointerUp: (event) {
                if (event.pointer != _pointer) return;
                _pointer = null;
                _last = null;
                widget.onEnd?.call();
              },
              onPointerCancel: (event) {
                if (event.pointer != _pointer) return;
                _pointer = null;
                _last = null;
                widget.onCancel?.call();
              },
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: BoardPainter(
                    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                    maze: widget.maze,
                    theme: widget.theme,
                    path: List.of(widget.path),
                    hint: widget.hint,
                    tapTargets: widget.tapToSelect
                        ? widget.tapTargets
                        : const {},
                  ),
                  size: size,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Rect boardRect(Size size) => Rect.fromLTWH(
  size.width * .028,
  size.height * .022,
  size.width * .944,
  size.height * .944,
);

class BoardPainter extends CustomPainter {
  BoardPainter({
    this.devicePixelRatio = 1,
    required this.maze,
    this.theme = MazeTheme.hedge,
    this.path = const [],
    this.hint,
    this.tapTargets = const {},
  });
  final Maze maze;
  final MazeTheme theme;
  final List<int> path;
  final int? hint;
  final Set<int> tapTargets;

  final double devicePixelRatio;

  bool get stone => theme == MazeTheme.stone;
  bool get glass => theme == MazeTheme.glass;
  Color get dark => stone
      ? const Color(0xFF424B49)
      : glass
      ? const Color(0xFF294D7B)
      : const Color(0xFF173D27);
  Color get light => stone
      ? const Color(0xFFB7B9AA)
      : glass
      ? const Color(0xFFB9F5FA)
      : const Color(0xFF88B54F);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = boardRect(size);
    final cell = rect.width / maze.width;
    final depth = cell * .15;
    final frame = rect.inflate(cell * .14);
    final radius = Radius.circular(cell * .25);
    final framePath = Path()..addRRect(RRect.fromRectAndRadius(frame, radius));
    canvas.drawShadow(framePath, const Color(0xFF163E3B), cell * .32, true);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame.shift(Offset(0, depth * 1.9)), radius),
      Paint()..color = dark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, radius),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, dark],
        ).createShader(frame),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * .08)),
      Paint()
        ..color = stone
            ? const Color(0xFFB9B9AB)
            : glass
            ? const Color(0xFFDDEDF7)
            : const Color(0xFFD5D2AC),
    );
    // Quiet stone floor checkerboard adds depth without hiding corridors.
    for (var y = 0; y < maze.height; y++) {
      for (var x = 0; x < maze.width; x++) {
        final floor = Rect.fromLTWH(
          rect.left + x * cell,
          rect.top + y * cell,
          cell,
          cell,
        );
        canvas.drawRect(
          floor.deflate(.5),
          Paint()
            ..color = (x + y).isEven
                ? (stone
                      ? const Color(0xFFC9C9BA)
                      : glass
                      ? const Color(0xFFEAF5FA)
                      : const Color(0xFFE2DEBA))
                : (stone
                      ? const Color(0xFFBABEB0)
                      : glass
                      ? const Color(0xFFD9EAF5)
                      : const Color(0xFFD5D3AB)),
        );
      }
    }
    // Deterministic surface detail stays still as the finger moves.
    final ground = math.Random(maze.seed);
    for (var n = 0; n < maze.width * maze.height * 9; n++) {
      final p = Offset(
        rect.left + ground.nextDouble() * rect.width,
        rect.top + ground.nextDouble() * rect.height,
      );
      canvas.drawCircle(
        p,
        cell * (.005 + ground.nextDouble() * .01),
        Paint()
          ..color = (glass ? Colors.white : dark).withValues(
            alpha: glass ? .65 : .09,
          ),
      );
    }
    Offset center(int index) => Offset(
      rect.left + (index % maze.width + .5) * cell,
      rect.top + (index ~/ maze.width + .5) * cell,
    );
    if (path.isNotEmpty) {
      final trail = Path()
        ..moveTo(center(path.first).dx, center(path.first).dy);
      for (final i in path.skip(1)) {
        final c = center(i);
        trail.lineTo(c.dx, c.dy);
      }
      canvas.drawPath(
        trail,
        Paint()
          ..color = const Color(0xFFDCAD47).withValues(alpha: .28)
          ..strokeWidth = cell * .36
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      canvas.drawPath(
        trail,
        Paint()
          ..color = const Color(0xFFF4C75F)
          ..strokeWidth = cell * .16
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        center(path.last),
        cell * .13,
        Paint()..color = Colors.white,
      );
    }
    // Every raised segment is anchored to the exact logical wall boundary.
    void wall(Offset a, Offset b) {
      final width = cell * (glass ? .12 : .17);
      final random = math.Random((a.dx * 71 + a.dy * 193 + b.dx * 13).round());
      final cap = StrokeCap.round;
      void stroke(Offset start, Offset end, Color color, double thickness) =>
          canvas.drawLine(
            start,
            end,
            Paint()
              ..color = color
              ..strokeWidth = thickness
              ..strokeCap = cap,
          );
      stroke(
        a + Offset(cell * .075, depth * 1.5),
        b + Offset(cell * .075, depth * 1.5),
        dark.withValues(alpha: .2),
        width * 1.8,
      );
      for (var layer = 5; layer >= 0; layer--) {
        final shift = Offset(0, depth * layer / 5);
        stroke(
          a + shift,
          b + shift,
          Color.lerp(dark, light, (5 - layer) / 13)!,
          width,
        );
      }
      if (stone) {
        // Uneven capstones with bevels, mineral flecks, seams and hairline cracks.
        for (var i = 0; i < 4; i++) {
          final c = Offset.lerp(a, b, (i + .5) / 4)!;
          final horizontal = (b.dx - a.dx).abs() > (b.dy - a.dy).abs();
          final block = Rect.fromCenter(
            center: c,
            width: horizontal ? cell * .245 : width * 1.15,
            height: horizontal ? width * 1.15 : cell * .245,
          );
          final shape = RRect.fromRectAndRadius(
            block,
            Radius.circular(cell * .028),
          );
          canvas.drawRRect(
            shape,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFD4D4C3),
                  light,
                  const Color(0xFF858E81),
                ],
              ).createShader(block),
          );
          canvas.drawLine(
            block.topLeft + Offset(2, 1),
            block.topRight - const Offset(2, -1),
            Paint()
              ..color = Colors.white.withValues(alpha: .45)
              ..strokeWidth = .8,
          );
          for (var j = 0; j < 13; j++) {
            canvas.drawCircle(
              Offset(
                block.left + random.nextDouble() * block.width,
                block.top + random.nextDouble() * block.height,
              ),
              cell * .008,
              Paint()..color = dark.withValues(alpha: .28),
            );
          }
          final crack = Path()
            ..moveTo(block.left + block.width * .3, block.top)
            ..relativeLineTo(block.width * .14, block.height * .4)
            ..relativeLineTo(-block.width * .08, block.height * .26);
          canvas.drawPath(
            crack,
            Paint()
              ..color = dark.withValues(alpha: .3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .7,
          );
          if (i == 0) {
            canvas.drawOval(
              Rect.fromCenter(
                center: block.bottomRight - Offset(2, 2),
                width: cell * .07,
                height: cell * .035,
              ),
              Paint()..color = const Color(0xFF718353),
            );
          }
        }
      } else if (glass) {
        stroke(a, b, const Color(0xFF84D9E4).withValues(alpha: .8), width);
        stroke(
          a - Offset(0, width * .35),
          b - Offset(0, width * .35),
          Colors.white.withValues(alpha: .95),
          cell * .022,
        );
        stroke(
          a + Offset(width * .28, depth * .65),
          b + Offset(width * .28, depth * .65),
          const Color(0xFF8888D4).withValues(alpha: .75),
          cell * .026,
        );
        stroke(
          a + Offset(0, depth),
          b + Offset(0, depth),
          const Color(0xFFB7F9FF),
          cell * .018,
        );
        final shine = Offset.lerp(a, b, .26)!;
        stroke(
          shine - Offset(cell * .035, cell * .035),
          shine + Offset(cell * .035, cell * .035),
          Colors.white.withValues(alpha: .75),
          cell * .022,
        );
      } else {
        // Overlapping foliage crowns hide the rigid wall cap and cast a leafy edge.
        for (var i = 0; i < 14; i++) {
          final c =
              Offset.lerp(a, b, i / 13)! +
              Offset(
                (random.nextDouble() - .5) * width * .6,
                (random.nextDouble() - .5) * width * .5,
              );
          final leaf = cell * (.046 + random.nextDouble() * .027);
          canvas.drawCircle(
            c + Offset(0, cell * .035),
            leaf * 1.18,
            Paint()..color = const Color(0xFF265E34),
          );
          canvas.drawOval(
            Rect.fromCenter(center: c, width: leaf * 2, height: leaf * 1.6),
            Paint()
              ..color = Color.lerp(
                const Color(0xFF40833A),
                const Color(0xFF9AC85C),
                random.nextDouble(),
              )!,
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: c - Offset(leaf * .25, leaf * .25),
              width: leaf * .9,
              height: leaf * .5,
            ),
            Paint()..color = const Color(0xFFCEE69A).withValues(alpha: .45),
          );
        }
      }
    }

    for (var y = 0; y < maze.height; y++) {
      for (var x = 0; x < maze.width; x++) {
        final origin = Offset(rect.left + x * cell, rect.top + y * cell);
        final bits = maze.walls[y * maze.width + x];
        if (bits & MazeDir.north.bit != 0) {
          wall(origin, origin + Offset(cell, 0));
        }
        if (bits & MazeDir.west.bit != 0) {
          wall(origin, origin + Offset(0, cell));
        }
        if (y == maze.height - 1 && bits & MazeDir.south.bit != 0) {
          wall(origin + Offset(0, cell), origin + Offset(cell, cell));
        }
        if (x == maze.width - 1 && bits & MazeDir.east.bit != 0) {
          wall(origin + Offset(cell, 0), origin + Offset(cell, cell));
        }
      }
    }
    for (final letter in maze.letters) {
      final index = letter.y * maze.width + letter.x;
      final c = center(index);
      final active = path.contains(index);
      final tile = Rect.fromCenter(
        center: c - Offset(0, depth * .22),
        width: cell * .66,
        height: cell * .65,
      );
      final r = Radius.circular(cell * .14);
      if (hint == index) {
        canvas.drawCircle(
          c,
          cell * .47,
          Paint()..color = gold.withValues(alpha: .5),
        );
        canvas.drawCircle(
          c,
          cell * .43,
          Paint()
            ..color = const Color(0xFFF5FAE3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(tile.shift(Offset(2, depth + 2)), r),
        Paint()..color = ink.withValues(alpha: .17),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tile.shift(Offset(0, depth)), r),
        Paint()
          ..color = active
              ? const Color(0xFFB28226)
              : dark.withValues(alpha: .6),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tile, r),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [const Color(0xFFFFE8A8), const Color(0xFFF1C65D)]
                : (stone
                      ? [const Color(0xFFE3E0CD), const Color(0xFFB9BDAD)]
                      : glass
                      ? [const Color(0xFFF2FEFF), const Color(0xFFB7DDEB)]
                      : [const Color(0xFFFFFFE8), const Color(0xFFE4E8C6)]),
          ).createShader(tile),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tile.deflate(.6), r),
        Paint()
          ..color = Colors.white.withValues(alpha: .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      if (stone && !active) {
        final mineral = math.Random(index + maze.seed);
        for (var i = 0; i < 24; i++) {
          final p = Offset(
            tile.left + 3 + mineral.nextDouble() * (tile.width - 6),
            tile.top + 3 + mineral.nextDouble() * (tile.height - 6),
          );
          canvas.drawCircle(
            p,
            cell * .006,
            Paint()..color = dark.withValues(alpha: .2),
          );
        }
      }
      if (glass) {
        final facet = Path()
          ..moveTo(tile.left + 3, tile.top + 3)
          ..lineTo(tile.right - 3, tile.top + 3)
          ..lineTo(tile.left + 3, tile.top + tile.height * .45)
          ..close();
        canvas.drawPath(
          facet,
          Paint()..color = Colors.white.withValues(alpha: .36),
        );
        canvas.drawLine(
          tile.bottomLeft + const Offset(3, -3),
          tile.bottomRight + const Offset(-3, -3),
          Paint()
            ..color = const Color(0xFF67B6D6)
            ..strokeWidth = 1.5,
        );
      }
      if (tapTargets.contains(index)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(tile.inflate(1.6), r),
          Paint()
            ..color = const Color(0xFF258270)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
        canvas.drawCircle(
          Offset(tile.right - 3, tile.top + 3),
          cell * .06,
          Paint()..color = const Color(0xFF258270),
        );
      }
      final letterStyle = TextStyle(
        fontFamily: maze.script.font,
        fontSize: cell * .40,
        // Indic families ship a real bold face; Latin has a real extra-bold.
        fontWeight: maze.script.indic ? FontWeight.w700 : FontWeight.w800,
        fontVariations: maze.script.kana
            ? const [FontVariation('wght', 800)]
            : null,
        color: ink,
      );
      final text = TextPainter(
        text: TextSpan(text: letter.letter, style: letterStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      // Preserve the same fit limits, but lay out at the final size instead of
      // scaling painted text. Solid glyphs avoid the old doubled shadow edges.
      final scale = [
        1.0,
        tile.width * .85 / text.width,
        tile.height * .90 / text.height,
      ].reduce((a, b) => a < b ? a : b);
      if (scale < 1) {
        text.text = TextSpan(
          text: letter.letter,
          style: letterStyle.copyWith(fontSize: cell * .40 * scale),
        );
        text.layout();
      }
      double pixelAligned(double value) =>
          (value * devicePixelRatio).roundToDouble() / devicePixelRatio;
      text.paint(
        canvas,
        Offset(
          pixelAligned(c.dx - text.width / 2),
          pixelAligned(c.dy - depth * .25 - text.height / 2),
        ),
      );
      text.dispose();
    }
    // Brass corner pins finish the board as a physical object.
    for (final p in [
      frame.topLeft,
      frame.topRight,
      frame.bottomLeft,
      frame.bottomRight,
    ]) {
      final pin = Offset(
        p.dx + (p.dx < rect.center.dx ? 5 : -5),
        p.dy + (p.dy < rect.center.dy ? 5 : -5),
      );
      canvas.drawCircle(pin, 2, Paint()..color = const Color(0xFFC9DAAB));
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => true;
}
