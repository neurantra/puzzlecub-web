import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small vector flags keep the language menu consistent offline on every OS.
class LanguageFlag extends StatelessWidget {
  const LanguageFlag(this.language, {super.key});
  final String language;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: const Size(36, 24),
      painter: _FlagPainter(language),
    ),
  );
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter(this.language);
  final String language;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(bounds, const Radius.circular(3)));
    void band(double y, double height, Color color) => canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, height),
      Paint()..color = color,
    );
    if (language == 'fr' || language == 'it') {
      band(0, size.height, Colors.white);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width / 3, size.height),
        Paint()..color = Color(language == 'it' ? 0xFF009246 : 0xFF002654),
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width * 2 / 3, 0, size.width / 3, size.height),
        Paint()..color = const Color(0xFFED2939),
      );
    } else if (language == 'nl') {
      band(0, size.height / 3, const Color(0xFFAE1C28));
      band(size.height / 3, size.height / 3, Colors.white);
      band(size.height * 2 / 3, size.height / 3, const Color(0xFF21468B));
    } else if (language == 'de') {
      band(0, size.height / 3, Colors.black);
      band(size.height / 3, size.height / 3, const Color(0xFFDD0000));
      band(size.height * 2 / 3, size.height / 3, const Color(0xFFFFCE00));
    } else if (language == 'bn') {
      band(0, size.height, const Color(0xFF006A4E));
      canvas.drawCircle(
        Offset(size.width * .45, size.height * .5),
        size.height * .30,
        Paint()..color = const Color(0xFFF42A41),
      );
    } else if (language == 'ja') {
      band(0, size.height, Colors.white);
      canvas.drawCircle(
        bounds.center,
        size.height * .30,
        Paint()..color = const Color(0xFFBC002D),
      );
    } else if (language == 'pt-BR') {
      band(0, size.height, const Color(0xFF009739));
      final diamond = Path()
        ..moveTo(size.width * .5, size.height * .1)
        ..lineTo(size.width * .92, size.height * .5)
        ..lineTo(size.width * .5, size.height * .9)
        ..lineTo(size.width * .08, size.height * .5)
        ..close();
      canvas.drawPath(diamond, Paint()..color = const Color(0xFFFEDD00));
      final circle = Rect.fromCircle(
        center: bounds.center,
        radius: size.height * .26,
      );
      canvas.drawOval(circle, Paint()..color = const Color(0xFF012169));
      canvas.save();
      canvas.clipPath(Path()..addOval(circle));
      final stripe = Path()
        ..moveTo(circle.left, circle.center.dy - 2)
        ..quadraticBezierTo(
          circle.center.dx,
          circle.center.dy - 3,
          circle.right,
          circle.center.dy + 2,
        );
      canvas.drawPath(
        stripe,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      for (var i = 0; i < 9; i++) {
        canvas.drawCircle(
          Offset(
            circle.left + 2 + (i % 3) * 2.5,
            circle.center.dy + 1 + (i ~/ 3) * 1.8,
          ),
          .22,
          Paint()..color = Colors.white,
        );
      }
      canvas.restore();
    } else if (language == 'es') {
      band(0, size.height, const Color(0xFFAA151B));
      band(size.height / 4, size.height / 2, const Color(0xFFF1BF00));
    } else if ([
      'ta',
      'hi',
      'te',
      'kn',
      'ml',
      'gu',
      'mr',
      'pa',
    ].contains(language)) {
      band(0, size.height / 3, const Color(0xFFFF9933));
      band(size.height / 3, size.height / 3, Colors.white);
      band(size.height * 2 / 3, size.height / 3, const Color(0xFF138808));
      final center = bounds.center, r = size.height * .135;
      final blue = Paint()
        ..color = const Color(0xFF000080)
        ..strokeWidth = .55
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, r, blue);
      for (var i = 0; i < 24; i++) {
        final angle = i * math.pi / 12;
        canvas.drawLine(
          center,
          center + Offset(math.cos(angle) * r, math.sin(angle) * r),
          blue,
        );
      }
    } else {
      band(0, size.height, Colors.white);
      for (var i = 0; i < 13; i += 2) {
        band(i * size.height / 13, size.height / 13, const Color(0xFFB22234));
      }
      final canton = Rect.fromLTWH(
        0,
        0,
        size.width * .42,
        size.height * 7 / 13,
      );
      canvas.drawRect(canton, Paint()..color = const Color(0xFF3C3B6E));
      for (var row = 0; row < 9; row++) {
        final count = row.isEven ? 6 : 5;
        for (var col = 0; col < count; col++) {
          final center = Offset(
            (col + (row.isEven ? 0.5 : 1)) * canton.width / 6,
            (row + .5) * canton.height / 9,
          );
          final star = Path();
          for (var i = 0; i < 10; i++) {
            final a = -math.pi / 2 + i * math.pi / 5, r = i.isEven ? 0.6 : 0.25;
            final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
            if (i == 0) {
              star.moveTo(p.dx, p.dy);
            } else {
              star.lineTo(p.dx, p.dy);
            }
          }
          canvas.drawPath(star..close(), Paint()..color = Colors.white);
        }
      }
    }
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(3)),
      Paint()
        ..color = const Color(0x22000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.language != language;
}
