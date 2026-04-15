import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// A honeycomb (hexagonal) mosaic of images.
/// Used on the second onboarding page.
///
/// Layout (honeycomb pattern):
///   Row 0:   ⬡   ⬡
///   Row 1:  ⬡  ⬡  ⬡
///   Row 2:   ⬡   ⬡
class OnboardingImageHexagons extends StatelessWidget {
  const OnboardingImageHexagons({
    super.key,
    required this.images,
  });

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final hexSize = width * 0.27;
        final gap = 12.0;

        // Horizontal step between hex centers
        final hStep = hexSize + gap;
        // Vertical step (hexagons stack tighter than circles)
        final vStep = hexSize * 0.88 + gap;

        final centerX = width / 2;

        final row0Y = hexSize / 2;
        final row1Y = row0Y + vStep;
        final row2Y = row1Y + vStep;

        final totalHeight = row2Y + hexSize / 2;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Row 0: 2 hexagons ──────────────────────────
              _hexImage(images[0], hexSize,
                  cx: centerX - hStep / 2, cy: row0Y),
              _hexImage(images[1], hexSize,
                  cx: centerX + hStep / 2, cy: row0Y),

              // ── Row 1: 3 hexagons ──────────────────────────
              _hexImage(images[2], hexSize,
                  cx: centerX - hStep, cy: row1Y),
              _hexImage(images[3], hexSize * 1.08,
                  cx: centerX, cy: row1Y),
              _hexImage(images[4], hexSize,
                  cx: centerX + hStep, cy: row1Y),

              // ── Row 2: 2 hexagons ──────────────────────────
              _hexImage(images[5], hexSize,
                  cx: centerX - hStep / 2, cy: row2Y),
              if (images.length > 6)
                _hexImage(images[6], hexSize,
                    cx: centerX + hStep / 2, cy: row2Y),
            ],
          ),
        );
      },
    );
  }

  Widget _hexImage(String assetPath, double size,
      {required double cx, required double cy}) {
    return Positioned(
      left: cx - size / 2,
      top: cy - size / 2,
      width: size,
      height: size,
      child: ClipPath(
        clipper: _HexagonClipper(),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      ),
    );
  }
}

/// Clips a widget into a rounded hexagon shape.
class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    // Corner rounding radius
    final r = w * 0.08;

    // 6 vertices of a regular hexagon (flat-top orientation)
    final points = <Offset>[
      Offset(w * 0.25, 0),       // top-left
      Offset(w * 0.75, 0),       // top-right
      Offset(w, h * 0.5),        // right
      Offset(w * 0.75, h),       // bottom-right
      Offset(w * 0.25, h),       // bottom-left
      Offset(0, h * 0.5),        // left
    ];

    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final prev = points[(i - 1 + points.length) % points.length];

      // Direction vectors from current vertex toward neighbors
      final toPrev = Offset(
        prev.dx - current.dx,
        prev.dy - current.dy,
      );
      final toNext = Offset(
        next.dx - current.dx,
        next.dy - current.dy,
      );

      // Normalize and offset by radius
      final lenPrev = toPrev.distance;
      final lenNext = toNext.distance;
      final startPt = Offset(
        current.dx + toPrev.dx / lenPrev * r,
        current.dy + toPrev.dy / lenPrev * r,
      );
      final endPt = Offset(
        current.dx + toNext.dx / lenNext * r,
        current.dy + toNext.dy / lenNext * r,
      );

      if (i == 0) {
        path.moveTo(startPt.dx, startPt.dy);
      } else {
        path.lineTo(startPt.dx, startPt.dy);
      }

      path.quadraticBezierTo(current.dx, current.dy, endPt.dx, endPt.dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}