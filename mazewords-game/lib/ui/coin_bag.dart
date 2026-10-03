import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'style.dart';

/// Shared Neurantra drawstring artwork. This balance is local to Maze Words.
class CoinBag extends StatelessWidget {
  const CoinBag({super.key, required this.coins, this.onTap});
  final int coins;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$coins coins${onTap == null ? '' : '. Open coin vault'}',
    button: onTap != null,
    excludeSemantics: true,
    child: Tooltip(
      message: onTap == null ? 'Coins' : 'Coin vault',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 42,
              child: CustomPaint(
                painter: CoinBagPainter(progress: 0, coins: 0),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E8CF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$coins',
                style: const TextStyle(
                  color: ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CoinBagPainter extends CustomPainter {
  final double progress;
  final int coins;
  CoinBagPainter({required this.progress, required this.coins});
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 42, s.height / 54);
    // Coins disappear behind the gathered neck, not in front of the bag.
    for (var i = 0; i < coins; i++) {
      final t = (progress - .1 - i / coins * .62) / .20;
      if (t <= 0 || t >= 1) continue;
      final x = 21 + math.sin(i * 2.4) * 11 * (1 - t);
      final y = -5 + 28 * t * t;
      final width = 2 + 5 * math.cos(t * math.pi * 2).abs();
      final oval = Rect.fromCenter(
        center: Offset(x, y),
        width: width,
        height: 7,
      );
      c.drawOval(oval, Paint()..color = const Color(0xffbb7e17));
      c.drawOval(oval.deflate(.7), Paint()..color = const Color(0xffffd76a));
      c.drawLine(
        Offset(x, y - 1.5),
        Offset(x, y + 1.5),
        Paint()
          ..color = const Color(0xffb67c19)
          ..strokeWidth = .8,
      );
    }
    final pulse = coins > 0 && progress > .3 && progress < .96
        ? math.sin((progress - .3) * math.pi * 16) * .035
        : 0.0;
    c.translate(21, 49);
    c.scale(1 + pulse, 1 - pulse);
    c.translate(-21, -49);
    c.drawOval(
      const Rect.fromLTWH(6, 47, 31, 5),
      Paint()
        ..color = const Color(0x25683b14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final bag = Path()
      ..moveTo(16, 21)
      ..cubicTo(12, 28, 4, 33, 5, 43)
      ..cubicTo(5, 53, 37, 53, 37, 43)
      ..cubicTo(38, 34, 29, 27, 26, 21)
      ..close();
    c.drawPath(
      bag,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xffa96d31),
            Color(0xffe7ba71),
            Color(0xffd9a558),
            Color(0xff9c5f2c),
          ],
          stops: [0, .25, .7, 1],
        ).createShader(const Rect.fromLTWH(5, 21, 32, 30)),
    );
    c.drawPath(
      bag,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = const Color(0xff8c592f),
    );
    c.drawPath(
      Path()
        ..moveTo(15, 24)
        ..quadraticBezierTo(9, 35, 11, 43)
        ..moveTo(27, 25)
        ..quadraticBezierTo(34, 36, 31, 46),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x55683b17),
    );
    // Folded fabric above the tightly gathered cord.
    final neck = Path()
      ..moveTo(16, 22)
      ..lineTo(12, 13)
      ..lineTo(18, 15)
      ..lineTo(22, 12)
      ..lineTo(26, 15)
      ..lineTo(31, 13)
      ..lineTo(26, 22)
      ..close();
    c.drawPath(neck, Paint()..color = const Color(0xffd9a65e));
    c.drawPath(
      neck,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = const Color(0xff976132),
    );
    final cord = Paint()
      ..color = const Color(0xff684224)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    c.drawPath(
      Path()
        ..moveTo(15, 22)
        ..quadraticBezierTo(21, 24, 28, 21)
        ..moveTo(24, 22)
        ..cubicTo(13, 16, 14, 27, 24, 22)
        ..cubicTo(34, 16, 35, 27, 24, 22)
        ..quadraticBezierTo(25, 27, 29, 30)
        ..moveTo(24, 23)
        ..quadraticBezierTo(22, 28, 23, 30),
      cord,
    );
    c.drawCircle(
      const Offset(24, 22),
      1.6,
      Paint()..color = const Color(0xff59371f),
    );
    // Small stitched coin emblem, with the balance deliberately outside.
    c.drawCircle(
      const Offset(21, 38),
      6,
      Paint()..color = const Color(0xffedc579),
    );
    c.drawCircle(
      const Offset(21, 38),
      5.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = const Color(0xffa67030),
    );
    c.drawLine(
      const Offset(21, 35),
      const Offset(21, 41),
      cord..strokeWidth = 1,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(CoinBagPainter old) =>
      progress != old.progress || coins != old.coins;
}
