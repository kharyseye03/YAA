import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../model/category/structure.dart';
import '../category/restaurant_bottom_sheet.dart';
import '../home/providers/category_provider.dart';
import '../home/restaurant_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Debounce : on attend que l'utilisateur arrête de taper
  // avant d'interroger l'API
  void _onChanged(String value) {
    setState(() {}); // met à jour l'affichage (tags / résultats)
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _onTagTap(String tag) {
    _controller.text = tag;
    setState(() => _query = tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.dark),
          decoration: InputDecoration(
            hintText: 'Rechercher un produit, restaurant…',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey400,
            ),
            border: InputBorder.none,
            prefixIcon: PhosphorIcon(
              PhosphorIcons.magnifyingGlass(),
              color: AppColors.grey400,
              size: 20,
            ),
          ),
          onChanged: _onChanged,
        ),
      ),
      body: _controller.text.isEmpty
          ? _buildPopularTags()
          : _buildResults(),
    );
  }

  // ── Recherches populaires (champ vide) ────────────────────────
  Widget _buildPopularTags() {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recherches populaires',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Burger', 'Pizza', 'Pharmacie', 'Boutique', 'Épicerie',
            ].map((tag) => GestureDetector(
              onTap: () => _onTagTap(tag),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: Text(
                  tag,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ── Résultats de recherche ────────────────────────────────────
  Widget _buildResults() {
    // On attend la fin du debounce avant d'interroger l'API
    if (_query.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ref.watch(searchStructuresProvider(_query)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Erreur lors de la recherche',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
        ),
      ),
      data: (structures) {
        if (structures.isEmpty) {
          return Center(
            child: Text(
              'Aucun résultat pour "${_controller.text}"',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey400,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppDimens.screenPadding),
          itemCount: structures.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimens.md),
          itemBuilder: (_, i) => _ResultCard(structure: structures[i]),
        );
      },
    );
  }
}

// ── Carte résultat ──────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.structure});

  final Structure structure;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showRestaurantBottomSheet(
        context,
        RestaurantData(
          name         : structure.name,
          cuisine      : structure.categorie,
          rating       : structure.nombreEtoile.toDouble(),
          deliveryTime : structure.tempsLivraison,
          imageUrl     : structure.logoUrl,
        ),
        structureId  : structure.id,
        categoryType : structure.categorie,
      ),
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Row(
        children: [
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: Image.network(
              structure.logoUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: AppColors.grey100,
                child: const Icon(Icons.storefront_outlined,
                    color: AppColors.grey400, size: 26),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  structure.name,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${structure.categorie} • ${structure.adresse}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        size: 14, color: Colors.amber.shade600),
                    const SizedBox(width: 2),
                    Text(
                      '${structure.nombreEtoile}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: AppColors.grey500),
                    const SizedBox(width: 3),
                    Text(
                      structure.tempsLivraison,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right_rounded,
              color: AppColors.grey400, size: 22),
        ],
      ),
    );
  }
}
