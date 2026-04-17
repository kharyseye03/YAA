import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/driver_sheet.dart';
import '../../../shared/widgets/restaurant_sheet.dart';
import '../../../shared/widgets/yaa_button.dart';

/// Order tracking screen — "Itinéraire"
/// Map placeholder, ETA, order status timeline,
/// delivery address, restaurant info, driver info.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          _buildHeader(context),

          // ── Map placeholder ─────────────────────────────
          _buildMapPlaceholder(),

          // ── Content ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimens.xxl),

                  // ETA + Order ID
                  _buildEtaSection(),

                  const SizedBox(height: AppDimens.xxl),

                  // Timeline
                  _buildTimeline(),

                  const SizedBox(height: AppDimens.xxl),

                  // Delivery address
                  _buildDeliveryAddress(),

                  const SizedBox(height: AppDimens.lg),

                  // Restaurant card
                  GestureDetector(
                    onTap: () => showRestaurantSheet(context),
                    child: _buildInfoCard(
                      icon: Icons.restaurant,
                      iconColor: AppColors.primary,
                      title: 'les delices de mami',
                      subtitle: '★ 4.8 •20-30 min',
                    ),
                  ),

                  const SizedBox(height: AppDimens.md),

                  // Driver card
                  GestureDetector(
                    onTap: () => showDriverSheet(context),
                    child: _buildInfoCard(
                      icon: Icons.person,
                      iconColor: AppColors.grey600,
                      title: 'Mamadou D.',
                      subtitle: 'Moto Yamaha - AB 1234',
                      isDriver: true,
                    ),
                  ),
                  const SizedBox(height: AppDimens.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: MediaQuery.of(context).padding.top + AppDimens.md,
        bottom: AppDimens.xl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1652F0),
            Color(0xFF08399A)
          ],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.chevron_left,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Text(
            'Itinéraire',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      color: AppColors.grey200,
      child: Stack(
        children: [
          // Placeholder map background
          Center(
            child: Icon(
              Icons.map_outlined,
              size: 60,
              color: AppColors.grey400,
            ),
          ),

          // "En route" badge
          Positioned(
            bottom: AppDimens.lg,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                  BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pedal_bike,
                        color: AppColors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'En route',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heure d\'arrivée estimée',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '14:45 - 15:00',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          ),
          child: Text(
            '#CMD-8491',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    final steps = [
      _TimelineStep(
        title: 'Commande acceptée',
        time: '13:15',
        isCompleted: true,
      ),
      _TimelineStep(
        title: 'En préparation',
        time: '13:20',
        isCompleted: true,
      ),
      _TimelineStep(
        title: 'Le livreur est en route',
        time: '13:40',
        isCompleted: true,
        isActive: true,
      ),
      _TimelineStep(
        title: 'Livraison à l\'adresse',
        time: '--:--',
        isCompleted: false,
      ),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot + line
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: step.isActive ? 14 : 10,
                    height: step.isActive ? 14 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step.isCompleted
                          ? AppColors.primary
                          : AppColors.grey300,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: step.isCompleted
                          ? AppColors.primary
                          : AppColors.grey300,
                    ),
                ],
              ),
            ),

            const SizedBox(width: AppDimens.md),

            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: step.isCompleted
                            ? AppColors.dark
                            : AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.time,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDeliveryAddress() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_outlined,
            color: AppColors.grey600,
            size: 20,
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adresse de livraison',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mermoz, Dakar\nAppartement 4B, Résidence les Flamboyants',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isDriver = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDriver ? AppColors.grey200 : AppColors.grey100,
              borderRadius: BorderRadius.circular(
                  isDriver ? AppDimens.radiusFull : AppDimens.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.grey400, size: 24),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final String time;
  final bool isCompleted;
  final bool isActive;

  const _TimelineStep({
    required this.title,
    required this.time,
    required this.isCompleted,
    this.isActive = false,
  });
}