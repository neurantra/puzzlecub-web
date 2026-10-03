import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/puzzle_board.dart';

const ink = Color(0xFF173E46);
const teal = Color(0xFF08786F);
const cream = Color(0xFFFFFBEE);
const coral = Color(0xFFED8976);
const letterColors = [
  Color(0xFFFFD477),
  Color(0xFF91D3BB),
  Color(0xFFAECFED),
  Color(0xFFF1A498),
  Color(0xFFCFB7E7),
];

ThemeData toyTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'PlusJakartaSans',
  scaffoldBackgroundColor: cream,
  colorScheme: ColorScheme.fromSeed(
    seedColor: teal,
    surface: cream,
  ).copyWith(primary: teal, onSurface: ink, onSurfaceVariant: ink),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 38,
      height: 1.12,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    headlineSmall: TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 1.4,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 54),
      backgroundColor: teal,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
);

class Garden extends StatelessWidget {
  const Garden({super.key, required this.child, this.playful = false});
  final bool playful;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: CustomPaint(painter: _GardenPainter())),
      if (playful) const Positioned.fill(child: _FloatingBubbles()),
      SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: child,
          ),
        ),
      ),
    ],
  );
}

class _GardenPainter extends CustomPainter {
  const _GardenPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = cream);
    final p = Paint()..color = const Color(0xFFFFE6AE);
    canvas.drawCircle(Offset(size.width + 10, 90), 155, p);
    p.color = const Color(0xFFE1F0E3);
    canvas.drawOval(
      Rect.fromLTWH(-size.width * .3, size.height - 95, size.width * 1.4, 280),
      p,
    );
    p.color = const Color(0xFFCEE5D6);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .35, size.height - 48, size.width, 180),
      p,
    );
    for (var i = 0; i < 19; i++) {
      p.color = [
        coral,
        teal,
        const Color(0xFFCAAB63),
      ][i % 3].withValues(alpha: .13);
      canvas.drawCircle(
        Offset((i * 137.0 + 17) % size.width, (i * 197.0 + 130) % size.height),
        3,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_GardenPainter oldDelegate) => false;
}

/// A vector toy character: no remote art, tracks, or bitmap scaling artifacts.
class Pip extends StatefulWidget {
  const Pip({super.key, this.size = 110, this.happy = true});
  final double size;
  final bool happy;
  @override
  State<Pip> createState() => _PipState();
}

class _PipState extends State<Pip> with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else {
      _animation.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Pip, your friendly puzzle buddy',
    image: true,
    child: AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Transform.translate(
        offset: Offset(
          0,
          MediaQuery.disableAnimationsOf(context)
              ? 0
              : math.sin(_animation.value * math.pi) * -5,
        ),
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PipPainter(widget.happy),
        ),
      ),
    ),
  );
}

class _PipPainter extends CustomPainter {
  const _PipPainter(this.happy);
  final bool happy;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120);
    final p = Paint();
    canvas.drawOval(
      const Rect.fromLTWH(18, 107, 85, 8),
      p..color = ink.withValues(alpha: .12),
    );
    canvas.drawOval(
      const Rect.fromLTWH(18, 91, 32, 19),
      p..color = const Color(0xFFD78042),
    );
    canvas.drawOval(const Rect.fromLTWH(74, 91, 32, 19), p);
    canvas.drawOval(
      const Rect.fromLTWH(0, 52, 27, 37),
      p..color = const Color(0xFFEAA84D),
    );
    canvas.drawOval(const Rect.fromLTWH(95, 39, 23, 39), p);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(15, 15, 91, 84),
      const Radius.circular(31),
    );
    canvas.drawRRect(
      body,
      p
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE69D), Color(0xFFF3B84F)],
        ).createShader(body.outerRect),
    );
    p.shader = null;
    canvas.drawOval(
      const Rect.fromLTWH(24, 24, 55, 15),
      p..color = Colors.white.withValues(alpha: .35),
    );
    canvas.drawCircle(const Offset(42, 55), 5, p..color = ink);
    canvas.drawCircle(const Offset(78, 55), 5, p);
    canvas.drawCircle(const Offset(43, 53), 1.5, p..color = Colors.white);
    canvas.drawCircle(const Offset(79, 53), 1.5, p);
    canvas.drawOval(
      const Rect.fromLTWH(24, 64, 17, 8),
      p..color = coral.withValues(alpha: .8),
    );
    canvas.drawOval(const Rect.fromLTWH(81, 64, 17, 8), p);
    canvas.drawArc(
      const Rect.fromLTWH(49, 62, 23, 17),
      0,
      math.pi,
      false,
      p
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    p.style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(55, 2, 12, 24), p..color = teal);
    canvas.drawOval(
      const Rect.fromLTWH(63, 4, 20, 11),
      p..color = const Color(0xFF75B892),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PipPainter oldDelegate) => oldDelegate.happy != happy;
}

class ToyTile extends StatelessWidget {
  const ToyTile({
    super.key,
    required this.letter,
    this.onTap,
    this.onTouch,
    this.onTouchCancel,
    this.correct = false,
    this.fixed = false,
    this.small = false,
  });
  final String letter;
  final VoidCallback? onTap, onTouch, onTouchCancel;
  final bool correct, fixed, small;
  @override
  Widget build(BuildContext context) {
    final color =
        letterColors[(int.tryParse(letter) ?? (letter.codeUnitAt(0) - 65))
                .clamp(0, 29) %
            letterColors.length];
    return Semantics(
      button: onTap != null,
      label:
          '${letter == '✿' ? 'Flower' : letter}${fixed
              ? ', stays here'
              : correct
              ? ', in place'
              : ''}',
      child: GestureDetector(
        onTap: onTap,
        onTapDown: onTouch == null ? null : (_) => onTouch!(),
        onTapCancel: onTouchCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.fromLTRB(2, 2, 2, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(small ? 7 : 12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(color, Colors.white, .28)!, color],
            ),
            border: Border.all(
              color: onTap != null ? Colors.white : color,
              width: onTap != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(color, ink, .28)!,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: ink.withValues(alpha: .18),
                offset: const Offset(0, 7),
                blurRadius: 4,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 3,
                left: 7,
                right: 7,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .48),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: letter == '✿'
                        ? Icon(
                            Icons.local_florist_rounded,
                            size: small ? 17 : 28,
                            color: teal,
                          )
                        : Text(
                            letter,
                            style: TextStyle(
                              height: 1,
                              fontSize: small ? 17 : 28,
                              fontWeight: FontWeight.w800,
                              color: ink,
                              shadows: const [
                                Shadow(
                                  color: Colors.white70,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              if (correct && !small)
                const Positioned(
                  right: 4,
                  bottom: 3,
                  child: Icon(Icons.check_rounded, size: 10, color: teal),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlphabetBoard extends StatefulWidget {
  const AlphabetBoard({
    super.key,
    required this.board,
    this.onMove,
    this.small = false,
  });
  final PuzzleBoard board;
  final ValueChanged<int>? onMove;
  final bool small;
  @override
  State<AlphabetBoard> createState() => _AlphabetBoardState();
}

class _AlphabetBoardState extends State<AlphabetBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cue;
  @override
  void initState() {
    super.initState();
    _cue =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 450),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _from = null);
          }
        });
  }

  int? _from;
  int _to = 0;
  PuzzleBoard get board => widget.board;
  bool get small => widget.small;
  ValueChanged<int>? get onMove => widget.onMove;

  void _touch(int index) {
    if (onMove == null || !board.canMove(index)) return;
    setState(() {
      _from = index;
      _to = board.blankIndex;
    });
    _cue.forward(from: 0);
  }

  void _cancelTouch() {
    _cue.stop();
    setState(() => _from = null);
  }

  @override
  void dispose() {
    _cue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(small ? 8 : 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEDD0A3), Color(0xFFC59C6E)],
      ),
      border: Border.all(color: const Color(0xFFF7DFB9), width: 3),
      boxShadow: const [
        BoxShadow(color: Color(0xFFA88058), offset: Offset(0, 8)),
        BoxShadow(
          color: Color(0x2529474C),
          blurRadius: 22,
          offset: Offset(0, 15),
        ),
      ],
    ),
    child: AspectRatio(
      aspectRatio: 5 / 6,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / 5, h = c.maxHeight / 6;
          return Stack(
            children: [
              for (var i = 0; i < 30; i++)
                Positioned(
                  left: i % 5 * w,
                  top: i ~/ 5 * h,
                  width: w,
                  height: h,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAE8A63).withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: board.tiles[i] == null
                        ? Center(
                            child: Icon(
                              Icons.touch_app_outlined,
                              color: cream.withValues(alpha: .7),
                              size: small ? 16 : 27,
                            ),
                          )
                        : null,
                  ),
                ),
              for (final letter in board.tiles.whereType<String>().where(
                (t) => t != PuzzleBoard.lockedEmptyTile,
              ))
                AnimatedPositioned(
                  key: ValueKey(letter),
                  duration: Duration(
                    milliseconds: MediaQuery.disableAnimationsOf(context)
                        ? 0
                        : 150,
                  ),
                  curve: Curves.easeOutCubic,
                  left: board.tiles.indexOf(letter) % 5 * w,
                  top: board.tiles.indexOf(letter) ~/ 5 * h,
                  width: w,
                  height: h,
                  child: ToyTile(
                    letter: board.displaySymbol(letter),
                    onTouch:
                        onMove != null &&
                            board.canMove(board.tiles.indexOf(letter))
                        ? () => _touch(board.tiles.indexOf(letter))
                        : null,
                    onTouchCancel: _cancelTouch,
                    small: small,
                    fixed: !board.isNumbers && (letter == 'Y' || letter == 'Z'),
                    correct: board.correctAt(board.tiles.indexOf(letter)),
                    onTap:
                        onMove != null &&
                            board.canMove(board.tiles.indexOf(letter))
                        ? () => onMove!(board.tiles.indexOf(letter))
                        : null,
                  ),
                ),
              if (_from != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: AnimatedBuilder(
                        animation: _cue,
                        builder: (context, _) {
                          final start = Offset(
                            (_from! % 5 + .5) * w,
                            (_from! ~/ 5 + .5) * h,
                          );
                          final end = Offset(
                            (_to % 5 + .5) * w,
                            (_to ~/ 5 + .5) * h,
                          );
                          final delta = end - start;
                          final reduced = MediaQuery.disableAnimationsOf(
                            context,
                          );
                          final progress = reduced
                              ? .5
                              : Curves.easeOutCubic.transform(_cue.value) * .8;
                          final position = Offset.lerp(start, end, progress)!;
                          final size = math.min(w, h) * .48;
                          final direction = delta.dx > 0
                              ? 'right'
                              : delta.dx < 0
                              ? 'left'
                              : delta.dy > 0
                              ? 'down'
                              : 'up';
                          return Stack(
                            children: [
                              Positioned(
                                left: position.dx - size / 2,
                                top: position.dy - size / 2,
                                width: size,
                                height: size,
                                child: Opacity(
                                  opacity: reduced ? 1 : (1 - _cue.value * .7),
                                  child: DecoratedBox(
                                    key: ValueKey('slide-$direction'),
                                    decoration: BoxDecoration(
                                      color: teal,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Transform.rotate(
                                      angle: math.atan2(delta.dy, delta.dx),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: size * .75,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              if (!board.isNumbers)
                Positioned(
                  left: w * 2,
                  top: h * 5,
                  width: w * 3,
                  height: h,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          board.isNumbers
                              ? 'One more → · One more ↓'
                              : 'Y & Z stay here',
                          style: TextStyle(
                            fontSize: small ? 9 : 11,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = 20,
  });
  final Widget child;
  final Color color;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: ink.withValues(alpha: .07)),
      boxShadow: [
        BoxShadow(
          color: ink.withValues(alpha: .04),
          offset: const Offset(0, 5),
          blurRadius: 12,
        ),
      ],
    ),
    child: child,
  );
}

/// Read-only view of the AI's actual active cells. Y/Z never move, so their
/// shelf is omitted here to keep each of the 25 active cells legible.
class LiveAiBoard extends StatelessWidget {
  const LiveAiBoard({super.key, required this.board});
  final PuzzleBoard board;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        "Pip's board, ${board.correctlyPlacedCount} of ${board.symbolCount} tiles in place",
    image: true,
    child: ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFCFAC80),
          borderRadius: BorderRadius.circular(10),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cell = constraints.maxWidth / 5;
            final rowHeight = constraints.maxHeight / board.playableRows;
            return Stack(
              children: [
                for (var i = 0; i < board.playableCells; i++)
                  Positioned(
                    left: i % 5 * cell,
                    top: i ~/ 5 * rowHeight,
                    width: cell,
                    height: rowHeight,
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB79068),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                for (final letter
                    in board.tiles
                        .take(board.playableCells)
                        .whereType<String>())
                  AnimatedPositioned(
                    key: ValueKey('ai-$letter'),
                    duration: Duration(
                      milliseconds: MediaQuery.disableAnimationsOf(context)
                          ? 0
                          : 280,
                    ),
                    curve: Curves.easeInOutCubic,
                    left: board.tiles.indexOf(letter) % 5 * cell,
                    top: board.tiles.indexOf(letter) ~/ 5 * rowHeight,
                    width: cell,
                    height: rowHeight,
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            letterColors[(int.tryParse(
                                      board.displaySymbol(letter),
                                    ) ??
                                    (letter.codeUnitAt(0) - 65)) %
                                letterColors.length],
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x44664C30),
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: FittedBox(
                        child: Text(
                          board.displaySymbol(letter),
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// Quiet, decorative bubbles stay behind controls and ignore all touches.
class _FloatingBubbles extends StatefulWidget {
  const _FloatingBubbles();
  @override
  State<_FloatingBubbles> createState() => _FloatingBubblesState();
}

class _FloatingBubblesState extends State<_FloatingBubbles>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      _motion.value = 0;
    } else {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(painter: _BubblePainter(_motion)),
      ),
    ),
  );
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.motion) : super(repaint: motion);
  final Animation<double> motion;
  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFEF8DB0),
      Color(0xFF71C7E8),
      Color(0xFFB39AE8),
      Color(0xFFFFC65B),
      Color(0xFF71CEAF),
    ];
    for (var i = 0; i < 22; i++) {
      final phase = motion.value * math.pi * 2 + i * 1.7;
      final radius = 5.0 + i % 5 * 3;
      final center = Offset(
        ((i * 137 + 12) % 997) / 997 * size.width + math.sin(phase) * 9,
        ((i * 193 + 35) % 991) / 991 * size.height + math.cos(phase) * 14,
      );
      final color = colors[i % colors.length];
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = color.withValues(alpha: .3),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
        center - Offset(radius * .3, radius * .3),
        radius * .2,
        Paint()..color = Colors.white.withValues(alpha: .8),
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.motion != motion;
}

class GameIcon extends StatelessWidget {
  const GameIcon({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .22),
    child: Image.asset(
      'assets/images/app-icon.png',
      width: size,
      height: size,
      semanticLabel: 'Slide & Sort app icon',
      filterQuality: FilterQuality.medium,
    ),
  );
}
