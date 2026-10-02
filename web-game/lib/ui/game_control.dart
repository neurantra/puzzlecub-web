import 'package:flutter/material.dart';

/// Shared touch, visible keyboard focus and screen-reader activation for cells.
class GameControl extends StatefulWidget {
  const GameControl({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
    this.selected = false,
    this.hint,
  });
  final String label;
  final String? hint;
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

  @override
  State<GameControl> createState() => _GameControlState();
}

class _GameControlState extends State<GameControl> {
  bool focused = false;
  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    hint: widget.hint,
    button: true,
    selected: widget.selected,
    enabled: widget.onTap != null,
    onTap: widget.onTap,
    focusable: widget.onTap != null,
    focused: focused,
    child: ExcludeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (value) => setState(() => focused = value),
          child: Container(
            foregroundDecoration: focused
                ? BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF175BB0),
                      width: 2.5,
                    ),
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    ),
  );
}
