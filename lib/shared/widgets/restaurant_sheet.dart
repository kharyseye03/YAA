import 'package:flutter/material.dart';
import 'package:yaa/shared/widgets/yaa_button.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';

/// Shows the restaurant detail bottom sheet.
/// ```dart
/// showRestaurantSheet(context);
/// ```
void showRestaurantSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RestaurantSheet(),
  );
}

class _RestaurantSheet extends StatelessWidget {
  const _RestaurantSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppDimens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: AppDimens.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: AppDimens.lg),

          // Title + close
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Détails du resto',
                  style: AppTextStyles.h4
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close,
                      color: AppColors.grey500, size: 24),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.xxl),

          // Restaurant image
          ClipOval(
            child: Image.asset(
              'assets/images/resto_tata.png',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.grey200,
                ),
                child: ClipRRect(
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
              ),
            ),
          ),

          const SizedBox(height: AppDimens.lg),

          // Name
          Text(
            'Les délice de tata',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Membre depuis 2022',
            style:
            AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),

          const SizedBox(height: AppDimens.xxl),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: Row(
              children: [
                _buildStat(
                  icon: Icons.receipt_long_outlined,
                  value: '+245',
                  label: 'Commandnes',
                  color: AppColors.primary,
                ),
                _buildDivider(),
                _buildStat(
                  icon: Icons.star,
                  value: '4.8',
                  label: '129 avis',
                  color: AppColors.warning,
                ),
                _buildDivider(),
                _buildStat(
                  icon: Icons.verified_outlined,
                  value: '98%',
                  label: 'Taux de réussite',
                  color: AppColors.success,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.xxxl),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: Row(
              children: [
                // Appeler
                Expanded(
                  child: SizedBox(
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Call restaurant
                      },
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Appeler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(AppDimens.radiusFull),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                // Message
                Expanded(
                  child: SizedBox(
                    height: AppDimens.buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Message restaurant
                      },
                      icon: const Icon(Icons.chat_bubble_outline,
                          size: 18),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(AppDimens.radiusFull),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppDimens.sm),
          Text(
            value,
            style: AppTextStyles.labelLarge
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppColors.grey200,
    );
  }
}