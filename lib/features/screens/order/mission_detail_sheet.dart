import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/devise.dart';
import '../../../features/orders/providers/commande_notifier.dart';
import '../../../model/order/commande_detail_model.dart';
import '../../../model/order/livraison_course_model.dart';
import '../../../service/storage/notation_storage.dart';
import '../../../shared/widgets/recherche_animation.dart';
import '../course/rating_sheet.dart';
import 'detail_widgets.dart';
import 'orders_screen.dart' show CommandeCard;

/// Détail d'une mission — colis, course ou livraison de commande.
///
/// Reçoit un **identifiant**, pas une copie de la mission : le sheet
/// relit l'objet dans le provider à chaque reconstruction. Sans ça,
/// un coursier qui accepte pendant que le client regarde l'écran ne
/// changerait rien à l'affichage, et l'animation d'attente tournerait
/// dans le vide.
Future<void> showMissionDetailSheet(BuildContext context, int missionId) {
  return showModalBottomSheet(
    context            : context,
    isScrollControlled : true,
    backgroundColor    : Colors.transparent,
    builder            : (_) => _MissionDetailSheet(missionId: missionId),
  );
}

class _MissionDetailSheet extends ConsumerStatefulWidget {
  const _MissionDetailSheet({required this.missionId});
  final int missionId;

  @override
  ConsumerState<_MissionDetailSheet> createState() =>
      _MissionDetailSheetState();
}

class _MissionDetailSheetState extends ConsumerState<_MissionDetailSheet> {
  @override
  void initState() {
    super.initState();
    // Une commande d'établissement a un contenu que la mission ignore :
    // structure et produits viennent d'un second appel.
    final m = _chercher(ref.read(commandeProvider).missions);
    if (m != null && m.hasDetail) {
      Future.microtask(
          () => ref.read(commandeProvider.notifier).loadDetail(m));
    }
    _verifierNotation();
  }

  /// null tant qu'on ne sait pas encore si la mission a été notée
  bool? _dejaNotee;

  Future<void> _verifierNotation() async {
    final vu = await NotationStorage.instance.dejaNotee(widget.missionId);
    if (mounted) setState(() => _dejaNotee = vu);
  }

  Future<void> _ouvrirNotation(LivraisonCourseModel m) async {
    await showRatingSheet(context, m);
    // Le sheet enregistre lui-même : on relit plutôt que de supposer
    // que le client est allé au bout.
    await _verifierNotation();
  }

  /// On ne relance que sur une mission achevée, confiée à quelqu'un,
  /// et pas encore notée.
  bool _notationAProposer(LivraisonCourseModel m) =>
      m.statut == 'COURSE_TERMINEE' &&
      m.livreur != null &&
      _dejaNotee == false;

  Widget _relanceNotation(LivraisonCourseModel m) {
    return GestureDetector(
      onTap    : () => _ouvrirNotation(m),
      behavior : HitTestBehavior.opaque,
      child: Container(
        width   : double.infinity,
        padding : const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(
          color        : AppColors.secondaryLight,
          borderRadius : BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Column(
          children: [
            Text(
              'Comment s\'est passée votre ${_motService(m)} ?',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight : FontWeight.w700,
                color      : AppColors.dark,
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            Text(
              'Votre avis aide ${m.livreur!.fullName.split(' ').first} '
              'et les prochains clients.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSoft, height: 1.4),
            ),
            const SizedBox(height: AppDimens.md),
            // Étoiles muettes : elles annoncent le geste, la notation
            // se fait dans le sheet dédié
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(Icons.star_rounded,
                      size: 30, color: Colors.amber.shade600),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            Text(
              'Toucher pour noter',
              style: AppTextStyles.caption.copyWith(
                color      : AppColors.secondaryDark,
                fontWeight : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _motService(LivraisonCourseModel m) =>
      switch (m.typeService) {
        TypeServiceMission.course            => 'course',
        TypeServiceMission.livraison         => 'livraison',
        TypeServiceMission.livraisonCommande => 'commande',
      };

  LivraisonCourseModel? _chercher(List<LivraisonCourseModel> missions) {
    for (final m in missions) {
      if (m.id == widget.missionId) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // On relit la mission à chaque build : elle change sous nos pieds
    // quand la liste se rafraîchit
    final etat    = ref.watch(commandeProvider);
    final mission = _chercher(etat.missions);

    return SheetDetail(
      enfant: mission == null
          ? const Padding(
              padding: EdgeInsets.all(AppDimens.xxxl),
              child: Center(child: Text('Mission introuvable')),
            )
          : _corps(mission, etat.detail),
    );
  }

  Widget _corps(LivraisonCourseModel m, CommandeDetailModel? detail) {
    final enRecherche = m.statut == 'RECHERCHE_COURSIER' ||
        m.statut == 'EN_ATTENTE_LIVREUR';
    final course = m.typeService == TypeServiceMission.course;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ① État — animation pendant l'attente, badge sinon
        if (enRecherche)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.xl),
            child: RechercheAnimation(
              titre   : 'Recherche d\'un ${course ? 'chauffeur' : 'livreur'}',
              message : 'Nous cherchons quelqu\'un de disponible '
                  'près du point de départ.',
              icone   : course
                  ? Icons.local_taxi_rounded
                  : Icons.sports_motorsports,
            ),
          )
        else
          EnTeteDetail(
            icone      : m.typeService.icon,
            titre      : m.typeService.label,
            reference  : m.code,
            statut     : CommandeCard.statusInfo(m.statut),
          ),

        // ② Le coursier, dès qu'il est assigné
        if (m.livreur != null) ...[
          const SizedBox(height: AppDimens.lg),
          CarteCoursier(
            nom       : m.livreur!.fullName,
            telephone : m.livreur!.telephone,
            photoUrl  : m.livreur!.photoUrl,
            note      : m.livreur!.noteMoyenne,
          ),
        ],

        // Relance de notation — pour les trois types de service.
        // L'écran de suivi ne la propose qu'aux missions créées depuis
        // l'app ; une commande d'établissement n'y passe jamais, et
        // rares sont les clients qui restent sur l'écran jusqu'au bout.
        if (_notationAProposer(m)) ...[
          const SizedBox(height: AppDimens.lg),
          _relanceNotation(m),
        ],

        const SizedBox(height: AppDimens.xl),

        // ③ Le trajet, toujours
        const SectionTitre('Trajet'),
        const SizedBox(height: AppDimens.md),
        TrajetAB(
          depart  : m.adresseDepart,
          arrivee : m.adresseArrivee,
          meta    : m.metaLabel,
        ),

        // ④ Le contenu, pour une commande d'établissement
        if (m.hasDetail) ...[
          const SizedBox(height: AppDimens.xl),
          const SectionTitre('Votre commande'),
          const SizedBox(height: AppDimens.md),
          ContenuCommande(detail: detail),
        ],

        // ⑤ Consignes et contacts, pour un envoi de colis
        if (m.typeService == TypeServiceMission.livraison) ...[
          if (m.instructions.isNotEmpty) ...[
            const SizedBox(height: AppDimens.xl),
            const SectionTitre('Consignes'),
            const SizedBox(height: AppDimens.sm),
            EncadreConsigne(m.instructions),
          ],
          if (m.telephoneExpediteur != null ||
              m.telephoneDestinataire != null) ...[
            const SizedBox(height: AppDimens.xl),
            const SectionTitre('Contacts'),
            const SizedBox(height: AppDimens.md),
            if (m.telephoneExpediteur != null)
              LigneContact(
                  role: 'Expéditeur', numero: m.telephoneExpediteur!),
            if (m.telephoneDestinataire != null) ...[
              const SizedBox(height: AppDimens.sm),
              LigneContact(
                  role: 'Destinataire', numero: m.telephoneDestinataire!),
            ],
          ],
        ],

        const SizedBox(height: AppDimens.xl),
        const Divider(height: 1, color: AppColors.grey200),
        const SizedBox(height: AppDimens.lg),

        // ⑥ Les montants
        _montants(m, detail),
      ],
    );
  }

  /// Sur une commande d'établissement, les produits et la livraison
  /// sont facturés séparément : les additionner en silence ferait
  /// disparaître l'information.
  Widget _montants(LivraisonCourseModel m, CommandeDetailModel? detail) {
    final produits = m.hasDetail ? detail?.montantTotal : null;
    if (produits == null) {
      return LigneMontant(
        'Montant',
        montantLabel(m.montant, devise: m.devise),
        fort: true,
      );
    }
    return Column(
      children: [
        LigneMontant('Commande', montantLabel(produits)),
        const SizedBox(height: AppDimens.sm),
        LigneMontant('Livraison', montantLabel(m.montant, devise: m.devise)),
        const SizedBox(height: AppDimens.md),
        const Divider(height: 1, color: AppColors.grey200),
        const SizedBox(height: AppDimens.md),
        LigneMontant(
          'Total',
          montantLabel(produits + m.montant, devise: m.devise),
          fort: true,
        ),
      ],
    );
  }
}

/// Liste des produits d'une commande, avec son établissement.
class ContenuCommande extends StatelessWidget {
  const ContenuCommande({super.key, required this.detail});
  final CommandeDetailModel? detail;

  @override
  Widget build(BuildContext context) {
    final d = detail;
    if (d == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimens.lg),
        child: Center(
          child: SizedBox(
            width  : 20,
            height : 20,
            child  : CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.storefront_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: AppDimens.sm),
            Expanded(
              child: Text(
                d.structureName,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight : FontWeight.w700,
                  color      : AppColors.dark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.md),
        ...d.commandeProduits.map(
          (p) => LigneProduit(
            nom          : p.nom,
            imageUrl     : p.imageUrl,
            quantite     : p.quantite,
            prixUnitaire : p.prixUnitaire,
            prixTotal    : p.prixTotal,
          ),
        ),
      ],
    );
  }
}
