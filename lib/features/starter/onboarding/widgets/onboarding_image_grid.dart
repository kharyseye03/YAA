import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';

/// A staggered mosaic grid of images with rounded corners.
/// Supports both asset and network images via [useNetwork].
class OnboardingImageGrid extends StatelessWidget {
  const OnboardingImageGrid({
    super.key,
    required this.images,
    this.useNetwork = false,
  });

  final List<String> images;
  final bool useNetwork;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final spacing = 8.0;
        final colWidth = (width - spacing * 2) / 3;
        final rowHeight = colWidth * 1.25;

        final staggerOffset = rowHeight * 0.18;
        final totalHeight = rowHeight * 2 + spacing + staggerOffset;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Row 1 ──────────────────────────────────────
              _buildImage(images[0], left: 0, top: 0, width: colWidth, height: rowHeight),
              _buildImage(images[1], left: colWidth + spacing, top: staggerOffset, width: colWidth, height: rowHeight),
              _buildImage(images[2], left: (colWidth + spacing) * 2, top: 0, width: colWidth, height: rowHeight),

              // ── Row 2 ──────────────────────────────────────
              _buildImage(images[3], left: 0, top: rowHeight + spacing + staggerOffset, width: colWidth, height: rowHeight),
              _buildImage(images[4], left: colWidth + spacing, top: rowHeight + spacing + staggerOffset * 1.9, width: colWidth, height: rowHeight),
              _buildImage(images[5], left: (colWidth + spacing) * 2, top: rowHeight + spacing + staggerOffset, width: colWidth, height: rowHeight),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(
      String path, {
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
        child: useNetwork
            ? Image.network(
          path,
          fit: BoxFit.cover,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.grey200,
            child: const Icon(Icons.image_outlined, color: AppColors.grey400, size: 28),
          ),
        )
            : Image.asset(
          path,
          fit: BoxFit.cover,
          width: width,
          height: height,
        ),
      ),
    );
  }
}