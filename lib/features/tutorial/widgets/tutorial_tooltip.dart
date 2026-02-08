import 'package:flutter/material.dart';

/// Tooltip widget for tutorial steps.
/// UX: User advances by tapping the highlighted target button (or Skip).
/// targetRect and containerSize are in screen (global) coordinates when used with OverlayEntry.
class TutorialTooltip extends StatelessWidget {
  final String message;
  final Rect targetRect;
  final Size containerSize;
  final VoidCallback? onSkip;

  const TutorialTooltip({
    super.key,
    required this.message,
    required this.targetRect,
    required this.containerSize,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    // Determine tooltip position (targetRect in screen coordinates)
    final hasSpaceAbove = targetRect.top > 200;
    final tooltipY = hasSpaceAbove
        ? targetRect.top - 180
        : targetRect.bottom + 20;

    // Center tooltip horizontally with the target
    final tooltipX = targetRect.center.dx - 150; // Half of tooltip width (300)

    // clamp(min, max) requires min <= max; ensure valid range for narrow/short screens
    const padding = 16.0;
    const tooltipWidth = 300.0;
    const tooltipMinHeight = 200.0;
    final maxLeft = containerSize.width - tooltipWidth - padding;
    final maxTop = containerSize.height - tooltipMinHeight;
    final leftClamped = tooltipX.clamp(
      padding <= maxLeft ? padding : maxLeft,
      padding <= maxLeft ? maxLeft : padding,
    );
    final topClamped = tooltipY.clamp(
      padding <= maxTop ? padding : maxTop,
      padding <= maxTop ? maxTop : padding,
    );

    // Use Align + Transform instead of Positioned to avoid requiring Stack as direct parent
    return Align(
      alignment: Alignment.topLeft,
      child: Transform.translate(
        offset: Offset(leftClamped, topClamped),
        child: IgnorePointer(
          ignoring: true,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                if (onSkip != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IgnorePointer(
                      ignoring: false,
                      child: TextButton(
                        onPressed: () {
                          onSkip?.call();
                        },
                        child: const Text(
                          'スキップ',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
