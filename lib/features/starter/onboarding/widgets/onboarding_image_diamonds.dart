import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// A diamond (rotated 45°) mosaic of images.
/// Used on the last onboarding page.
///
/// Layout (3 rows, honeycomb pattern):
///   Row 0:     ◇   ◇
///   Row 1:   ◇   ◇   ◇
///   Row 2:     ◇   ◇
class OnboardingImageDiamonds extends StatelessWidget {
  const OnboardingImageDiamonds({
    super.key,
    required this.images,
  });

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Diamond square size (before rotation)
        final size = width * 0.24;
        // The diagonal of the diamond after rotation = size * sqrt(2)
        final diagonal = size * math.sqrt2;
        // Spacing between diamonds
        final gap = 24.0;

        // After rotation, the diamond occupies a diagonal x diagonal bounding box
        // Horizontal step between centers in same row
        final hStep = diagonal + gap;
        // Vertical step between row centers
        final vStep = diagonal / 2 + gap / 2;

        // Center the grid horizontally
        // Row with 3 diamonds: spans 2 * hStep
        // Row with 2 diamonds: spans 1 * hStep, offset by hStep/2
        final centerX = width / 2;

        // Row centers (y positions)
        final row0Y = diagonal / 2;
        final row1Y = row0Y + vStep;
        final row2Y = row1Y + vStep;

        final totalHeight = row2Y + diagonal / 2;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Row 0: 2 diamonds (centered) ───────────────
              _diamond(images[0], size,
                  cx: centerX - hStep / 2, cy: row0Y),
              _diamond(images[1], size,
                  cx: centerX + hStep / 2, cy: row0Y),

              // ── Row 1: 3 diamonds ──────────────────────────
              _diamond(images[2], size,
                  cx: centerX - hStep, cy: row1Y),
              _diamond(images[3], size * 1.05,
                  cx: centerX, cy: row1Y),
              _diamond(images[4], size,
                  cx: centerX + hStep, cy: row1Y),

              // ── Row 2: 2 diamonds (centered) ───────────────
              _diamond(images[5], size,
                  cx: centerX - hStep / 2, cy: row2Y),
              _diamond(images[6], size,
                  cx: centerX + hStep / 2, cy: row2Y),
            ],
          ),
        );
      },
    );
  }

  /// Builds a single diamond image positioned by its center (cx, cy).
  Widget _diamond(String assetPath, double size,
      {required double cx, required double cy}) {
    // The rotated diamond's bounding box is size * sqrt(2)
    final diagonal = size * math.sqrt2;

    return Positioned(
      left: cx - diagonal / 2,
      top: cy - diagonal / 2,
      width: diagonal,
      height: diagonal,
      child: Center(
        child: Transform.rotate(
          angle: math.pi / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: SizedBox(
              width: size,
              height: size,
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Transform.scale(
                  scale: 1.42,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}