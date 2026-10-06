import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/api/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_contacts.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/errors/messages_erreur.dart';
import '../../../core/utils/journal.dart';
import '../../../service/api/api_service.dart';
import '../../user/providers/user_notifier.dart';

/// Suppression du compte.
///
/// **Pourquoi cet écran existe.** Google Play l'impose depuis avril
/// 2024 à toute application permettant de créer un compte : un chemin
/// de suppression doit exister *dans* l'app, en plus d'une page web.
/// Une app non conforme peut être retirée du magasin.
///
/// **Deux temps, volontairement.** L'action est irréversible et sans
/// recours. Une simple boîte « Êtes-vous sûr ? » se valide par réflexe ;
/// ici il faut lire ce qui disparaît, puis cocher une case avant que le
/// bouton ne s'active. Le frein est délibéré.
///
/// **Deux chemins.** Si l'identifiant du client est connu, l'écran
/// appelle DELETE /registrations/id. Sinon — profil pas encore chargé,
/// ou backend qui ne renvoie pas cet id — il ouvre un e-mail prérempli
/// vers le support, ce que Play accepte également. Mieux vaut une
/// demande qui part qu'un bouton qui échoue.
Future<bool> showSuppressionCompteSheet(BuildContext context) async {
  final supprime = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Sortie possible d'un geste : personne ne doit se sentir piégé
    // dans un écran de suppression.
    isDismissible: true,
    builder: (_) => const _SuppressionSheet(),
  );
  return supprime ?? false;
}

class _SuppressionSheet extends ConsumerStatefulWidget {
  const _SuppressionSheet();

  @override
  ConsumerState<_SuppressionSheet> createState() => _SuppressionSheetState();
}

class _SuppressionSheetState extends ConsumerState<_SuppressionSheet> {
  bool    _compris    = false;
  bool    _enCours    = false;
  String? _erreur;

  Future<void> _supprimer(int id) async {
    setState(() { _enCours = true; _erreur = null; });
    try {
      await ApiService().supprimerCompte(id: id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      journal('❌ suppression compte: $e');
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _erreur  = MessagesErreur.depuisException(e);
      });
    }
  }

  /// Ouvre un e-mail prérempli vers le support.
  ///
  /// Repli quand l'identifiant du client est inconnu. L'objet et le corps
  /// sont écrits d'avance : quelqu'un qui veut partir ne doit pas avoir
  /// à chercher quoi écrire.
  Future<void> _ecrireAuSupport() async {
    final uri = Uri(
      scheme : 'mailto',
      path   : AppContacts.emailSupport,
      query  : Uri.encodeFull(
        'subject=Suppression de mon compte YAA'
        '&body=Bonjour,\n\nJe souhaite supprimer mon compte YAA ainsi '
        'que les données associées.\n\nMerci de me confirmer la '
        'suppression.\n',
      ),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    if (!mounted) return;
    setState(() => _erreur = 'Aucune application e-mail sur cet appareil.');
  }

  @override
  Widget build(BuildContext context) {
    // L'endpoint réclame l'identifiant du client dans l'URL. Sans lui
    // — profil pas encore chargé, ou backend qui ne le renvoie pas —
    // on ne peut pas construire l'appel : on bascule sur la demande
    // par e-mail plutôt que d'échouer devant l'utilisateur.
    final idClient = ref.watch(userProvider).profile?.id;
    final disponible =
        ApiConfig.suppressionCompteDisponible && idClient != null;

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(AppDimens.md),
        padding: EdgeInsets.fromLTRB(
          AppDimens.lg, AppDimens.lg, AppDimens.lg, AppDimens.md),
        decoration: BoxDecoration(
          color        : AppColors.surface,
          borderRadius : BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width  : 36.r,
                  height : 36.r,
                  decoration: BoxDecoration(
                    color        : AppColors.errorLight,
                    borderRadius : BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 20.r),
                ),
                SizedBox(width: AppDimens.md),
                Expanded(
                  child: Text(
                    'Supprimer mon compte',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color     : AppColors.dark,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppDimens.lg),

            Text(
              disponible
                  ? 'Cette action est définitive. Seront supprimés :'
                  : 'Votre demande sera traitée par notre équipe. '
                    'Seront supprimés :',
              style: AppTextStyles.bodySmall.copyWith(
                color : AppColors.textSoft,
                height: 1.5,
              ),
            ),

            SizedBox(height: AppDimens.md),

            // Nommer ce qui disparaît, plutôt qu'un vague « vos
            // données » : quelqu'un doit pouvoir mesurer ce qu'il perd
            // avant de décider.
            ...[
              'Votre profil, vos coordonnées et votre adresse',
              'Votre historique de commandes et de courses',
              'Vos favoris et votre panier en cours',
            ].map((texte) => Padding(
              padding: EdgeInsets.only(bottom: AppDimens.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Container(
                      width  : 4.r,
                      height : 4.r,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: Text(
                      texte,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.dark, height: 1.45),
                    ),
                  ),
                ],
              ),
            )),

            SizedBox(height: AppDimens.xs),

            Text(
              'Les documents que la loi nous oblige à conserver, comme '
              'les pièces comptables, sont conservés puis anonymisés.',
              style: AppTextStyles.caption.copyWith(
                color : AppColors.textMuted,
                height: 1.45,
              ),
            ),

            SizedBox(height: AppDimens.lg),

            // Le verrou : le bouton reste inerte tant que la case n'est
            // pas cochée. Un geste de plus, mais un geste conscient.
            GestureDetector(
              onTap    : _enCours ? null : () =>
                  setState(() => _compris = !_compris),
              behavior : HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width  : 22.r,
                    height : 22.r,
                    decoration: BoxDecoration(
                      color        : _compris ? AppColors.error : null,
                      borderRadius : BorderRadius.circular(6.r),
                      border: Border.all(
                        color: _compris ? AppColors.error : AppColors.borderStrong,
                        width: 1.5,
                      ),
                    ),
                    child: _compris
                        ? Icon(Icons.check_rounded,
                            size: 15.r, color: Colors.white)
                        : null,
                  ),
                  SizedBox(width: AppDimens.md),
                  Expanded(
                    child: Text(
                      disponible
                          ? 'Je comprends que cette action est définitive '
                            'et que mes données ne pourront pas être '
                            'récupérées.'
                          : 'Je comprends que ma demande entraînera la '
                            'suppression définitive de mon compte.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color : AppColors.dark,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_erreur != null) ...[
              SizedBox(height: AppDimens.md),
              Container(
                width   : double.infinity,
                padding : EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color        : AppColors.errorLight,
                  borderRadius : BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Text(
                  _erreur!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error),
                ),
              ),
            ],

            SizedBox(height: AppDimens.lg),

            SizedBox(
              width  : double.infinity,
              height : 50.h,
              child: ElevatedButton(
                onPressed: (!_compris || _enCours)
                    ? null
                    : (disponible ? () => _supprimer(idClient) : _ecrireAuSupport),
                style: ElevatedButton.styleFrom(
                  backgroundColor        : AppColors.error,
                  foregroundColor        : Colors.white,
                  disabledBackgroundColor: AppColors.grey200,
                  disabledForegroundColor: AppColors.textMuted,
                  elevation              : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                ),
                child: _enCours
                    ? SizedBox(
                        width : 20.r,
                        height: 20.r,
                        child : CircularProgressIndicator(
                            strokeWidth: 2.r, color: Colors.white),
                      )
                    : Text(
                        disponible
                            ? 'Supprimer définitivement'
                            : 'Envoyer ma demande',
                        style: AppTextStyles.button
                            .copyWith(color: Colors.white),
                      ),
              ),
            ),

            TextButton(
              onPressed: _enCours ? null : () => Navigator.of(context).pop(false),
              child: Text(
                'Annuler',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color     : AppColors.textSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
