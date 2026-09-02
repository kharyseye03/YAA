import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/devise.dart';
import '../../../features/orders/providers/commande_notifier.dart';
import '../../../model/order/commande_detail_model.dart';
import '../../../model/order/commande_model.dart';
import '../../../shared/widgets/recherche_animation.dart';
import 'detail_widgets.dart';
import 'mission_detail_sheet.dart' show ContenuCommande;
import 'orders_screen.dart' show CommandeCard;

/// Détail d'une commande passée chez un commerçant.
///
/// Même squelette que le détail d'une mission — état, coursier,
/// trajet, contenu, montants — mais alimenté par
/// `/commandes-clients/detail`.
Future<void> showCommandeDetailSheet(BuildContext context, int commandeId) {
  return showModalBottomSheet(
    context            : context,
    isScrollControlled : true,
    backgroundColor    : Colors.transparent,
    builder            : (_) => _CommandeDetailSheet(commandeId: commandeId),
  );
}

class _CommandeDetailSheet extends ConsumerStatefulWidget {
  const _CommandeDetailSheet({required this.commandeId});
  final int commandeId;

  @override
  ConsumerState<_CommandeDetailSheet> createState() =>
      _CommandeDetailSheetState();
}

class _CommandeDetailSheetState extends ConsumerState<_CommandeDetailSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(commandeProvider.notifier)
        .refreshDetail(widget.commandeId));
  }

  /// Phase d'avancement d'une commande. Tant que le commerçant
  /// travaille ou qu'aucun livreur n'est trouvé, on préfère une
  /// animation à un badge : elle dit que quelque chose se passe.
  ({String titre, String message, IconData icone})? _phase(String statut) =>
      switch (statut) {
        'EN_ATTENTE' => (
            titre   : 'En attente de confirmation',
            message : 'Votre commande a été envoyée à l\'établissement, '
                'il va bientôt la confirmer.',
            icone   : Icons.storefront_rounded,
          ),
        'CONFIRME' || 'EN_PREPARATION' => (
            titre   : 'Préparation en cours',
            message : 'L\'établissement prépare votre commande.',
            icone   : Icons.restaurant_rounded,
          ),
        'PRET' || 'EN_ATTENTE_LIVREUR' => (
            titre   : 'Recherche d\'un livreur',
            message : 'Votre commande est prête. Nous cherchons un '
                'livreur disponible dans votre zone.',
            icone   : Icons.sports_motorsports,
          ),
        // Livrée, annulée, en cours de livraison : un badge suffit,
        // il n'y a plus rien à faire patienter.
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(commandeProvider);

    CommandeModel? resume;
    for (final c in etat.commandes) {
      if (c.id == widget.commandeId) resume = c;
    }
    final detail = etat.detail?.id == widget.commandeId ? etat.detail : null;

    return SheetDetail(
      enfant: detail == null && resume == null
          ? Padding(
              padding: EdgeInsets.all(AppDimens.xxxl),
              child: Center(child: Text('Commande introuvable')),
            )
          : _corps(detail, resume),
    );
  }

  Widget _corps(CommandeDetailModel? d, CommandeModel? resume) {
    // Le résumé de la liste permet d'afficher l'essentiel pendant que
    // le détail se charge, plutôt qu'un écran vide.
    final statut    = d?.statut ?? resume?.statut ?? '';
    final reference = d?.referenceCommande ?? resume?.referenceCommande ?? '';
    final phase     = _phase(statut);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ① État
        if (phase != null)
          Padding(
            padding: EdgeInsets.only(bottom: AppDimens.xl),
            child: RechercheAnimation(
              titre   : phase.titre,
              message : phase.message,
              icone   : phase.icone,
            ),
          )
        else
          EnTeteDetail(
            icone     : Icons.shopping_bag_outlined,
            titre     : 'Commande',
            reference : reference,
            statut    : CommandeCard.statusInfo(statut),
          ),

        // ② Le livreur, dès qu'il est assigné
        if (d != null && d.hasLivreur) ...[
          SizedBox(height: AppDimens.lg),
          CarteCoursier(
            nom       : d.livreurFullName ?? '',
            telephone : d.livreurTelephone,
            photoUrl  : d.livreurImageUrl,
            note      : d.livreurNote,
            vehicule  : d.vehiculeCoursier,
          ),
        ],

        SizedBox(height: AppDimens.xl),

        // ③ Le trajet — de l'établissement jusqu'au client.
        // Pas de distance ni de durée : cette API ne les calcule pas,
        // elles n'existent que sur la mission de livraison.
        if (d != null) ...[
          const SectionTitre('Trajet'),
          SizedBox(height: AppDimens.md),
          TrajetAB(
            depart       : d.structureAdresse,
            arrivee      : d.adresseLivraison,
            labelDepart  : 'Établissement',
            labelArrivee : d.modeReceptionCommande == 'RETRAIT_CLIENT'
                ? 'À retirer sur place'
                : 'Livraison',
          ),
          SizedBox(height: AppDimens.xl),
        ],

        // ④ Le contenu
        const SectionTitre('Votre commande'),
        SizedBox(height: AppDimens.md),
        ContenuCommande(detail: d),

        // ⑤ Consignes
        if (d != null && d.description.isNotEmpty) ...[
          SizedBox(height: AppDimens.xl),
          const SectionTitre('Consignes'),
          SizedBox(height: AppDimens.sm),
          EncadreConsigne(d.description),
        ],

        SizedBox(height: AppDimens.xl),
        const Divider(height: 1, color: AppColors.grey200),
        SizedBox(height: AppDimens.lg),

        // ⑥ Le montant. Les frais de livraison ne figurent pas dans
        // cette API : ils vivent sur la mission correspondante.
        LigneMontant(
          'Montant',
          montantLabel(d?.montantTotal ?? resume?.montantTotal ?? 0),
          fort: true,
        ),
      ],
    );
  }
}
