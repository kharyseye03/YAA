import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// A diamond (rotated 45°) mosaic of images.
/// Used on the last onboarding page.
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
        // Diamond size — fits ~3 across with spacing
        final diamondSize = width * 0.28;
        final gap = diamondSize * 0.15;
        final totalHeight = diamondSize * 3.5;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Row 0 (top) — 2 diamonds
              _diamond(images[0], diamondSize,
                  x: width * 0.25, y: 0),
              _diamond(images[1], diamondSize,
                  x: width * 0.58, y: 0),

              // Row 1 (middle) — 3 diamonds
              _diamond(images[2], diamondSize,
                  x: width * 0.08, y: diamondSize * 0.75 + gap),
              _diamond(images[3], diamondSize * 1.05,
                  x: width * 0.40, y: diamondSize * 0.75 + gap),
              _diamond(images[4], diamondSize,
                  x: width * 0.72, y: diamondSize * 0.75 + gap),

              // Row 2 (bottom) — 2 diamonds
              _diamond(images[5], diamondSize,
                  x: width * 0.22, y: (diamondSize * 0.75 + gap) * 2),
              _diamond(images[6], diamondSize,
                  x: width * 0.55, y: (diamondSize * 0.75 + gap) * 2),
            ],
          ),
        );
      },
    );
  }

  Widget _diamond(String assetPath, double size,
      {required double x, required double y}) {
    return Positioned(
      left: x - size / 2,
      top: y,
      child: Transform.rotate(
        angle: math.pi / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          child: SizedBox(
            width: size,
            height: size,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Transform.scale(
                scale: 1.45,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}