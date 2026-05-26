import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/api/api_config.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../features/cart/providers/cart_notifier.dart';
import '../../../model/cart/cart_item_model.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../../shared/widgets/yaa_text_field.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key, this.onAddMore});

  final VoidCallback? onAddMore;

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).loadCart());
  }

  Future<void> _confirmClearCart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title        : const Text('Vider le panier'),
        content      : const Text('Êtes-vous sûr de vouloir supprimer tous les articles ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(cartProvider.notifier).clearCartFromServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cart      = cartState.cart;
    final lignes    = cart?.lignes ?? [];
    final total     = cart?.montantTotal ?? 0.0;
    final count     = cart?.totalArticles ?? 0;

    return Column(
      children: [
        // ── Header blanc ────────────────────────────────
        Padding(
          padding: EdgeInsets.only(
            top    : MediaQuery.of(context).padding.top + 12,
            left   : AppDimens.screenPadding,
            right  : AppDimens.screenPadding,
            bottom : 16,
          ),
          child: Row(
            children: [
              Text(
                'Mon panier',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color        : AppColors.grey100,
                  borderRadius : BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: Text(
                  cartState.isLoading
                      ? '...'
                      : '$count article${count > 1 ? 's' : ''}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color      : AppColors.grey600,
                    fontWeight : FontWeight.w600,
                    fontSize   : 12,
                  ),
                ),
              ),
              if (lignes.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmClearCart(context),
                  child: Container(
                    width  : 34,
                    height : 34,
                    decoration: BoxDecoration(
                      color        : AppColors.errorLight,
                      borderRadius : BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color : AppColors.error,
                      size  : 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.grey200),

        // ── Erreur ─────────────────────────────────────
        if (cartState.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding, vertical: 10),
            color: AppColors.errorLight,
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cartState.error!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),

        // ── Contenu scrollable ──────────────────────────
        Expanded(
          child: cartState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.screenPadding,
                    20,
                    AppDimens.screenPadding,
                    120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Résumé total ───────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total à payer',
                            style: AppTextStyles.bodySmall.copyWith(
                              color    : AppColors.grey500,
                              fontSize : 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${total.toStringAsFixed(0)} F',
                            style: const TextStyle(
                              fontFamily : 'Archivo',
                              fontSize   : 30,
                              fontWeight : FontWeight.w800,
                              color      : AppColors.dark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColors.grey200),
                      const SizedBox(height: 20),

                      // ── Adresse ────────────────────────────
                      Row(
                        children: [
                          Container(
                            width  : 36,
                            height : 36,
                            decoration: BoxDecoration(
                              color        : AppColors.primarySurface,
                              borderRadius : BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_on_outlined,
                                color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Adresse de livraison',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color    : AppColors.grey500,
                                    fontSize : 11,
                                  ),
                                ),
                                Text(
                                  '15 Rue de la Paix, Dakar',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight : FontWeight.w600,
                                    fontSize   : 13,
                                    color      : AppColors.dark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.grey400),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColors.grey200),
                      const SizedBox(height: 20),

                      // ── Articles ───────────────────────────
                      Row(
                        children: [
                          Text(
                            'Articles',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight  : FontWeight.w700,
                              fontSize    : 13,
                              color       : AppColors.grey500,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (lignes.isNotEmpty) ...[
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.swipe_left_outlined,
                                    size: 12, color: AppColors.grey400),
                                const SizedBox(width: 4),
                                Text(
                                  'Glisser pour supprimer',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize : 11,
                                    color    : AppColors.grey400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (lignes.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Votre panier est vide',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                          ),
                        )
                      else
                        ...List.generate(lignes.length, (i) {
                          final item = lignes[i];
                          return Column(
                            children: [
                              Dismissible(
                                key       : ValueKey(item.id),
                                direction : DismissDirection.endToStart,
                                background: Container(
                                  alignment   : Alignment.centerRight,
                                  padding     : const EdgeInsets.only(right: 16),
                                  decoration  : BoxDecoration(
                                    color        : AppColors.error,
                                    borderRadius : BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color : Colors.white,
                                    size  : 24,
                                  ),
                                ),
                                onDismissed: (_) {
                                  ref.read(cartProvider.notifier).removeItem(item.id);
                                },
                                child: _CartItem(item: item),
                              ),
                              if (i < lignes.length - 1)
                                const Divider(
                                    height: 24, color: AppColors.grey200),
                            ],
                          );
                        }),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: AppColors.grey200),
                      const SizedBox(height: 20),

                      // ── Note ──────────────────────────────
                      Text(
                        'Note pour le livreur',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight   : FontWeight.w700,
                          fontSize     : 13,
                          color        : AppColors.grey500,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      YaaTextField(
                        hint     : 'Instructions supplémentaires…',
                        maxLines : 3,
                      ),
                    ],
                  ),
                ),
        ),

        // ── Bouton Commander fixe ───────────────────────
        Container(
          padding: EdgeInsets.only(
            left   : AppDimens.screenPadding,
            right  : AppDimens.screenPadding,
            top    : 12,
            bottom : MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: const BoxDecoration(
            color  : Colors.white,
            border : Border(top: BorderSide(color: AppColors.grey200)),
          ),
          child: YaaButton(
            label           : lignes.isEmpty
                ? 'Panier vide'
                : 'Commander · ${total.toStringAsFixed(0)} F',
            onPressed       : lignes.isEmpty
                ? null
                : () => context.pushNamed(RouteNames.checkout),
            icon            : lignes.isEmpty ? null : Icons.arrow_forward,
            backgroundColor : lignes.isEmpty
                ? AppColors.grey300
                : AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

// ── Chip info ─────────────────────────────────────────────
class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color        : AppColors.grey100,
        borderRadius : BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.grey600),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize   : 11,
              color      : AppColors.grey600,
              fontWeight : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Article panier ────────────────────────────────────────
class _CartItem extends StatefulWidget {
  const _CartItem({required this.item});

  final CartItemModel item;

  @override
  State<_CartItem> createState() => _CartItemState();
}

class _CartItemState extends State<_CartItem> {
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = widget.item.quantite;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: widget.item.image != null
              ? Image.network(
                  ApiConfig.getImageUrl(widget.item.image!),
                  width     : 56,
                  height    : 56,
                  fit       : BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width : 56, height: 56,
                    color : AppColors.grey100,
                    child : const Icon(Icons.fastfood_outlined,
                        color: AppColors.grey400, size: 24),
                  ),
                )
              : Container(
                  width : 56,
                  height: 56,
                  color : AppColors.grey100,
                  child : const Icon(Icons.fastfood_outlined,
                      color: AppColors.grey400, size: 24),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.nom.isNotEmpty
                    ? widget.item.nom
                    : 'Produit #${widget.item.produitId}',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w700,
                  fontSize   : 14,
                  color      : AppColors.dark,
                ),
                maxLines : 1,
                overflow : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.item.prixUnitaire.toStringAsFixed(0)} F',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w700,
                  fontSize   : 13,
                  color      : AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            GestureDetector(
              onTap: () { if (_qty > 1) setState(() => _qty--); },
              child: Container(
                width  : 28,
                height : 28,
                decoration: BoxDecoration(
                  color : AppColors.grey100,
                  shape : BoxShape.circle,
                ),
                child: const Icon(Icons.remove, size: 14, color: AppColors.dark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$_qty',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w700,
                  fontSize   : 14,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _qty++),
              child: Container(
                width  : 28,
                height : 28,
                decoration: const BoxDecoration(
                  color : AppColors.primary,
                  shape : BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
