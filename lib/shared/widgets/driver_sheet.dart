import 'package:flutter/material.dart';
import 'package:yaa/shared/widgets/yaa_button.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';

/// Shows the driver detail bottom sheet.
/// ```dart
/// showDriverSheet(context);
/// ```
void showDriverSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DriverSheet(),
  );
}

class _DriverSheet extends StatelessWidget {
  const _DriverSheet();

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
                  'Détails Livreur',
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

          // Driver photo with verified badge
          Stack(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/diallo_livreur.png',
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
                    child: const Icon(Icons.person,
                        color: AppColors.grey500, size: 36),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: AppColors.white, size: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.lg),

          // Name
          Text(
            'Mamadou Diallo',
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
                  icon: Icons.pedal_bike,
                  value: '245',
                  label: 'Trajets réussis',
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

          // Vehicle info
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations du véhicule',
                  style: AppTextStyles.labelMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppDimens.md),

                // Vehicle card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimens.lg),
                  decoration: BoxDecoration(
                    color: AppColors.grey900,
                    borderRadius:
                    BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  child: Column(
                    children: [
                      // Moto image
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(AppDimens.radiusMd),
                        child: Image.asset(
                          'assets/images/moto.png',
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: AppColors.grey800,
                            child: const Icon(Icons.two_wheeler,
                                color: AppColors.grey500, size: 48),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.md),
                      Text(
                        'DIAKARTA',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'AA-1234-56',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey400,
                            ),
                          ),
                          const SizedBox(width: AppDimens.sm),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.grey500,
                            ),
                          ),
                          const SizedBox(width: AppDimens.sm),
                          Text(
                            'Rouge noir',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.xxl),

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
                        // TODO: Call driver
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
                        // TODO: Message driver
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