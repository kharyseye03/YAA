import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/devise.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../service/location/location_service.dart';

/// Blocs communs aux deux détails — celui d'une mission et celui
/// d'une commande d'établissement.
///
/// Les deux écrans montrent les mêmes choses puisées à des endroits
/// différents : un trajet, un coursier, des produits, des montants.
/// Les définir ici garantit qu'ils resteront identiques à l'œil.

/// Ouvre le composeur du téléphone avec le numéro pré-saisi.
/// Un appel réellement automatique exigerait la permission
/// CALL_PHONE, mal perçue à l'installation.
Future<void> appelerNumero(String? numero) async {
  if (numero == null || numero.isEmpty) return;
  final uri = Uri(scheme: 'tel', path: unformatPhone(numero));
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

// ── Titre de section ──────────────────────────────────────────
class SectionTitre extends StatelessWidget {
  const SectionTitre(this.titre, {super.key});
  final String titre;

  @override
  Widget build(BuildContext context) => Text(
        titre,
        style: AppTextStyles.labelMedium.copyWith(
          fontWeight : FontWeight.w700,
          fontSize   : 15,
          color      : AppColors.dark,
        ),
      );
}

// ── Coursier ──────────────────────────────────────────────────
/// Composition centrée : la personne d'abord, ses attributs ensuite.
class CarteCoursier extends StatelessWidget {
  const CarteCoursier({
    super.key,
    required this.nom,
    this.telephone,
    this.photoUrl,
    this.note,
  });

  final String  nom;
  final String? telephone;
  final String? photoUrl;
  final double? note;

  String get _initiales => nom
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((m) => m.isNotEmpty ? m[0] : '')
      .join()
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    final aTelephone = telephone != null && telephone!.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            width  : 76,
            height : 76,
            decoration: BoxDecoration(
              color : AppColors.primary,
              shape : BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color      : AppColors.primary.withValues(alpha: 0.22),
                  blurRadius : 16,
                  offset     : const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl == null
                  ? _avatarInitiales()
                  : Image.network(
                      photoUrl!,
                      width  : 76,
                      height : 76,
                      fit    : BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarInitiales(),
                    ),
            ),
          ),

          SizedBox(height: AppDimens.md),

          Text(
            nom,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w800,
              fontSize   : 16,
              color      : AppColors.dark,
            ),
          ),

          if (note != null || aTelephone) ...[
            SizedBox(height: AppDimens.md),
            Row(
              mainAxisSize      : MainAxisSize.min,
              mainAxisAlignment : MainAxisAlignment.center,
              children: [
                // Pas de pastille : sur fond blanc elle disparaîtrait.
                // L'étoile ambre suffit à porter la couleur.
                if (note != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 19, color: Colors.amber.shade600),
                      const SizedBox(width: 4),
                      Text(
                        note!.toStringAsFixed(1),
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize   : 15,
                          fontWeight : FontWeight.w800,
                          color      : AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                if (note != null && aTelephone)
                  SizedBox(width: AppDimens.lg),
                if (aTelephone)
                  GestureDetector(
                    onTap: () => appelerNumero(telephone),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color        : AppColors.success,
                        borderRadius :
                            BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 7),
                          Text(
                            'Appeler',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize   : 13,
                              fontWeight : FontWeight.w700,
                              color      : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarInitiales() => Center(
        child: Text(
          _initiales.isEmpty ? '?' : _initiales,
          style: const TextStyle(
            fontFamily : 'PlusJakartaSans',
            fontSize   : 22,
            fontWeight : FontWeight.w800,
            color      : Colors.white,
          ),
        ),
      );
}

// ── Trajet A → B ──────────────────────────────────────────────
class TrajetAB extends StatelessWidget {
  const TrajetAB({
    super.key,
    required this.depart,
    required this.arrivee,
    this.meta = '',
    this.labelDepart  = 'Départ',
    this.labelArrivee = 'Arrivée',
  });

  final String depart;
  final String arrivee;

  /// « 3,9 km · 13 min » — vide si la source ne les fournit pas
  final String meta;
  final String labelDepart;
  final String labelArrivee;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Point(
          couleur : AppColors.primary,
          label   : labelDepart,
          valeur  : LocationService.cleanAddress(depart),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 7),
          child: Row(
            children: [
              Container(width: 2, height: 26, color: AppColors.grey200),
              SizedBox(width: AppDimens.lg),
              if (meta.isNotEmpty)
                Text(
                  meta,
                  style: AppTextStyles.bodySmall.copyWith(
                    color      : AppColors.textSoft,
                    fontWeight : FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        _Point(
          couleur : AppColors.secondary,
          label   : labelArrivee,
          valeur  : LocationService.cleanAddress(arrivee),
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.couleur,
    required this.label,
    required this.valeur,
  });

  final Color  couleur;
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width  : 16,
          height : 16,
          margin : const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            shape  : BoxShape.circle,
            color  : couleur.withValues(alpha: 0.15),
            border : Border.all(color: couleur, width: 2),
          ),
        ),
        SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color      : AppColors.textSoft,
                  fontWeight : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valeur,
                style: AppTextStyles.labelSmall.copyWith(
                  color      : AppColors.dark,
                  fontWeight : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Ligne produit ─────────────────────────────────────────────
class LigneProduit extends StatelessWidget {
  const LigneProduit({
    super.key,
    required this.nom,
    required this.quantite,
    required this.prixUnitaire,
    required this.prixTotal,
    this.imageUrl,
  });

  final String  nom;
  final int     quantite;
  final double  prixUnitaire;
  final double  prixTotal;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimens.md),
      child: Row(
        children: [
          // Vignette, avec la quantité posée dessus
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: imageUrl == null
                    ? const _VignetteVide()
                    : Image.network(
                        imageUrl!,
                        width  : 48,
                        height : 48,
                        fit    : BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _VignetteVide(),
                      ),
              ),
              Positioned(
                right : 0,
                bottom: 0,
                child : Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: const BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.only(
                      topLeft     : Radius.circular(6),
                      bottomRight : Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    '×$quantite',
                    style: AppTextStyles.caption.copyWith(
                      fontSize   : 10,
                      fontWeight : FontWeight.w800,
                      color      : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight : FontWeight.w600,
                    color      : AppColors.dark,
                  ),
                  maxLines : 1,
                  overflow : TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${montantLabel(prixUnitaire)} l\'unité',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSoft),
                ),
              ],
            ),
          ),
          SizedBox(width: AppDimens.sm),
          Text(
            montantLabel(prixTotal),
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight : FontWeight.w700,
              color      : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _VignetteVide extends StatelessWidget {
  const _VignetteVide();

  @override
  Widget build(BuildContext context) => Container(
        width  : 48,
        height : 48,
        color  : AppColors.grey100,
        child  : const Icon(Icons.shopping_bag_outlined,
            size: 20, color: AppColors.grey400),
      );
}

// ── Ligne de montant ──────────────────────────────────────────
class LigneMontant extends StatelessWidget {
  const LigneMontant(this.label, this.valeur, {super.key, this.fort = false});

  final String label;
  final String valeur;

  /// Ligne de total : plus grande et plus grasse
  final bool fort;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color      : fort ? AppColors.dark : AppColors.textSoft,
            fontWeight : fort ? FontWeight.w700 : FontWeight.w500,
            fontSize   : fort ? 15 : 14,
          ),
        ),
        const Spacer(),
        Text(
          valeur,
          style: TextStyle(
            fontFamily : 'PlusJakartaSans',
            fontSize   : fort ? 20 : 14,
            fontWeight : fort ? FontWeight.w800 : FontWeight.w600,
            color      : AppColors.dark,
          ),
        ),
      ],
    );
  }
}

// ── Encadré de consigne ───────────────────────────────────────
class EncadreConsigne extends StatelessWidget {
  const EncadreConsigne(this.texte, {super.key});
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      width   : double.infinity,
      padding : EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color        : AppColors.secondaryLight,
        borderRadius : BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Text(
        texte,
        style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.dark, height: 1.5),
      ),
    );
  }
}

// ── Contact cliquable ─────────────────────────────────────────
class LigneContact extends StatelessWidget {
  const LigneContact({super.key, required this.role, required this.numero});

  final String role;
  final String numero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap    : () => appelerNumero(numero),
      behavior : HitTestBehavior.opaque,
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, size: 17, color: AppColors.textSoft),
          SizedBox(width: AppDimens.md),
          Expanded(
            child: Text(
              role,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSoft),
            ),
          ),
          Text(
            formatPhone(numero),
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight : FontWeight.w700,
              color      : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Enveloppe commune des deux sheets ─────────────────────────
/// Poignée, coins arrondis, hauteur bornée et défilement : la coquille
/// est identique pour le détail d'une mission et celui d'une commande.
class SheetDetail extends StatelessWidget {
  const SheetDetail({super.key, required this.enfant});
  final Widget enfant;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width  : 40,
            height : 4,
            margin : const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color        : AppColors.grey300,
              borderRadius : BorderRadius.circular(AppDimens.radiusFull),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding,
                AppDimens.sm,
                AppDimens.screenPadding,
                MediaQuery.of(context).padding.bottom + AppDimens.xxl,
              ),
              child: enfant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── En-tête : type, référence, statut ─────────────────────────
class EnTeteDetail extends StatelessWidget {
  const EnTeteDetail({
    super.key,
    required this.icone,
    required this.titre,
    required this.reference,
    required this.statut,
  });

  final IconData icone;
  final String   titre;
  final String   reference;
  final ({String label, Color color, Color bgColor}) statut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width  : 44,
          height : 44,
          decoration: BoxDecoration(
            color        : AppColors.primarySurface,
            borderRadius : BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Icon(icone, size: 20, color: AppColors.primary),
        ),
        SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w800,
                  fontSize   : 16,
                  color      : AppColors.dark,
                ),
              ),
              Text(
                reference,
                style: AppTextStyles.caption.copyWith(
                  color      : AppColors.textSoft,
                  fontWeight : FontWeight.w600,
                ),
                maxLines : 1,
                overflow : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: AppDimens.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color        : statut.bgColor,
            borderRadius : BorderRadius.circular(AppDimens.radiusFull),
          ),
          child: Text(
            statut.label,
            style: AppTextStyles.labelSmall.copyWith(
              color      : statut.color,
              fontWeight : FontWeight.w700,
              fontSize   : 11,
            ),
          ),
        ),
      ],
    );
  }
}
