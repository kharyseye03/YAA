import '../../../shared/widgets/image_reseau.dart';
import '../../../model/order/livraison_course_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          fontSize   : 15.sp,
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
    this.vehicule,
  });

  final String  nom;
  final String? telephone;
  final String? photoUrl;
  final double? note;

  /// Affiché sous le nom quand le coursier l'a renseigné
  final VehiculeCoursier? vehicule;

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
            width  : 76.r,
            height : 76.r,
            decoration: BoxDecoration(
              color : AppColors.primary,
              shape : BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color      : AppColors.primary.withValues(alpha: 0.22),
                  blurRadius : 16.r,
                  offset     : const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl == null
                  ? _avatarInitiales()
                  : ImageReseau(
                      url: photoUrl!,
                      width  : 76.r,
                      height : 76.r,
                      fit    : BoxFit.cover,
                      fallback: _avatarInitiales(),
                    ),
            ),
          ),

          SizedBox(height: AppDimens.md),

          Text(
            nom,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w800,
              fontSize   : 16.sp,
              color      : AppColors.dark,
            ),
          ),

          // ── Le véhicule ────────────────────────────────────
          // L'immatriculation est mise en avant comme une plaque :
          // c'est le seul élément qui permet de reconnaître l'engin
          // qui se gare devant chez soi.
          if (vehicule != null && !vehicule!.estVide) ...[
            // Le modèle et la couleur d'abord : c'est ce qu'on repère
            // de loin. La plaque ensuite, pour confirmer de près.
            if (vehicule!.description.isNotEmpty) ...[
              SizedBox(height: AppDimens.xs),
              Text(
                vehicule!.description.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize      : 13.sp,
                  fontWeight    : FontWeight.w700,
                  letterSpacing : 0.3,
                  color         : AppColors.textSoft,
                ),
                maxLines : 1,
                overflow : TextOverflow.ellipsis,
              ),
            ],
            if (vehicule!.immatriculation?.isNotEmpty ?? false) ...[
              SizedBox(height: AppDimens.sm),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.md, vertical: 6.h),
                decoration: BoxDecoration(
                  color        : AppColors.white,
                  borderRadius : BorderRadius.circular(AppDimens.radiusSm),
                  border       : Border.all(
                      color: AppColors.dark, width: 1.6),
                ),
                child: Text(
                  vehicule!.immatriculation!.toUpperCase(),
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize      : 19.sp,
                    fontWeight    : FontWeight.w800,
                    letterSpacing : 1.4,
                    color         : AppColors.dark,
                  ),
                ),
              ),
            ],
          ],

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
                          size: 19.r, color: Colors.amber.shade600),
                      SizedBox(width: 4.w),
                      Text(
                        note!.toStringAsFixed(1),
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize   : 15.sp,
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 7.h),
                      decoration: BoxDecoration(
                        color        : AppColors.success,
                        borderRadius :
                            BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_rounded,
                              color: Colors.white, size: 16.r),
                          SizedBox(width: 7.w),
                          Text(
                            'Appeler',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize   : 13.sp,
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
          style: TextStyle(
            fontFamily : 'PlusJakartaSans',
            fontSize   : 22.sp,
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
          padding: EdgeInsets.only(left: 7.w),
          child: Row(
            children: [
              Container(width: 2, height: 26.h, color: AppColors.grey200),
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
          width  : 16.r,
          height : 16.r,
          margin : EdgeInsets.only(top: 2.h),
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
                    : ImageReseau(
                        url: imageUrl!,
                        width  : 48.r,
                        height : 48.r,
                        fit    : BoxFit.cover,
                        fallback: const _VignetteVide(),
                      ),
              ),
              Positioned(
                right : 0.w,
                bottom: 0.h,
                child : Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 5.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.only(
                      topLeft     : Radius.circular(6.r),
                      bottomRight : Radius.circular(6.r),
                    ),
                  ),
                  child: Text(
                    '×$quantite',
                    style: AppTextStyles.caption.copyWith(
                      fontSize   : 10.sp,
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
        width  : 48.r,
        height : 48.r,
        color  : AppColors.grey100,
        child  : Icon(Icons.shopping_bag_outlined,
            size: 20.r, color: AppColors.grey400),
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
          Icon(Icons.phone_outlined, size: 17.r, color: AppColors.textSoft),
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
            width  : 40.w,
            height : 4.h,
            margin : EdgeInsets.symmetric(vertical: 12.h),
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
          width  : 44.r,
          height : 44.r,
          decoration: BoxDecoration(
            color        : AppColors.primarySurface,
            borderRadius : BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Icon(icone, size: 20.r, color: AppColors.primary),
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
                  fontSize   : 16.sp,
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
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color        : statut.bgColor,
            borderRadius : BorderRadius.circular(AppDimens.radiusFull),
          ),
          child: Text(
            statut.label,
            style: AppTextStyles.labelSmall.copyWith(
              color      : statut.color,
              fontWeight : FontWeight.w700,
              fontSize   : 11.sp,
            ),
          ),
        ),
      ],
    );
  }
}
