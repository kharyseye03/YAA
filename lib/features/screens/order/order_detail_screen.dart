import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/feedback_sheet.dart';
import '../../../shared/widgets/yaa_button.dart';

/// Order detail screen for delivered orders — "Commande #CMD-XXXX"
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          _buildHeader(context),

          // ── Content ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding,
                vertical: AppDimens.lg,
              ),
              child: Column(
                children: [
                  // ── Main card ─────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                      BorderRadius.circular(AppDimens.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Order ID + Status
                        Padding(
                          padding: const EdgeInsets.all(AppDimens.lg),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Commande #CMD-8320',
                                    style:
                                    AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hier, 19:45',
                                    style:
                                    AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppDimens.radiusFull),
                                ),
                                child: Text(
                                  'Livrée',
                                  style:
                                  AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Dotted separator ────────────────
                        _buildDottedDivider(),

                        // ── Items ───────────────────────────
                        Padding(
                          padding: const EdgeInsets.all(AppDimens.lg),
                          child: Column(
                            children: [
                              _buildItemRow(
                                imageUrl:
                                'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=200',
                                name: 'Pasta Box',
                                description:
                                '1x Spaguetti\nbolognaise',
                                price: '1000F cfa',
                              ),
                              const SizedBox(height: AppDimens.xl),
                              _buildItemRow(
                                imageUrl:
                                'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=200',
                                name: 'Boisson Fraîche',
                                description: '1x Coca-Cola (33cl)',
                                price: '500F cfa',
                              ),
                            ],
                          ),
                        ),

                        // ── Dotted separator ────────────────
                        _buildDottedDivider(),

                        // ── Price breakdown ─────────────────
                        Padding(
                          padding: const EdgeInsets.all(AppDimens.lg),
                          child: Column(
                            children: [
                              _buildPriceRow(
                                  'Sous-total', '1500F cfa', false),
                              const SizedBox(height: AppDimens.lg),
                              _buildPriceRow(
                                  'Frais de livraison', '500F cfa', false),
                              const SizedBox(height: AppDimens.lg),
                              const Divider(
                                  color: AppColors.grey200, height: 1),
                              const SizedBox(height: AppDimens.lg),
                              _buildPriceRow(
                                  'Total payé', '2000F cfa', true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimens.xxl),

                  // ── Info card (address + payment) ──────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimens.lg),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                      BorderRadius.circular(AppDimens.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Delivery address
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          title: 'Adresse de livraison',
                          lines: [
                            'Mermoz, Dakar',
                            'Appartement 4B, Résidence les Flamboyants',
                          ],
                        ),

                        const SizedBox(height: AppDimens.xxl),

                        // Payment method
                        _buildInfoRow(
                          icon: Icons.payment_outlined,
                          title: 'Méthode de paiement',
                          lines: ['Espèces à la livraison'],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimens.xxxl),

                  // ── Buttons ────────────────────────────────
                  YaaButton(
                    label: 'Télécharger',
                    onPressed: () {
                      // TODO: Download receipt
                    },
                    icon: Icons.download,
                    backgroundColor: AppColors.primarySurface,
                    foregroundColor: AppColors.primary,
                  ),

                  const SizedBox(height: AppDimens.md),

                  YaaButton(
                    label: 'Donner un avis',
                    onPressed: () => showFeedbackSheet(context, shopName: 'TATA Food'),
                    isOutlined: true,
                    backgroundColor: AppColors.primarySurface,
                    foregroundColor: AppColors.primary,
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

  // ── Header ───────────────────────────────────────────────
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
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Text(
            'Commande #CMD-8320',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dotted divider ───────────────────────────────────────
  Widget _buildDottedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = 6.0;
          final dashSpace = 4.0;
          final dashCount =
          (constraints.maxWidth / (dashWidth + dashSpace)).floor();

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1.5,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.grey300),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ── Item row ─────────────────────────────────────────────
  Widget _buildItemRow({
    required String imageUrl,
    required String name,
    required String description,
    required String price,
  }) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Image.network(
            imageUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 64,
              height: 64,
              color: AppColors.grey200,
              child: const Icon(Icons.image_outlined,
                  color: AppColors.grey400),
            ),
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Price row ────────────────────────────────────────────
  Widget _buildPriceRow(String label, String price, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.labelLarge
              .copyWith(fontWeight: FontWeight.w700)
              : AppTextStyles.bodyMedium
              .copyWith(color: AppColors.grey600),
        ),
        Text(
          price,
          style: isTotal
              ? AppTextStyles.labelLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          )
              : AppTextStyles.bodyMedium.copyWith(color: AppColors.dark),
        ),
      ],
    );
  }

  // ── Info row (address, payment) ──────────────────────────
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required List<String> lines,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.grey100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.grey600, size: 20),
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
              const SizedBox(height: 4),
              ...lines.map((line) => Text(
                line,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
}