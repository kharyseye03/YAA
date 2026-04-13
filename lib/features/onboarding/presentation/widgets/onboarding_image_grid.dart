import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// A staggered mosaic grid of images with rounded corners.
/// Images in each row are vertically offset to create a
/// brickwork / masonry effect matching the Figma design.
class OnboardingImageGrid extends StatelessWidget {
  const OnboardingImageGrid({
    super.key,
    required this.images,
  });

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final spacing = 8.0;
        final colWidth = (width - spacing * 2) / 3;
        final rowHeight = colWidth * 1.25;

        // Vertical offsets per column to create the staggered effect
        // Row 1: left=0, center=offset down, right=0
        // Row 2: left=offset down, center=0, right=offset down
        final staggerOffset = rowHeight * 0.18;
        final totalHeight = rowHeight * 2 + spacing + staggerOffset;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Row 1 ──────────────────────────────────────
              // Left — starts at top
              _buildImage(
                images[0],
                left: 0,
                top: 0,
                width: colWidth,
                height: rowHeight,
              ),
              // Center — shifted down
              _buildImage(
                images[1],
                left: colWidth + spacing,
                top: staggerOffset,
                width: colWidth,
                height: rowHeight,
              ),
              // Right — starts at top
              _buildImage(
                images[2],
                left: (colWidth + spacing) * 2,
                top: 0,
                width: colWidth,
                height: rowHeight,
              ),

              // ── Row 2 ──────────────────────────────────────
              // Left — shifted down
              _buildImage(
                images[3],
                left: 0,
                top: rowHeight + spacing + staggerOffset,
                width: colWidth,
                height: rowHeight,
              ),
              // Center — aligns higher
              _buildImage(
                images[4],
                left: colWidth + spacing,
                top: rowHeight + spacing + staggerOffset * 1.9,                width: colWidth,
                height: rowHeight,
              ),
              // Right — shifted down
              _buildImage(
                images[5],
                left: (colWidth + spacing) * 2,
                top: rowHeight + spacing + staggerOffset,
                width: colWidth,
                height: rowHeight,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(
      String assetPath, {
        required double left,
        required double top,
        required double width,
        required double height,
      }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: width,
          height: height,
        ),
      ),
    );
  }
}