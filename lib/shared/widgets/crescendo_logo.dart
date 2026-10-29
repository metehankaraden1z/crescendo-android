import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// The crescendo "hairpin" mark, optionally followed by the wordmark.
class CrescendoLogo extends StatelessWidget {
  const CrescendoLogo({super.key, this.size = 24, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Crescendo',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(size: Size(size * 1.4, size), painter: const _HairpinPainter()),
          if (showWordmark) ...[
            SizedBox(width: size * 0.4),
            ExcludeSemantics(
              child: Text('Crescendo', style: CrText.display(size, color: CrColors.gold2)),
            ),
          ],
        ],
      ),
    );
  }
}

class _HairpinPainter extends CustomPainter {
  const _HairpinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CrColors.gold2
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.13
      ..strokeCap = StrokeCap.round;
    final tip = Offset(size.width * 3 / 28, size.height / 2);
    canvas.drawLine(tip, Offset(size.width * 25 / 28, size.height * 3 / 20), paint);
    canvas.drawLine(tip, Offset(size.width * 25 / 28, size.height * 17 / 20), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
