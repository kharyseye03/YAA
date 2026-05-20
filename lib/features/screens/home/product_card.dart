import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/cart/providers/cart_notifier.dart';

class ProductData {
  final int id;
  final String name;
  final String? subtitle;
  final int price;
  final double rating;
  final String imageUrl;
  final bool isAsset;

  const ProductData({
    this.id = 0,
    required this.name,
    this.subtitle,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.isAsset = false,
  });
}

class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  final ProductData product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdding = ref.watch(cartProvider).isAdding;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
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

                // Rating badge
                Positioned(
                  top   : AppDimens.sm,
                  right : AppDimens.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color        : AppColors.white.withValues(alpha: 0.92),
                      borderRadius : BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: AppColors.error),
                        const SizedBox(width: 3),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize : 11,
                            color    : AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bouton +
                Positioned(
                  bottom : AppDimens.sm,
                  right  : AppDimens.sm,
                  child: GestureDetector(
                    onTap: isAdding
                        ? null
                        : () => _addToCart(context, ref),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color : AppColors.primary,
                        shape : BoxShape.circle,
                      ),
                      child: isAdding
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                color       : AppColors.white,
                                strokeWidth : 2,
                              ),
                            )
                          : const Icon(
                              Icons.add,
                              color : AppColors.white,
                              size  : 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.sm),

          Text(
            product.name,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w700,
              color      : AppColors.dark,
              fontSize   : 13,
            ),
            maxLines : 1,
            overflow : TextOverflow.ellipsis,
          ),

          Text(
            '${product.price}F cfa',
            style: AppTextStyles.labelMedium.copyWith(
              color      : AppColors.primary,
              fontWeight : FontWeight.w600,
              fontSize   : 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(cartProvider.notifier).addToCart(
          produitId : product.id,
          quantite  : 1,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${product.name} ajouté au panier ✓'
              : ref.read(cartProvider).error ?? 'Erreur lors de l\'ajout',
        ),
        backgroundColor: success ? AppColors.primary : AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
