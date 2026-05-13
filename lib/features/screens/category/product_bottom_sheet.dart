import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../home/providers/category_provider.dart';

void showProductBottomSheet(BuildContext context, int produitId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProviderScope(
      child: _ProductSheet(produitId: produitId),
    ),
  );
}

class _ProductSheet extends ConsumerStatefulWidget {
  const _ProductSheet({required this.produitId});
  final int produitId;

  @override
  ConsumerState<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends ConsumerState<_ProductSheet> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(produitDetailProvider(widget.produitId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.xl),
            child: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (produit) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image + bouton fermer ──────────────
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.network(
                            produit.imageUrl,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 300,
                              color: AppColors.grey100,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 20, color: AppColors.dark),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Contenu ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding,
                        AppDimens.lg,
                        AppDimens.screenPadding,
                        AppDimens.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nom + Prix
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  produit.nom,
                                  style: AppTextStyles.h2.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    color: AppColors.dark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimens.md),
                              Text(
                                '${produit.prix.toInt()} F',
                                style: AppTextStyles.h3.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppDimens.lg),

                          // Description
                          Text(
                            produit.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey500,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Barre bas fixe ─────────────────────────
            Container(
              padding: EdgeInsets.only(
                left: AppDimens.screenPadding,
                right: AppDimens.screenPadding,
                top: AppDimens.md,
                bottom: MediaQuery.of(context).padding.bottom + AppDimens.md,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.grey200)),
              ),
              child: Row(
                children: [
                  // Sélecteur quantité
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey300),
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: Row(
                      children: [
                        _QuantityButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _QuantityButton(
                          icon: Icons.add,
                          onTap: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppDimens.md),

                  // Bouton Ajouter
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D00),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusFull),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Ajouter',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 20, color: AppColors.dark),
      ),
    );
  }
}
