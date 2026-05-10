import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/feedback_sheet.dart';
import '../../../shared/widgets/yaa_button.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header blanc simple ──────────────────────────
          Padding(
            padding: EdgeInsets.only(
              top: top + 12,
              left: AppDimens.screenPadding,
              right: AppDimens.screenPadding,
              bottom: 16,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: AppColors.dark),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '#CMD-8320',
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    'Livrée',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.grey200),

          // ── Contenu ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Date ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding, 20,
                        AppDimens.screenPadding, 20),
                    child: Text(
                      'Hier, 19:45',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey400,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.grey200),

                  // ── Articles ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding, 20,
                        AppDimens.screenPadding, 0),
                    child: Text(
                      'Articles',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.grey500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),

                  _ItemRow(
                    imageUrl:
                        'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=200',
                    name: 'Pasta Box',
                    description: '1× Spaghetti bolognaise',
                    price: 1000,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.screenPadding),
                    child: Divider(height: 1, color: AppColors.grey200),
                  ),

                  _ItemRow(
                    imageUrl:
                        'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=200',
                    name: 'Boisson Fraîche',
                    description: '1× Coca-Cola (33cl)',
                    price: 500,
                  ),

                  const Divider(height: 1, color: AppColors.grey200),

                  // ── Récapitulatif prix ────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding, 20,
                        AppDimens.screenPadding, 0),
                    child: Text(
                      'Récapitulatif',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.grey500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _PriceRow(label: 'Sous-total', value: '1 500 F'),
                  _PriceRow(label: 'Frais de livraison', value: '500 F'),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.screenPadding, vertical: 12),
                    child: const Divider(height: 1, color: AppColors.grey200),
                  ),

                  _PriceRow(
                      label: 'Total payé', value: '2 000 F', isTotal: true),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.grey200),

                  // ── Adresse + paiement ────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding, 20,
                        AppDimens.screenPadding, 0),
                    child: Text(
                      'Détails',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.grey500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    title: 'Adresse de livraison',
                    subtitle:
                        'Mermoz, Dakar · Appt 4B, Résidence les Flamboyants',
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.screenPadding),
                    child: Divider(height: 24, color: AppColors.grey200),
                  ),

                  _DetailRow(
                    icon: Icons.payments_outlined,
                    title: 'Paiement',
                    subtitle: 'Espèces à la livraison',
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.grey200),

                  // ── Boutons ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding, 24,
                        AppDimens.screenPadding, 0),
                    child: Column(
                      children: [
                        YaaButton(
                          label: 'Donner un avis',
                          onPressed: () =>
                              showFeedbackSheet(context, shopName: 'Pasta Box'),
                          isOutlined: true,
                          foregroundColor: AppColors.primary,
                        ),
                        const SizedBox(height: AppDimens.md),
                        YaaButton(
                          label: 'Télécharger le reçu',
                          onPressed: () {},
                          icon: Icons.download_outlined,
                          backgroundColor: AppColors.grey100,
                          foregroundColor: AppColors.dark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ligne article ─────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.imageUrl,
    required this.name,
    required this.description,
    required this.price,
  });

  final String imageUrl;
  final String name;
  final String description;
  final int price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.screenPadding, vertical: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: AppColors.grey100,
                child: const Icon(Icons.image_outlined,
                    color: AppColors.grey400, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$price F',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ligne prix ────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.screenPadding, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.dark,
                  )
                : AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey500,
                    fontSize: 13,
                  ),
          ),
          Text(
            value,
            style: isTotal
                ? AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.dark,
                  )
                : AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.dark,
                    fontSize: 13,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Ligne détail (adresse, paiement) ──────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.screenPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.grey600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
