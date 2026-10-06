import 'dart:async';
import '../../../shared/widgets/image_reseau.dart';
import '../../../core/utils/devise.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/api/api_config.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  const CartScreen({super.key, this.onAddMore, this.afficherRetour = false});

  final VoidCallback? onAddMore;

  /// Affiche une flèche de retour dans l'en-tête.
  ///
  /// Vrai quand l'écran est empilé — depuis la pastille « Voir mon
  /// panier » d'un établissement. Faux quand il sert d'onglet de
  /// l'accueil : il n'y a alors rien derrière, et une flèche
  /// promettrait un retour qui n'existe pas.
  final bool afficherRetour;

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
        shape   : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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
            bottom : 16.h,
          ),
          child: Row(
            children: [
              if (widget.afficherRetour) ...[
                GestureDetector(
                  onTap    : () => Navigator.of(context).maybePop(),
                  behavior : HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(right: AppDimens.sm),
                    child: Icon(Icons.arrow_back_rounded,
                        color: AppColors.dark, size: 22.r),
                  ),
                ),
              ],
              Text(
                'Mon panier',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
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
                    fontSize   : 12.sp,
                  ),
                ),
              ),
              if (!isEmpty) ...[
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => _confirmClearCart(context),
                  child: Container(
                    width  : 34.r,
                    height : 34.r,
                    decoration: BoxDecoration(
                      color        : AppColors.errorLight,
                      borderRadius : BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color : AppColors.error,
                      size  : 18.r,
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
            padding : EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding, vertical: 10.h),
            color   : AppColors.errorLight,
            child   : Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 16.r),
                SizedBox(width: 8.w),
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
                  padding: EdgeInsets.fromLTRB(
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
                          fontSize : 12.sp,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        montantLabel(total),
                        style: TextStyle(
                          fontFamily : 'PlusJakartaSans',
                          fontSize   : 30.sp,
                          fontWeight : FontWeight.w800,
                          color      : AppColors.dark,
                        ),
                      ),

                      SizedBox(height: 20.h),
                      const Divider(height: 1, color: AppColors.grey200),
                      SizedBox(height: 20.h),

                      // ── Adresse de livraison ─────────────────
                      // Adresse de la commande en cours, sinon
                      // adresse par défaut du profil
                      GestureDetector(
                        onTap    : () => showDeliveryAddressSheet(context),
                        behavior : HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Container(
                              width  : 36.r,
                              height : 36.r,
                              decoration: BoxDecoration(
                                color        : AppColors.primarySurface,
                                borderRadius : BorderRadius.circular(10.r),
                              ),
                              child: Icon(Icons.location_on_outlined,
                                  color: AppColors.primary, size: 18.r),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Adresse de livraison',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color    : AppColors.grey500,
                                      fontSize : 11.sp,
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
                                      fontSize   : 13.sp,
                                      color      : AppColors.dark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 18.r, color: AppColors.grey400),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),
                      const Divider(height: 1, color: AppColors.grey200),
                      SizedBox(height: 20.h),

                      // ── Label Articles + hint swipe ───────────
                      Row(
                        children: [
                          Text(
                            'Articles',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight   : FontWeight.w700,
                              fontSize     : 13.sp,
                              color        : AppColors.grey500,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (!isEmpty) ...[
                            const Spacer(),
                            Icon(Icons.swipe_left_outlined,
                                size: 12.r, color: AppColors.grey400),
                            SizedBox(width: 4.w),
                            Text(
                              'Glisser pour supprimer',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize : 11.sp,
                                color    : AppColors.grey400,
                              ),
                            ),
                          ],
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // ── Panier vide ───────────────────────────
                      if (isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.h),
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
                              SizedBox(height: 12.h),

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
                                        padding   : EdgeInsets.only(right: 16.w),
                                        decoration: BoxDecoration(
                                          color        : AppColors.error,
                                          borderRadius : BorderRadius.circular(12.r),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          color : Colors.white,
                                          size  : 24.r,
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
                                      Divider(
                                          height: 24.h,
                                          color: AppColors.grey200),
                                  ],
                                );
                              }),

                              // Séparateur entre structures
                              if (gi < lignes.length - 1) ...[
                                SizedBox(height: 16.h),
                                const Divider(
                                    height: 1, color: AppColors.grey200),
                                SizedBox(height: 16.h),
                              ],
                            ],
                          );
                        }),

                      SizedBox(height: 24.h),
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
            top    : 12.h,
            bottom : MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: const BoxDecoration(
            color  : Colors.white,
            border : Border(top: BorderSide(color: AppColors.grey200)),
          ),
          child: YaaButton(
            label           : isEmpty
                ? 'Panier vide'
                : 'Commander · ${montantLabel(total)}',
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
          width  : 32.r,
          height : 32.r,
          decoration: BoxDecoration(
            color        : AppColors.primarySurface,
            borderRadius : BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.storefront_outlined,
              size: 16.r, color: AppColors.primary),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.nomStructure,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w700,
                  fontSize   : 13.sp,
                  color      : AppColors.dark,
                ),
              ),
              if (group.adresseStructure.isNotEmpty)
                Text(
                  group.adresseStructure,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize : 11.sp,
                    color    : AppColors.grey500,
                  ),
                ),
            ],
          ),
        ),
        Text(
          montantLabel(group.sousTotal),
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight : FontWeight.w700,
            color      : AppColors.dark,
            fontSize   : 13.sp,
          ),
        ),
      ],
    );
  }
}

// ── Article panier ────────────────────────────────────────────
class _CartItem extends ConsumerStatefulWidget {
  const _CartItem({required this.item});
  final CartItemModel item;

  @override
  ConsumerState<_CartItem> createState() => _CartItemState();
}

class _CartItemState extends ConsumerState<_CartItem> {
  late int _qty;

  /// L'envoi est différé : passer de 1 à 5 se fait en quatre appuis
  /// rapides, et déclencher un appel par appui saturerait le réseau
  /// pour trois quantités qui n'existeront jamais. Seule la dernière
  /// valeur part — ce que la sémantique de remplacement autorise.
  Timer? _envoiDiffere;

  @override
  void initState() {
    super.initState();
    _qty = widget.item.quantite;
  }

  @override
  void didUpdateWidget(_CartItem old) {
    super.didUpdateWidget(old);
    // Le panier relu depuis le serveur fait autorité, sauf pendant
    // qu'une saisie est en attente d'envoi : sinon le compteur
    // reviendrait en arrière sous le doigt de l'utilisateur.
    if (_envoiDiffere?.isActive != true &&
        widget.item.quantite != old.item.quantite) {
      _qty = widget.item.quantite;
    }
  }

  @override
  void dispose() {
    _envoiDiffere?.cancel();
    super.dispose();
  }

  /// Applique un écart à la quantité, affiché tout de suite et
  /// enregistré peu après.
  void _ajusterQuantite(int ecart) {
    final nouvelle = _qty + ecart;
    // Descendre à zéro reviendrait à supprimer la ligne : c'est le
    // rôle du balayage, pas celui du bouton « moins ».
    if (nouvelle < 1) return;

    setState(() => _qty = nouvelle);

    _envoiDiffere?.cancel();
    _envoiDiffere = Timer(const Duration(milliseconds: 450), () async {
      final ok = await ref.read(cartProvider.notifier).changerQuantite(
            produitId : widget.item.produitId,
            quantite  : nouvelle,
          );
      // Échec : on revient à la dernière quantité connue du serveur,
      // pour ne pas laisser un chiffre qui ment à l'écran.
      if (!ok && mounted) setState(() => _qty = widget.item.quantite);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: widget.item.image != null
              ? ImageReseau(
                  url: ApiConfig.getImageUrl(widget.item.image!),
                  width  : 56.r,
                  height : 56.r,
                  fit    : BoxFit.cover,
                  fallback: _placeholder(),
                )
              : _placeholder(),
        ),
        SizedBox(width: 14.w),
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
                  fontSize   : 14.sp,
                  color      : AppColors.dark,
                ),
                maxLines : 1,
                overflow : TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                montantLabel(widget.item.prixUnitaire),
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w700,
                  fontSize   : 13.sp,
                  color      : AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        // Sélecteur quantité
        Row(
          children: [
            _QtyButton(
              icon  : Icons.remove,
              color : AppColors.grey100,
              iconColor: _qty > 1 ? AppColors.dark : AppColors.grey400,
              onTap : () => _ajusterQuantite(-1),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Text(
                '$_qty',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w700,
                  fontSize   : 14.sp,
                ),
              ),
            ),
            _QtyButton(
              icon     : Icons.add,
              color    : AppColors.primary,
              iconColor: Colors.white,
              onTap    : () => _ajusterQuantite(1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        width  : 56.r,
        height : 56.r,
        color  : AppColors.grey100,
        child  : Icon(Icons.fastfood_outlined,
            color: AppColors.grey400, size: 24.r),
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
        width  : 28.r,
        height : 28.r,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child  : Icon(icon, size: 14.r, color: iconColor),
      ),
    );
  }
}
