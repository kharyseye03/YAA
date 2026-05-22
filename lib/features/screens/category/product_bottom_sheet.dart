import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/cart/providers/cart_notifier.dart';
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
  int _quantity = 1;
  bool _isFavorite = false;
  int _selectedSize = 1;

  static const _sizes = ['Petite', 'Normale', 'Grande'];
  static const _sizeMultipliers = [0.8, 1.0, 1.3];

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(produitDetailProvider(widget.produitId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.93,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
        data: (produit) {
          final total =
              (produit.prix * _sizeMultipliers[_selectedSize] * _quantity)
                  .round();
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Image.network(
            produit.imageUrl,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 300,
              color: AppColors.grey100,
              child: const Center(
                child: Icon(Icons.image_outlined,
                    color: AppColors.grey400, size: 64),
              ),
            ),
          ),
        ),

        // ── Gradient haut (lisibilité boutons) ──────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              height: 90,
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
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 110,
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
        const Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                ),
              ),
            ),
          ),
        ),

        // ── Bouton fermer ────────────────────────────────
        Positioned(
          top: 16,
          right: 16,
          child: _GlassButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),

        // ── Bouton favori ────────────────────────────────
        Positioned(
          top: 16,
          left: 16,
          child: _GlassButton(
            icon: _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: _isFavorite ? const Color(0xFFFF4D6D) : Colors.white,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
        ),

        // ── Badge "Populaire" ────────────────────────────
        Positioned(
          bottom: 20,
          left: AppDimens.screenPadding,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
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
      padding: const EdgeInsets.fromLTRB(
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
              const SizedBox(width: AppDimens.sm),
              _InfoChip(
                icon: Icons.people_outline_rounded,
                label: '124 avis',
                iconColor: AppColors.grey500,
              ),
              const SizedBox(width: AppDimens.sm),
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: '20-30 min',
                iconColor: AppColors.grey500,
              ),
            ],
          ),

          const SizedBox(height: AppDimens.md),

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
                    fontSize: 22,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Text(
                '${produit.prix.toInt()} F',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.md),

          // ── Description ──────────────────────────────
          Text(
            produit.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey600,
              height: 1.65,
            ),
          ),

          const SizedBox(height: AppDimens.xl),

          // ── Séparateur ───────────────────────────────
          Container(height: 1, color: AppColors.grey100),

          const SizedBox(height: AppDimens.xl),

          // ── Section taille ───────────────────────────
          _SectionLabel(
            title: 'Choisir la taille',
            subtitle: 'Requis · Choisissez 1',
          ),

          const SizedBox(height: AppDimens.md),

          Row(
            children: List.generate(_sizes.length, (i) {
              final selected = _selectedSize == i;
              return Padding(
                padding: EdgeInsets.only(
                    right: i < _sizes.length - 1 ? AppDimens.sm : 0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedSize = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.grey100,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusFull),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      _sizes[i],
                      style: AppTextStyles.labelMedium.copyWith(
                        color:
                            selected ? Colors.white : AppColors.grey700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: AppDimens.xl),

          // ── Section extras ───────────────────────────
          _SectionLabel(
            title: 'Ajouter des extras',
            subtitle: 'Optionnel',
          ),

          const SizedBox(height: AppDimens.md),

          Wrap(
            spacing: AppDimens.sm,
            runSpacing: AppDimens.sm,
            children: const [
              _ExtraChip(label: 'Sauce piquante', price: '+200 F'),
              _ExtraChip(label: 'Fromage', price: '+300 F'),
              _ExtraChip(label: 'Sauce fromagère', price: '+250 F'),
              _ExtraChip(label: 'Extra viande', price: '+500 F'),
            ],
          ),

          const SizedBox(height: AppDimens.xxl),
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
            blurRadius: 20,
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
                  width: 32,
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
                  icon: Icons.add_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _quantity++);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: AppDimens.md),

          // ── Bouton Ajouter ───────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: ref.watch(cartProvider).isAdding
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      final success = await ref
                          .read(cartProvider.notifier)
                          .addToCart(
                            produitId : widget.produitId,
                            quantite  : _quantity,
                          );
                      if (!context.mounted) return;
                      if (success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content         : Text('Ajouté au panier ✓'),
                            backgroundColor : AppColors.primary,
                            duration        : Duration(seconds: 2),
                          ),
                        );
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
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: ref.watch(cartProvider).isAdding
                        ? [AppColors.grey400, AppColors.grey400]
                        : [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusFull),
                  boxShadow: ref.watch(cartProvider).isAdding
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: ref.watch(cartProvider).isAdding
                    ? const SizedBox(
                        width  : 22,
                        height : 22,
                        child  : CircularProgressIndicator(
                          strokeWidth : 2.5,
                          color       : Colors.white,
                        ),
                      )
                    : Text(
                        'Ajouter  •  $total F',
                        style: AppTextStyles.labelMedium.copyWith(
                          color      : Colors.white,
                          fontWeight : FontWeight.w700,
                          fontSize   : 15,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
        ),
      ],
    );
  }
}

class _ExtraChip extends StatefulWidget {
  const _ExtraChip({required this.label, required this.price});
  final String label;
  final String price;

  @override
  State<_ExtraChip> createState() => _ExtraChipState();
}

class _ExtraChipState extends State<_ExtraChip> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = !_selected);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _selected ? AppColors.primarySurface : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(
            color: _selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selected
                  ? const Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.primary),
                    )
                  : const SizedBox.shrink(),
            ),
            Text(
              widget.label,
              style: AppTextStyles.caption.copyWith(
                color: _selected ? AppColors.primary : AppColors.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.price,
              style: AppTextStyles.caption.copyWith(
                color: _selected ? AppColors.primaryLight : AppColors.grey500,
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
