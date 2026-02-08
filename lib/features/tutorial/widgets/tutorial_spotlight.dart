import 'package:flutter/material.dart';

/// Custom painter for tutorial spotlight effect
class TutorialSpotlight extends CustomPainter {
  final Rect targetRect;
  final double borderRadius;
  final Color overlayColor;

  TutorialSpotlight({
    required this.targetRect,
    this.borderRadius = 12.0,
    this.overlayColor = const Color(0xCC000000), // 80% opacity black
  });

  /// Expand rect slightly so the hole is easier to tap and absorbs small offset errors
  static const double _expandPixels = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    // Create a path that covers the entire screen
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Expand target rect slightly for easier tap and offset tolerance
    final expandedRect = targetRect.inflate(_expandPixels);
    // Clamp to overlay bounds (intersect with full rect)
    final clampedRect = expandedRect.intersect(Rect.fromLTWH(0, 0, size.width, size.height));
    if (clampedRect.isEmpty) return;

    // Create a rounded rectangle for the spotlight hole
    final spotlightPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          clampedRect,
          Radius.circular(borderRadius),
        ),
      );

    // Use PathOperation.difference to cut out the spotlight area
    final finalPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      spotlightPath,
    );

    canvas.drawPath(finalPath, paint);

    // Draw a subtle border around the spotlight
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        clampedRect,
        Radius.circular(borderRadius),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(TutorialSpotlight oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.overlayColor != overlayColor;
  }
}
