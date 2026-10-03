import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/geometry.dart';

/// Each arrow selects an exact reachable landing, even where footprints overlap.
class LandingArrows extends StatefulWidget {
  final List<Piece> landings;
  final Rect bounds;
  final double jarWidth;
  final bool motion;
  final Piece? recommended;
  final ValueChanged<Piece> onChoose;
  const LandingArrows({
    super.key,
    required this.landings,
    required this.bounds,
    required this.jarWidth,
    required this.motion,
    this.recommended,
    required this.onChoose,
  });

  @override
  State<LandingArrows> createState() => _LandingArrowsState();
}

class _LandingArrowsState extends State<LandingArrows>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.motion) _animation.repeat();
  }

  @override
  void didUpdateWidget(LandingArrows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.motion != oldWidget.motion) {
      if (widget.motion) {
        _animation.repeat();
      } else {
        _animation.stop();
        _animation.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  bool _isHint(Piece p) =>
      widget.recommended != null &&
      p.id == widget.recommended!.id &&
      (p.x - widget.recommended!.x).abs() < epsilon &&
      (p.y - widget.recommended!.y).abs() < epsilon;

  @override
  Widget build(BuildContext context) {
    final scale = widget.bounds.width / widget.jarWidth;
    // Half-cell destinations remain individually tappable on narrow jars.
    final width = math.min(28.0, scale * .5);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Stack(
        children: [
          for (final p in widget.landings.where(
            (p) => widget.recommended == null || _isHint(p),
          ))
            Positioned(
              left: widget.bounds.left + (p.x + p.w / 2) * scale - width / 2,
              top: widget.bounds.top + (p.y + p.h / 2) * scale - 24,
              width: width,
              height: 40,
              child: Semantics(
                button: true,
                label: '${_isHint(p) ? 'Hint: ' : ''}Drop at column ${p.x + 1}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onChoose(p),
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      widget.motion
                          ? 4 * math.sin(_animation.value * math.pi * 2)
                          : 0,
                    ),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      size: math.min(24, width + 3),
                      color: _isHint(p)
                          ? const Color(0xffad6200)
                          : const Color(0xff386978),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
