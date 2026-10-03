import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/geometry.dart';
import '../services/services.dart';
import 'art.dart';
import 'picture_art.dart';
import 'wooden_jar.dart';

const tutorialSeenKey = 'jar.tutorial.seen.v1';

Future<void> showTutorial(
  BuildContext context, {
  bool sound = false,
  String pictureAsset = PictureArt.asset,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _Tutorial(sound: sound, pictureAsset: pictureAsset),
);

class _Tutorial extends StatefulWidget {
  final bool sound;
  final String pictureAsset;
  const _Tutorial({required this.sound, required this.pictureAsset});
  @override
  State<_Tutorial> createState() => _TutorialState();
}

class _TutorialState extends State<_Tutorial>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  Sounds? sounds;
  late bool audible = widget.sound;
  int lastCue = -1;
  bool resume = false;
  static const titles = [
    'Choose a piece',
    'Follow the arrows',
    'Slide into place',
    'Turn a triangle',
    'Fit the slanted edges',
    'Room to rethink',
    'Need a hint?',
    'Everything fits.',
  ];
  static const captions = [
    'An empty jar. Different shapes. Tap a pile to begin.',
    'Tap an arrow to place your block—or drag it in.',
    'Drag clear blocks sideways. Free space below? They fall into it.',
    'Tap Rotate to turn a triangle before placing it.',
    'Triangles and parallelograms fit along their slanted edges.',
    'Tap a clear block to take it out. Undo is free too.',
    'Hint highlights a suggested placement. It costs 10 coins or a rewarded ad when available.',
    'Fill every gap! Optional picture themes reveal an image. Shapes still decide the fit.',
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(WoodMaterial.load().catchError((Object _) {}));
    unawaited(
      PictureArt.load(asset: widget.pictureAsset).catchError((Object _) {}),
    );
    clock.addListener(_audio);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (clock.value == 0 && !MediaQuery.disableAnimationsOf(context)) {
      clock.forward();
    }
  }

  void _audio() {
    final phase = clock.value * 8;
    final step = phase.floor().clamp(0, 7);
    if (phase - step < .72 || step == lastCue) return;
    lastCue = step;
    if (audible) {
      unawaited(
        (sounds ??= Sounds()).play(
          step == 7
              ? 'win'
              : step == 5
              ? 'lift'
              : 'click',
          true,
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      resume = resume || clock.isAnimating;
      clock.stop();
      sounds?.dispose();
      sounds = null;
    } else if (resume) {
      resume = false;
      clock.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    clock.dispose();
    sounds?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
    clipBehavior: Clip.antiAlias,
    child: AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final step = (clock.value * 8).floor().clamp(0, 7);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'YOUR FIRST PERFECT FIT',
                      style: TextStyle(
                        color: purple,
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: audible ? 'Mute tutorial' : 'Unmute tutorial',
                    onPressed: () => setState(() {
                      audible = !audible;
                      if (!audible) {
                        sounds?.dispose();
                        sounds = null;
                      }
                    }),
                    icon: Icon(
                      audible
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                    ),
                  ),
                ],
              ),
              Text(
                titles[step],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${step + 1} / 8 · 24-second guided demo',
                style: const TextStyle(fontSize: 11, color: ink),
              ),
              Semantics(
                label: 'Animated example: ${titles[step]}',
                image: true,
                child: SizedBox(
                  height: (MediaQuery.sizeOf(context).height * .48).clamp(
                    280.0,
                    420.0,
                  ),
                  width: 350,
                  child: CustomPaint(
                    painter: TutorialPainter(
                      step,
                      (clock.value * 8 - step).clamp(0, 1),
                    ),
                  ),
                ),
              ),
              Text(captions[step], textAlign: TextAlign.center),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: clock.value, color: purple),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Skip'),
                  ),
                  IconButton(
                    tooltip: clock.isAnimating
                        ? 'Pause tutorial'
                        : 'Play tutorial',
                    onPressed: () => setState(() {
                      if (clock.isAnimating) {
                        clock.stop();
                      } else {
                        if (clock.isCompleted) {
                          lastCue = -1;
                          clock.value = 0;
                        }
                        clock.forward();
                      }
                    }),
                    icon: Icon(
                      clock.isAnimating ? Icons.pause : Icons.play_arrow,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      lastCue = -1;
                      clock.forward(from: 0);
                    },
                    child: const Text('Replay'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Let’s play'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Uses the same glass, wood, bevels and destination-based picture renderer as
/// the game. This isolated example never touches the player's session.
class TutorialPainter extends CustomPainter {
  final int step;
  final double t;
  TutorialPainter(this.step, this.t)
    : super(
        repaint: Listenable.merge([WoodMaterial.texture, PictureArt.image]),
      );
  static Piece tile(int id, double x, double y) => Piece(
    id: id,
    x: x,
    y: y,
    w: 2,
    h: 1,
    points: const [Offset.zero, Offset(2, 0), Offset(2, 1), Offset(0, 1)],
  );
  static const triangle = Piece(
    id: 2,
    x: 0,
    y: 2,
    w: 2,
    h: 2,
    points: [Offset.zero, Offset(2, 2), Offset(0, 2)],
  );
  static const parallelogram = Piece(
    id: 3,
    x: 0,
    y: 2,
    w: 4,
    h: 2,
    points: [Offset.zero, Offset(2, 0), Offset(4, 2), Offset(2, 2)],
  );
  static const rightTriangle = Piece(
    id: 4,
    x: 2,
    y: 2,
    w: 2,
    h: 2,
    points: [Offset.zero, Offset(2, 0), Offset(2, 2)],
  );
  static final puzzle = Puzzle(
    number: 1,
    title: 'A picture takes shape',
    w: 4,
    h: 5,
    pieces: [
      tile(0, 2, 4),
      tile(1, 0, 4),
      triangle,
      parallelogram,
      rightTriangle,
      tile(5, 0, 1),
      tile(6, 2, 1),
      tile(7, 0, 0),
      tile(8, 2, 0),
    ],
  );

  /// Completed stages form a continuous, physically valid build from empty.
  List<Piece> get demoBoard {
    final board = <Piece>[];
    void drop(Piece p, double start, double end) {
      final u = ease(start, end);
      if (u > 0) board.add(p.at(p.x, -p.h + (p.y + p.h) * u));
    }

    if (step == 1) drop(tile(0, 0, 4), .18, .72);
    if (step == 2) {
      final p = tile(0, 0, 4);
      board.add(slidePiece([p], p, Offset(2 * ease(.12, .72), 4), 4, 5));
    }
    if (step >= 3) board.add(tile(0, 2, 4));
    if (step == 3) {
      drop(tile(1, 0, 4), 0, .18);
      drop(triangle, .45, .78);
    }
    if (step >= 4) board.addAll([tile(1, 0, 4), triangle]);
    if (step == 4) drop(parallelogram, .18, .72);
    if (step == 5) {
      if (t < .45) {
        board.add(parallelogram.at(0, 2 - 4 * ease(.12, .45)));
      } else {
        drop(parallelogram, .5, .8);
      }
    }
    if (step >= 6) board.add(parallelogram);
    if (step == 6) drop(rightTriangle, .4, .75);
    if (step == 7) {
      board.add(rightTriangle);
      for (int i = 0; i < 4; i++) {
        drop(puzzle.pieces[5 + i], i * .14, i * .14 + .18);
      }
    }
    return board;
  }

  double ease(double start, double end) => Curves.easeInOutCubic.transform(
    ((t - start) / (end - start)).clamp(0, 1),
  );
  @override
  void paint(Canvas canvas, Size size) {
    final jarSize = Size(size.width, size.height - 86);
    final bounds = WoodenJarPainter.bounds(jarSize, puzzle);
    final unit = bounds.width / 4;
    final board = demoBoard;
    WoodenJarPainter(
      puzzle,
      board,
      null,
      0,
      pictureClues: true,
      showReference: false,
    ).paint(canvas, jarSize);
    final tray = Rect.fromLTWH(4, size.height - 83, size.width - 8, 80);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tray, const Radius.circular(14)),
      Paint()..color = const Color(0xffe4daf2),
    );
    final shapes = [tile(0, 0, 0), triangle, parallelogram];
    final cardWidth = (tray.width - 20) / 3;
    final cards = <Rect>[];
    for (int i = 0; i < shapes.length; i++) {
      final card = Rect.fromLTWH(
        tray.left + 5 + i * (cardWidth + 5),
        tray.top + 5,
        cardWidth,
        70,
      );
      cards.add(card);
      canvas.drawRRect(
        RRect.fromRectAndRadius(card, const Radius.circular(10)),
        Paint()..color = Colors.white,
      );
      canvas.save();
      canvas.translate(card.center.dx, card.top + 27);
      if (step == 3 && i == 1) {
        canvas.rotate(-math.pi / 2 * (1 - ease(.12, .4)));
      }
      canvas.translate(-cardWidth / 2 + 4, -23);
      WoodenPiecePainter(shapes[i]).paint(canvas, Size(cardWidth - 8, 46));
      canvas.restore();
      final text = TextPainter(
        text: TextSpan(
          text: ['Rectangle', 'Triangle', 'Parallelogram'][i],
          style: const TextStyle(
            fontSize: 9,
            fontFamily: 'Roboto',
            color: ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: cardWidth - 4);
      text.paint(
        canvas,
        Offset(card.center.dx - text.width / 2, card.bottom - 18),
      );
    }
    final iconPoint = Offset(size.width - 40, bounds.top + 4);
    if (step == 3 || step == 5 || step == 6) {
      final icon = step == 3
          ? Icons.rotate_right
          : step == 5
          ? Icons.undo
          : Icons.lightbulb_outline;
      final text = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            fontSize: 26,
            color: purple,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, iconPoint);
    }
    void finger(Offset at) {
      canvas.drawCircle(
        at,
        12,
        Paint()..color = Colors.white.withValues(alpha: .85),
      );
      canvas.drawCircle(
        at,
        12,
        Paint()
          ..color = purple
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(at, 3, Paint()..color = purple);
    }

    if (step == 0) {
      finger(cards.first.center + Offset(12, math.sin(t * math.pi * 4) * 3));
    }
    if (step <= 1 && (step == 0 ? t > .4 : t < .25)) {
      for (final x in [1.0, 3.0]) {
        final at =
            bounds.topLeft +
            Offset(x, 4.35 + math.sin(t * math.pi * 6) * .12) * unit;
        final path = Path()
          ..moveTo(at.dx, at.dy - 9)
          ..lineTo(at.dx, at.dy + 6)
          ..moveTo(at.dx - 5, at.dy)
          ..lineTo(at.dx, at.dy + 6)
          ..lineTo(at.dx + 5, at.dy);
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xff169e9b)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    if (step == 2) {
      finger(bounds.topLeft + Offset(board.first.x + 1, 4.5) * unit);
    }
    if (step == 3 && t < .5) {
      finger(iconPoint + const Offset(13, 16));
    }
    if (step == 5 && t < .3) finger(bounds.topLeft + Offset(2, 3) * unit);
    if (step == 6 && t < .4) {
      final at =
          bounds.topLeft + Offset(3.4, 2.6 + math.sin(t * 18) * .12) * unit;
      final arrow = Path()
        ..moveTo(at.dx, at.dy - 12)
        ..lineTo(at.dx, at.dy + 6)
        ..lineTo(at.dx - 5, at.dy)
        ..moveTo(at.dx, at.dy + 6)
        ..lineTo(at.dx + 5, at.dy);
      canvas.drawPath(
        arrow,
        Paint()
          ..color = const Color(0xffd29a15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (step == 7 && t > .72) {
      for (int i = 0; i < 14; i++) {
        final angle = i * math.pi * 2 / 14;
        final center =
            bounds.center +
            Offset(
              math.cos(angle) * (bounds.width / 2 + 12),
              math.sin(angle) * (bounds.height / 2 + 12),
            );
        canvas.drawCircle(
          center,
          2 + math.sin(t * 8 + i).abs() * 2,
          Paint()
            ..color = [
              purple,
              const Color(0xffffbb45),
              const Color(0xff169e9b),
            ][i % 3],
        );
      }
    }
  }

  @override
  bool shouldRepaint(TutorialPainter old) => old.step != step || old.t != t;
}
