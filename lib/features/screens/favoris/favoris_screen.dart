import '../../../core/utils/devise.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/favoris/providers/favori_notifier.dart';
import '../../../model/favori/produit_favori_model.dart';
import '../../../model/favori/structure_favori_model.dart';

class FavorisScreen extends ConsumerStatefulWidget {
  const FavorisScreen({super.key});

  @override
  ConsumerState<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends ConsumerState<FavorisScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(favoriProvider.notifier).loadFavoris();
      ref.read(favoriProvider.notifier).loadProduitsFavoris();
    });
  }

  Future<void> _refresh() async {
    await ref.read(favoriProvider.notifier).loadFavoris();
    await ref.read(favoriProvider.notifier).loadProduitsFavoris();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoriProvider);

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),

        // ── En-tête ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.screenPadding, 14,
            AppDimens.screenPadding, 0,
          ),
          child: Row(
            children: [
              Text(
                'Mes favoris',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Tabs ─────────────────────────────────────────────
        _Tabs(current: _tab, onTap: (i) => setState(() => _tab = i),
              counts: [state.favoris.length, state.produitsFavoris.length]),

        // ── Erreur ────────────────────────────────────────────
        if (state.error != null)
          Container(
            width  : double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding, vertical: 10),
            color  : AppColors.errorLight,
            child  : Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(state.error!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error)),
                ),
              ],
            ),
          ),

        // ── Contenu ───────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: _tab == 0
                      ? _buildStructures(state)
                      : _buildProduits(state),
                ),
        ),
      ],
    );
  }

  Widget _buildStructures(FavoriState state) {
    if (state.favoris.isEmpty) {
      return const _Empty(
        icon: Icons.storefront_outlined,
        message: 'Aucun établissement favori',
        hint: 'Appuyez sur le cœur d\'un établissement\npour l\'ajouter ici.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding, 16,
          AppDimens.screenPadding, 90),
      itemCount: state.favoris.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final f = state.favoris[i];
        return _StructureCard(
          favori    : f,
          isToggling: state.isToggling(f.structureId),
          onToggle  : () => ref
              .read(favoriProvider.notifier)
              .toggleFavori(f.structureId),
        );
      },
    );
  }

  Widget _buildProduits(FavoriState state) {
    if (state.produitsFavoris.isEmpty) {
      return const _Empty(
        icon: Icons.fastfood_outlined,
        message: 'Aucun produit favori',
        hint: 'Appuyez sur le cœur d\'un produit\npour l\'ajouter ici.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding, 16,
          AppDimens.screenPadding, 90),
      itemCount: state.produitsFavoris.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final p = state.produitsFavoris[i];
        return _ProduitCard(
          favori    : p,
          isToggling: state.isToggling(p.produitId),
          onToggle  : () => ref
              .read(favoriProvider.notifier)
              .toggleProduitFavori(p.produitId),
        );
      },
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────
class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.current,
    required this.onTap,
    required this.counts,
  });
  final int            current;
  final ValueChanged<int> onTap;
  final List<int>      counts;

  @override
  Widget build(BuildContext context) {
    const labels = ['Établissements', 'Produits'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(2, (i) {
            final active = i == current;
            return Expanded(
              child: GestureDetector(
                onTap    : () => onTap(i),
                behavior : HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        labels[i],
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize   : 14,
                          fontWeight : active ? FontWeight.w700 : FontWeight.w500,
                          color      : active ? AppColors.dark : AppColors.grey400,
                        ),
                      ),
                      if (counts[i] > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color        : active
                                ? AppColors.primary
                                : AppColors.grey200,
                            borderRadius : BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${counts[i]}',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize   : 11,
                              fontWeight : FontWeight.w700,
                              color      : active
                                  ? Colors.white
                                  : AppColors.grey500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        Stack(
          children: [
            Container(height: 1, color: AppColors.grey200),
            AnimatedAlign(
              duration  : const Duration(milliseconds: 200),
              curve     : Curves.easeInOut,
              alignment : current == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(height: 2, color: AppColors.dark),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Carte structure ───────────────────────────────────────────
class _StructureCard extends StatelessWidget {
  const _StructureCard({
    required this.favori,
    required this.isToggling,
    required this.onToggle,
  });
  final StructureFavoriModel favori;
  final bool                 isToggling;
  final VoidCallback         onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.circular(16),
        boxShadow    : [
          BoxShadow(
            color      : Colors.black.withValues(alpha: 0.06),
            blurRadius : 16,
            offset     : const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft    : Radius.circular(16),
              bottomLeft : Radius.circular(16),
            ),
            child: favori.logoUrl != null
                ? Image.network(favori.logoUrl!,
                    width: 90, height: 90, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(Icons.storefront_outlined))
                : _fallback(Icons.storefront_outlined),
          ),

          // Infos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(favori.nom,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700, fontSize: 15,
                        color: AppColors.dark),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (favori.adresse.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.grey400),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(favori.adresse,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.grey500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    const SizedBox(height: 4),
                  ],
                  Row(children: [
                    Icon(Icons.star_rounded,
                        size: 14, color: Colors.amber.shade600),
                    const SizedBox(width: 3),
                    Text('${favori.nombreEtoile}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600, color: AppColors.dark)),
                    const SizedBox(width: 10),
                    SvgPicture.asset('assets/icones/motorcycle-fill.svg',
                        width: 13, height: 13,
                        colorFilter: const ColorFilter.mode(
                            AppColors.grey400, BlendMode.srcIn)),
                    const SizedBox(width: 4),
                    Text(favori.tempsLivraison,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey500)),
                  ]),
                ],
              ),
            ),
          ),

          // Bouton cœur
          _HeartButton(isToggling: isToggling, onToggle: onToggle),
        ],
      ),
    );
  }

  Widget _fallback(IconData icon) => Container(
      width: 90, height: 90, color: AppColors.grey100,
      child: Icon(icon, color: AppColors.grey400, size: 32));
}

// ── Carte produit ─────────────────────────────────────────────
class _ProduitCard extends StatelessWidget {
  const _ProduitCard({
    required this.favori,
    required this.isToggling,
    required this.onToggle,
  });
  final ProduitFavoriModel favori;
  final bool               isToggling;
  final VoidCallback       onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.circular(16),
        boxShadow    : [
          BoxShadow(
            color      : Colors.black.withValues(alpha: 0.06),
            blurRadius : 16,
            offset     : const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image produit
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft    : Radius.circular(16),
              bottomLeft : Radius.circular(16),
            ),
            child: favori.imageUrl != null
                ? Image.network(favori.imageUrl!,
                    width: 90, height: 90, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback())
                : _fallback(),
          ),

          // Infos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(favori.nom,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700, fontSize: 15,
                        color: AppColors.dark),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  // Prix
                  Text(
                    montantLabel(favori.prix),
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight : FontWeight.w800,
                      fontSize   : 14,
                      color      : AppColors.primary,
                    ),
                  ),
                  if (favori.structureName != null &&
                      favori.structureName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.storefront_outlined,
                          size: 13, color: AppColors.grey400),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(favori.structureName!,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.grey500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),

          // Bouton cœur
          _HeartButton(isToggling: isToggling, onToggle: onToggle),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
      width: 90, height: 90, color: AppColors.grey100,
      child: const Icon(Icons.fastfood_outlined,
          color: AppColors.grey400, size: 32));
}

// ── Bouton cœur partagé ───────────────────────────────────────
class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.isToggling, required this.onToggle});
  final bool         isToggling;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap    : isToggling ? null : onToggle,
        behavior : HitTestBehavior.opaque,
        child: Container(
          width  : 36,
          height : 36,
          decoration: const BoxDecoration(
            color : AppColors.errorLight,
            shape : BoxShape.circle,
          ),
          child: isToggling
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.error),
                )
              : const Icon(Icons.favorite_rounded,
                  color: AppColors.error, size: 18),
        ),
      ),
    );
  }
}

// ── État vide ─────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.message,
    required this.hint,
  });
  final IconData icon;
  final String   message;
  final String   hint;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.errorLight, shape: BoxShape.circle),
                child: Icon(icon, size: 36, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text(message,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.dark)),
              const SizedBox(height: 6),
              Text(hint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}
