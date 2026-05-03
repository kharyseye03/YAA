import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';

/// Data model for a product card.
class ProductData {
  final String name;
  final int price;
  final double rating;
  final String imageUrl;

  const ProductData({
    required this.name,
    required this.price,
    required this.rating,
    required this.imageUrl,
  });
}

/// Product card with image, rating badge, add-to-cart button, name and price.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddTap,
  });

  final ProductData product;
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with rating and add button overlay
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                // Image
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            color: AppColors.grey200,
                            child: const Icon(
                              Icons.image_outlined,
                              color: AppColors.grey400,
                              size: 40,
                            ),
                          ),
                    ),
                  ),
                ),

                // Rating badge (top-right)
                Positioned(
                  top: AppDimens.sm,
                  right: AppDimens.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.92),
                      borderRadius:
                      BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 11,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Add button (bottom-right)
                Positioned(
                  bottom: AppDimens.sm,
                  right: AppDimens.sm,
                  child: GestureDetector(
                    onTap: onAddTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.sm),

// Name
          Text(
            product.name,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

// Price
          Text(
            '${product.price}F cfa',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}