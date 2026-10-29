import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'ghost_button.dart';

/// Gold equaliser bars: the loading indicator.
class EqLoader extends StatefulWidget {
  const EqLoader({super.key, this.label});

  final String? label;

  @override
  State<EqLoader> createState() => _EqLoaderState();
}

class _EqLoaderState extends State<EqLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 5; i++)
                  Container(
                    width: 6,
                    height: 8 + 28 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi + i * 0.9)),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(color: CrColors.gold, borderRadius: BorderRadius.circular(3)),
                  ),
              ],
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: CrSpace.lg),
            Text(widget.label!, style: CrText.body(size: 14, color: CrColors.muted), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CrSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hit a wrong note.', style: CrText.display(28), textAlign: TextAlign.center),
            const SizedBox(height: CrSpace.md),
            Text(message, style: CrText.body(size: 15, color: CrColors.muted), textAlign: TextAlign.center),
            const SizedBox(height: CrSpace.xl),
            GhostButton(label: 'Try again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// Brief message at the bottom of the screen.
void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(
        message,
        style: CrText.body(size: 14, weight: FontWeight.w600, color: error ? CrColors.danger : CrColors.text),
      ),
      backgroundColor: CrColors.surface3,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CrRadius.sm),
        side: BorderSide(color: error ? CrColors.danger.withValues(alpha: 0.5) : CrColors.line2),
      ),
      duration: const Duration(seconds: 3),
    ));
}

/// Eyebrow + heading used at the top of each section.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: CrSpace.xxl, bottom: CrSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(), style: CrText.eyebrow()),
          const SizedBox(height: CrSpace.sm),
          Text(title, style: CrText.display(26, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
