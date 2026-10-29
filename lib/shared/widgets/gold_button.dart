import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// The primary call-to-action: a gold pill that shrinks slightly when pressed.
class GoldButton extends StatefulWidget {
  const GoldButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed; // null = disabled

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: CrColors.goldGradient,
                borderRadius: BorderRadius.circular(CrRadius.pill),
                boxShadow: CrShadow.goldGlow,
              ),
              child: Text(
                widget.label,
                style: CrText.body(size: 17, weight: FontWeight.w600, color: CrColors.onGold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
