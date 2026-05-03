import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../shared/widgets/restaurant_sheet.dart';
import '../../../shared/widgets/yaa_button.dart';
/// Product detail screen.
/// Full-width image (rounded bottom corners), name, price, rating,
/// description, restaurant info, and "Ajouter au panier" button.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Product Image ─────────────────────────
                  _buildImage(context),

                  Padding(
                    padding: const EdgeInsets.all(AppDimens.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + Rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Truffle Beef\nBurger',
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dark,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimens.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: AppColors.warning),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.5',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.dark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDimens.sm),

                        // Price
                        Text(
                          '2500F cfa',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: AppDimens.xxl),

                        // Description label
                        Text(
                          'Description',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: AppDimens.md),

                        // Description text
                        Text(
                          'Un burger gastronomique composé d\'un steak de bœuf haché frais, de fromage fondant, de champignons sautés et de notre sauce signature à la truffe noire. Le tout servi dans un pain brioché artisanal toasté. Un délice pour les amateurs de saveurs intenses.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey600,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: AppDimens.xxl),

                        // Restaurant info card
                        _buildRestaurantCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom button ─────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.screenPadding,
              vertical: AppDimens.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: YaaButton(
                label: 'Ajouter au panier — 2500F',
                onPressed: () {
                  context.pushNamed(RouteNames.cart);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Stack(
      children: [
        // Image with rounded bottom corners
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 280,
            child: Image.network(
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.grey200,
                child: const Icon(Icons.image_outlined,
                    size: 60, color: AppColors.grey400),
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + AppDimens.sm,
          left: AppDimens.screenPadding,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.white,
                size: 26,
              ),
            ),
          ),
        ),

        // Favorite button
        Positioned(
          top: MediaQuery.of(context).padding.top + AppDimens.sm,
          right: AppDimens.screenPadding,
          child: GestureDetector(
            onTap: () => setState(() => _isFavorite = !_isFavorite),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: AppColors.error,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantCard() {
    return GestureDetector(
      onTap: () => showRestaurantSheet(context),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            // Restaurant logo
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              child: Image.asset(
                'assets/images/resto_tata.jpg',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: const Icon(Icons.restaurant,
                      color: AppColors.grey500, size: 22),
                ),
              ),
            ),

            const SizedBox(width: AppDimens.md),

            // Restaurant info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'les delices de mami',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '★ 4.8 • 20-30 min',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow — bleu
            const Icon(
              Icons.chevron_right,
              color: AppColors.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}