import '../../../shared/widgets/image_reseau.dart';
import '../../../core/errors/messages_erreur.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/cart/providers/cart_notifier.dart';
import '../../../features/favoris/providers/favori_notifier.dart';
import '../home/providers/category_provider.dart';

void showProductBottomSheet(BuildContext context, int produitId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProductSheet(produitId: produitId),
  );
}

class _ProductSheet extends ConsumerStatefulWidget {
  const _ProductSheet({required this.produitId});
  final int produitId;

  @override
  ConsumerState<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends ConsumerState<_ProductSheet> {
  int  _quantity = 1;
  bool _added    = false; // état succès du bouton

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(produitDetailProvider(widget.produitId));

    return Container(
      // Plafond, non plus hauteur imposée : la feuille s'arrête là où
      // le contenu s'arrête. Avec une hauteur fixe, un produit à
      // description courte laissait une grande bande blanche sous le
      // texte — c'est ce qui se voyait depuis le retrait des sections
      // taille et extras.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.93,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(AppDimens.xl),
            child: Text(
              MessagesErreur.depuisException(e),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (produit) {
          // Le prix du backend, multiplié par la seule quantité. Le
          // sélecteur de taille appliquait ici un coefficient inventé
          // (0,8 / 1 / 1,3) : le bouton annonçait « Ajouter · 800 F »
          // pendant qu'addToCart n'envoyait que l'id et la quantité,
          // donc le panier facturait 1000. Le client lisait un prix
          // qui n'existait nulle part.
          final total = (produit.prix * _quantity).round();
          return Column(
            // La feuille épouse son contenu : sans cela, la contrainte
            // de hauteur maximale deviendrait une hauteur imposée.
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: CustomScrollView(
                  shrinkWrap: true,
                  slivers: [
                    SliverToBoxAdapter(child: _buildHero(produit)),
                    SliverToBoxAdapter(child: _buildContent(produit)),
                  ],
                ),
              ),
              _buildBottomBar(total),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHero(dynamic produit) {
    return Stack(
      children: [
        // ── Image hero ──────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          child: ImageReseau(
            url: produit.imageUrl,
            height: 300.h,
            width: double.infinity,
            fit: BoxFit.cover,
            fallback: Container(
              height: 300.h,
              color: AppColors.grey100,
              child: Center(
                child: Icon(Icons.image_outlined,
                    color: AppColors.grey400, size: 64.r),
              ),
            ),
          ),
        ),

        // ── Gradient haut (lisibilité boutons) ──────────
        Positioned(
          top: 0.h,
          left: 0.w,
          right: 0.w,
          child: ClipRRect(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28.r)),
            child: Container(
              height: 90.h,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Colors.transparent],
                ),
              ),
            ),
          ),
        ),

        // ── Gradient bas (fondu vers blanc) ─────────────
        Positioned(
          bottom: 0.h,
          left: 0.w,
          right: 0.w,
          child: Container(
            height: 110.h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.white, Colors.transparent],
              ),
            ),
          ),
        ),

        // ── Drag handle ─────────────────────────────────
        Positioned(
          top: 12.h,
          left: 0.w,
          right: 0.w,
          child: Center(
            child: SizedBox(
              width: 40.w,
              height: 4.h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.all(Radius.circular(100.r)),
                ),
              ),
            ),
          ),
        ),

        // ── Bouton fermer ────────────────────────────────
        Positioned(
          top: 16.h,
          right: 16.w,
          child: _GlassButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),

        // ── Bouton favori ────────────────────────────────
        Positioned(
          top: 16.h,
          left: 16.w,
          child: _GlassButton(
            icon: ref.watch(favoriProvider).isProduitFavori(widget.produitId)
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: ref.watch(favoriProvider).isProduitFavori(widget.produitId)
                ? AppColors.favori
                : Colors.white,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(favoriProvider.notifier)
                  .toggleProduitFavori(widget.produitId);
            },
          ),
        ),

        // ── Badge "Populaire" ────────────────────────────
        Positioned(
          bottom: 20.h,
          left: AppDimens.screenPadding,
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  blurRadius: 8.r,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔥', style: TextStyle(fontSize: 12.sp)),
                SizedBox(width: 5.w),
                Text(
                  'Populaire',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(dynamic produit) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.screenPadding,
        AppDimens.sm,
        AppDimens.screenPadding,
        AppDimens.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Chips info ───────────────────────────────
          Row(
            children: [
              _InfoChip(
                icon: Icons.star_rounded,
                label: '4.8',
                iconColor: const Color(0xFFFFC107),
              ),
              SizedBox(width: AppDimens.sm),
              _InfoChip(
                icon: Icons.people_outline_rounded,
                label: '124 avis',
                iconColor: AppColors.grey500,
              ),
              SizedBox(width: AppDimens.sm),
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: '20-30 min',
                iconColor: AppColors.grey500,
              ),
            ],
          ),

          SizedBox(height: AppDimens.md),

          // ── Nom + Prix ───────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  produit.nom,
                  style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                    fontSize: 22.sp,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(width: AppDimens.md),
              Text(
                '${produit.prix.toInt()} F',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: AppDimens.md),

          // ── Description ──────────────────────────────
          Text(
            produit.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey600,
              height: 1.65,
            ),
          ),

          // Marge de fin, pour que la description ne colle pas à la
          // barre d'ajout. Les sections « Choisir la taille » et
          // « Ajouter des extras » qui suivaient ont été retirées :
          // elles étaient écrites en dur, le backend ne renvoie ni
          // tailles ni suppléments.
          SizedBox(height: AppDimens.xl),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int total) {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: AppDimens.md,
        bottom: MediaQuery.of(context).padding.bottom + AppDimens.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20.r,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Sélecteur quantité ───────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius:
                  BorderRadius.circular(AppDimens.radiusFull),
            ),
            child: Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    if (_quantity > 1) {
                      HapticFeedback.selectionClick();
                      setState(() => _quantity--);
                    }
                  },
                ),
                SizedBox(
                  width: 32.w,
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _quantity++);
                  },
                ),
              ],
            ),
          ),

          SizedBox(width: AppDimens.md),

          // ── Bouton Ajouter ───────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: (ref.watch(cartProvider).isAdding || _added)
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      final success = await ref
                          .read(cartProvider.notifier)
                          .addToCart(
                            produitId : widget.produitId,
                            quantite  : _quantity,
                          );
                      if (!mounted) return;
                      if (success) {
                        HapticFeedback.mediumImpact();
                        setState(() => _added = true);
                        await Future.delayed(
                            const Duration(milliseconds: 900));
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ref.read(cartProvider).error ??
                                  'Erreur lors de l\'ajout',
                            ),
                            backgroundColor : AppColors.error,
                            duration        : const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              child: AnimatedContainer(
                duration : const Duration(milliseconds: 300),
                curve    : Curves.easeOut,
                height   : 54.h,
                decoration: BoxDecoration(
                  color: _added
                      ? AppColors.success
                      : ref.watch(cartProvider).isAdding
                          ? AppColors.grey400
                          : null,
                  gradient: (_added || ref.watch(cartProvider).isAdding)
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.primary],
                          begin  : Alignment.topLeft,
                          end    : Alignment.bottomRight,
                        ),
                  borderRadius :
                      BorderRadius.circular(AppDimens.radiusFull),
                  boxShadow: (_added || ref.watch(cartProvider).isAdding)
                      ? null
                      : [
                          BoxShadow(
                            color     : AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 14.r,
                            offset    : const Offset(0, 5),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: ref.watch(cartProvider).isAdding
                    ? SizedBox(
                        width : 22.r, height: 22.r,
                        child : CircularProgressIndicator(
                          strokeWidth : 2.5.r,
                          color       : Colors.white,
                        ),
                      )
                    : _added
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 20.r),
                              SizedBox(width: 8.w),
                              Text(
                                'Ajouté au panier !',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color      : Colors.white,
                                  fontWeight : FontWeight.w700,
                                  fontSize   : 15.sp,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Ajouter  •  $total F',
                            style: AppTextStyles.labelMedium.copyWith(
                              color      : Colors.white,
                              fontWeight : FontWeight.w700,
                              fontSize   : 15.sp,
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets réutilisables ──────────────────────────────────

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20.r, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });
  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: iconColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        width: 44.r,
        height: 44.r,
        child: Icon(icon, size: 20.r, color: AppColors.dark),
      ),
    );
  }
}
