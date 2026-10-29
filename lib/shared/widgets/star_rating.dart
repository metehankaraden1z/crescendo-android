import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/tokens.dart';
import '../format.dart';

/// Five stars with half-star precision. [value] is 1–10 (null = not rated).
///
/// Interactive when [onChanged] is set: tap or drag across the stars to pick a
/// score, long-press to clear it (if [onClear] is set).
class StarRating extends StatefulWidget {
  const StarRating({super.key, required this.value, this.size = 22, this.onChanged, this.onClear});

  final num? value;
  final double size;
  final ValueChanged<int>? onChanged;
  final VoidCallback? onClear;

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  int? _preview;

  double get _width => widget.size * 5;

  int _valueAt(double dx) => ((dx / _width) * 10).ceil().clamp(1, 10);

  void _setPreview(double dx) {
    final value = _valueAt(dx);
    if (value != _preview) {
      HapticFeedback.selectionClick();
      setState(() => _preview = value);
    }
  }

  void _commit() {
    final value = _preview;
    setState(() => _preview = null);
    if (value != null) widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final shown = (_preview ?? widget.value ?? 0).toDouble();
    final stars = CustomPaint(
      size: Size(_width, widget.size),
      painter: _StarsPainter(
        fraction: shown / 10,
        highlight: _preview != null,
      ),
    );
    if (widget.onChanged == null) {
      return Semantics(
        label: widget.value == null ? 'Not rated' : '${fmtScore(widget.value)} out of 5 stars',
        child: ExcludeSemantics(child: stars),
      );
    }

    final current = widget.value?.round() ?? 0;
    return Semantics(
      slider: true,
      label: 'Rating',
      value: current == 0 ? 'Not rated' : '${fmtScore(current)} out of 5 stars',
      increasedValue: '${fmtScore(math.min(10, current + 1))} out of 5 stars',
      decreasedValue: '${fmtScore(math.max(1, current - 1))} out of 5 stars',
      onIncrease: () => widget.onChanged!(math.min(10, current + 1)),
      onDecrease: () => widget.onChanged!(math.max(1, current - 1)),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _setPreview(d.localPosition.dx),
          onTapUp: (_) => _commit(),
          onTapCancel: () => setState(() => _preview = null),
          onHorizontalDragStart: (d) => _setPreview(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => _setPreview(d.localPosition.dx),
          onHorizontalDragEnd: (_) => _commit(),
          onLongPress: widget.onClear == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  setState(() => _preview = null);
                  widget.onClear!();
                },
          // Extra vertical padding makes small stars easier to hit.
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: stars),
        ),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter({required this.fraction, required this.highlight});

  final double fraction;
  final bool highlight;

  Path _star(Offset center, double radius) {
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final r = k.isEven ? radius : radius * 0.48;
      final angle = -math.pi / 2 + k * math.pi / 5;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      k == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 5;
    final all = Path();
    for (var i = 0; i < 5; i++) {
      all.addPath(_star(Offset(cell * i + cell / 2, size.height / 2), cell * 0.47), Offset.zero);
    }
    canvas.drawPath(all, Paint()..color = CrColors.starEmpty);
    if (fraction <= 0) return;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * fraction, size.height));
    canvas.drawPath(all, Paint()..color = highlight ? CrColors.gold2 : CrColors.gold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.fraction != fraction || old.highlight != highlight;
}
