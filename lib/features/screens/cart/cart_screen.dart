import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/api/api_config.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../features/cart/providers/cart_notifier.dart';
import '../../../features/cart/providers/delivery_address_provider.dart';
import '../../../features/user/providers/user_notifier.dart';
import '../../../model/cart/cart_item_model.dart';
import '../../../service/location/location_service.dart';
import '../../../model/cart/cart_structure_model.dart';
import '../../../shared/widgets/yaa_button.dart';
import 'delivery_address_sheet.dart';
import 'reception_mode_sheet.dart';

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
        shape   : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title   : const Text('Vider le panier'),
        content : const Text('Êtes-vous sûr de vouloir supprimer tous les articles ?'),
        actions : [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed : () => Navigator.of(ctx).pop(true),
            style     : TextButton.styleFrom(foregroundColor: AppColors.error),
            child     : const Text('Vider'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(cartProvider.notifier).clearCartFromServer();
    }
  }

  void _handleCommander(BuildContext context) {
    final cart = ref.read(cartProvider).cart;
    if (cart == null || cart.lignes.isEmpty) return;

    // Coordonnées d'arrivée : l'adresse choisie pour cette commande,
    // sinon celle du profil. Le sheet en a besoin dès son ouverture
    // pour précharger les tarifs.
    final livraison = ref.read(deliveryAddressProvider);
    final profil    = ref.read(userProvider).profile;

    // La question est posée à chaque commande : livraison ou retrait.
    showReceptionModeSheet(
      context,
      lignes          : cart.lignes,
      latitudeClient  : livraison?.latitude  ?? profil?.latitude,
      longitudeClient : livraison?.longitude ?? profil?.longitude,
      onConfirm: (choix) {
        Navigator.of(context).pop();
        context.pushNamed(RouteNames.checkout, extra: choix);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cart      = cartState.cart;
    final lignes    = cart?.lignes ?? [];
    final total     = cart?.montantTotal ?? 0.0;
    final count     = cart?.totalArticles ?? 0;
    final isEmpty   = lignes.isEmpty;

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────
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
              if (!isEmpty) ...[
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

        // ── Erreur ──────────────────────────────────────────
        if (cartState.error != null)
          Container(
            width   : double.infinity,
            padding : const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding, vertical: 10),
            color   : AppColors.errorLight,
            child   : Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cartState.error!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),

        // ── Contenu scrollable ───────────────────────────────
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
                      // ── Résumé total ─────────────────────────
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

                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColors.grey200),
                      const SizedBox(height: 20),

                      // ── Adresse de livraison ─────────────────
                      // Adresse de la commande en cours, sinon
                      // adresse par défaut du profil
                      GestureDetector(
                        onTap    : () => showDeliveryAddressSheet(context),
                        behavior : HitTestBehavior.opaque,
                        child: Row(
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
                                    () {
                                      final adr = ref.watch(deliveryAddressProvider)?.adresse
                                          ?? ref.watch(userProvider).profile?.address;
                                      return adr != null
                                          ? LocationService.cleanAddress(adr)
                                          : 'Définir une adresse';
                                    }(),
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight : FontWeight.w600,
                                      fontSize   : 13,
                                      color      : AppColors.dark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 18, color: AppColors.grey400),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColors.grey200),
                      const SizedBox(height: 20),

                      // ── Label Articles + hint swipe ───────────
                      Row(
                        children: [
                          Text(
                            'Articles',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight   : FontWeight.w700,
                              fontSize     : 13,
                              color        : AppColors.grey500,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (!isEmpty) ...[
                            const Spacer(),
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
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Panier vide ───────────────────────────
                      if (isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Votre panier est vide',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.grey500),
                            ),
                          ),
                        )

                      // ── Groupes par structure ─────────────────
                      else
                        ...List.generate(lignes.length, (gi) {
                          final group = lignes[gi];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête structure
                              _StructureHeader(group: group),
                              const SizedBox(height: 12),

                              // Produits de cette structure
                              ...List.generate(group.produits.length, (pi) {
                                final item = group.produits[pi];
                                return Column(
                                  children: [
                                    Dismissible(
                                      key       : ValueKey(item.id),
                                      direction : DismissDirection.endToStart,
                                      background: Container(
                                        alignment : Alignment.centerRight,
                                        padding   : const EdgeInsets.only(right: 16),
                                        decoration: BoxDecoration(
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
                                        ref
                                            .read(cartProvider.notifier)
                                            .removeItem(item.id);
                                      },
                                      child: _CartItem(item: item),
                                    ),
                                    if (pi < group.produits.length - 1)
                                      const Divider(
                                          height: 24,
                                          color: AppColors.grey200),
                                  ],
                                );
                              }),

                              // Séparateur entre structures
                              if (gi < lignes.length - 1) ...[
                                const SizedBox(height: 16),
                                const Divider(
                                    height: 1, color: AppColors.grey200),
                                const SizedBox(height: 16),
                              ],
                            ],
                          );
                        }),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: AppColors.grey200),

                    ],
                  ),
                ),
        ),

        // ── Bouton Commander fixe ────────────────────────────
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
            label           : isEmpty
                ? 'Panier vide'
                : 'Commander · ${total.toStringAsFixed(0)} F',
            onPressed       : isEmpty ? null : () => _handleCommander(context),
            icon            : isEmpty ? null : Icons.arrow_forward,
            backgroundColor : isEmpty ? AppColors.grey300 : AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

// ── En-tête de groupe structure ───────────────────────────────
class _StructureHeader extends StatelessWidget {
  const _StructureHeader({required this.group});
  final CartStructureModel group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width  : 32,
          height : 32,
          decoration: BoxDecoration(
            color        : AppColors.primarySurface,
            borderRadius : BorderRadius.circular(8),
          ),
          child: const Icon(Icons.storefront_outlined,
              size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.nomStructure,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w700,
                  fontSize   : 13,
                  color      : AppColors.dark,
                ),
              ),
              if (group.adresseStructure.isNotEmpty)
                Text(
                  group.adresseStructure,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize : 11,
                    color    : AppColors.grey500,
                  ),
                ),
            ],
          ),
        ),
        Text(
          '${group.sousTotal.toStringAsFixed(0)} F',
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight : FontWeight.w700,
            color      : AppColors.dark,
            fontSize   : 13,
          ),
        ),
      ],
    );
  }
}

// ── Article panier ────────────────────────────────────────────
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
                  width  : 56,
                  height : 56,
                  fit    : BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
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
        // Sélecteur quantité
        Row(
          children: [
            _QtyButton(
              icon  : Icons.remove,
              color : AppColors.grey100,
              iconColor: AppColors.dark,
              onTap : () { if (_qty > 1) setState(() => _qty--); },
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
            _QtyButton(
              icon     : Icons.add,
              color    : AppColors.primary,
              iconColor: Colors.white,
              onTap    : () => setState(() => _qty++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        width  : 56,
        height : 56,
        color  : AppColors.grey100,
        child  : const Icon(Icons.fastfood_outlined,
            color: AppColors.grey400, size: 24),
      );
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData  icon;
  final Color     color;
  final Color     iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width  : 28,
        height : 28,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child  : Icon(icon, size: 14, color: iconColor),
      ),
    );
  }
}
