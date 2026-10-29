import 'package:flutter/material.dart';

import '../../core/theme/typography.dart';
import '../format.dart';

/// Album art from the Cover Art Archive, over a colourful initials placeholder
/// that stays visible when an album has no cover.
class CoverImage extends StatelessWidget {
  const CoverImage({super.key, required this.albumId, required this.title, this.size = 250, this.radius = 10});

  final String albumId;
  final String title;
  final int size; // 250 or 500
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [hueColor(title, lightness: 0.42), hueColor('$title·', lightness: 0.16)],
                ),
              ),
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: FittedBox(
                    child: Text(initials(title), style: CrText.display(40, color: const Color(0xD9FFFFFF))),
                  ),
                ),
              ),
            ),
            Image.network(
              'https://coverartarchive.org/release-group/$albumId/front-$size',
              fit: BoxFit.cover,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: child,
              ),
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
