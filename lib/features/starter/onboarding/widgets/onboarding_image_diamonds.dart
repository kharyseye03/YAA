import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimens.dart';

/// A diamond (rotated 45°) mosaic of images.
/// Used on the last onboarding page.
/// Diamonds are centered and do NOT touch screen edges.
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

        // Smaller diamond size to avoid touching edges
        final size = width * 0.21;
        final diagonal = size * math.sqrt2;
        final gap = 16.0;

        // Vertical step between rows (stacked tighter)
        final vStep = diagonal / 2 + gap;

        final centerX = width / 2;

        // Horizontal step — reduced to keep diamonds away from edges
        final hStep = diagonal + gap;

        // 4 rows for better vertical spread
        final row0Y = diagonal / 2 + gap;
        final row1Y = row0Y + vStep;
        final row2Y = row1Y + vStep;
        final row3Y = row2Y + vStep;

        final totalHeight = row3Y + diagonal / 2 + gap;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Row 0: 2 diamonds ──────────────────────────
              _diamond(images[0], size,
                  cx: centerX - hStep * 0.55, cy: row0Y),
              _diamond(images[1], size,
                  cx: centerX + hStep * 0.55, cy: row0Y),

              // ── Row 1: 3 diamonds ──────────────────────────
              _diamond(images[2], size,
                  cx: centerX - hStep, cy: row1Y),
              _diamond(images[3], size * 1.1,
                  cx: centerX, cy: row1Y),
              _diamond(images[4], size,
                  cx: centerX + hStep, cy: row1Y),

              // ── Row 2: 2 diamonds ──────────────────────────
              _diamond(images[5], size,
                  cx: centerX - hStep * 0.55, cy: row2Y),
              _diamond(images[6], size,
                  cx: centerX + hStep * 0.55, cy: row2Y),

              // ── Row 3: 1 diamond (centered) ────────────────
              if (images.length > 7)
                _diamond(images[7], size, cx: centerX, cy: row3Y),
            ],
          ),
        );
      },
    );
  }

  Widget _diamond(String assetPath, double size,
      {required double cx, required double cy}) {
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