import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../model/category/categorie_produit.dart';
import 'category_filters.dart';

/// Panneau de filtres de l'écran Catégorie.
///
/// Renvoie les critères retenus, ou null si l'utilisateur ferme
/// sans valider — dans ce cas l'appelant garde les siens.
Future<CategoryFilters?> showCategoryFiltersSheet(
  BuildContext context, {
  required CategoryFilters filtres,
  required List<CategorieProduit> categories,
}) {
  return showModalBottomSheet<CategoryFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoryFiltersSheet(
      filtresInitiaux: filtres,
      categories: categories,
    ),
  );
}

class _CategoryFiltersSheet extends StatefulWidget {
  const _CategoryFiltersSheet({
    required this.filtresInitiaux,
    required this.categories,
  });

  final CategoryFilters filtresInitiaux;
  final List<CategorieProduit> categories;

  @override
  State<_CategoryFiltersSheet> createState() => _CategoryFiltersSheetState();
}

class _CategoryFiltersSheetState extends State<_CategoryFiltersSheet> {
  late CategoryFilters _filtres = widget.filtresInitiaux;

  static const _notes  = [0, 3, 4, 5];
  static const _temps  = [null, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPoignee(),
          _buildEntete(),
          const Divider(height: 1, color: AppColors.grey200),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding,
                AppDimens.lg,
                AppDimens.screenPadding,
                AppDimens.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.categories.isNotEmpty) ...[
                    _buildSection(
                      'Catégorie',
                      [
                        _chip(
                          'Tous',
                          actif: _filtres.categorie == null,
                          onTap: () => setState(
                            () => _filtres =
                                _filtres.copyWith(effacerCategorie: true),
                          ),
                        ),
                        ...widget.categories.map(
                          (c) => _chip(
                            c.nom,
                            actif: _filtres.categorie?.id == c.id,
                            onTap: () => setState(
                              () => _filtres = _filtres.copyWith(categorie: c),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimens.xl),
                  ],

                  _buildSection(
                    'Note minimale',
                    _notes.map((n) {
                      return _chip(
                        n == 0 ? 'Toutes' : '$n',
                        icone: n == 0 ? null : Icons.star_rounded,
                        couleurIcone: Colors.amber.shade600,
                        actif: _filtres.noteMin == n,
                        onTap: () => setState(
                          () => _filtres = _filtres.copyWith(noteMin: n),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: AppDimens.xl),

                  _buildSection(
                    'Temps de livraison',
                    _temps.map((t) {
                      return _chip(
                        t == null ? 'Peu importe' : 'Moins de $t min',
                        actif: _filtres.tempsMax == t,
                        onTap: () => setState(
                          () => _filtres = t == null
                              ? _filtres.copyWith(effacerTempsMax: true)
                              : _filtres.copyWith(tempsMax: t),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: AppDimens.xl),

                  _buildSection(
                    'Trier par',
                    TriStructures.values.map((t) {
                      return _chip(
                        t.libelle,
                        actif: _filtres.tri == t,
                        onTap: () => setState(
                          () => _filtres = _filtres.copyWith(tri: t),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          _buildValidation(),
        ],
      ),
    );
  }

  Widget _buildPoignee() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.grey300,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
    );
  }

  Widget _buildEntete() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.screenPadding, 0, AppDimens.sm, AppDimens.md),
      child: Row(
        children: [
          Text(
            'Filtres',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const Spacer(),
          // Pas de bouton « Réinitialiser » inerte : il n'apparaît
          // que s'il y a quelque chose à réinitialiser
          if (!_filtres.estVierge)
            TextButton(
              onPressed: () =>
                  setState(() => _filtres = const CategoryFilters()),
              child: Text(
                'Réinitialiser',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String titre, List<Widget> puces) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titre,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.dark,
          ),
        ),
        SizedBox(height: AppDimens.md),
        Wrap(spacing: 8, runSpacing: 10, children: puces),
      ],
    );
  }

  Widget _chip(
    String libelle, {
    required bool actif,
    required VoidCallback onTap,
    IconData? icone,
    Color? couleurIcone,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: actif ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(
            color: actif ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: 15, color: couleurIcone ?? AppColors.dark),
              const SizedBox(width: 4),
            ],
            Text(
              libelle,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: actif ? Colors.white : AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidation() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.screenPadding,
        AppDimens.md,
        AppDimens.screenPadding,
        MediaQuery.of(context).padding.bottom + AppDimens.md,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_filtres),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            ),
          ),
          child: Text(
            'Voir les résultats',
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
