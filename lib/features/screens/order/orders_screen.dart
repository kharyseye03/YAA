import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/devise.dart';
import '../../../features/orders/providers/commande_notifier.dart';
import '../../../model/order/commande_model.dart';
import '../../../model/order/livraison_course_model.dart';
import 'commande_detail_sheet.dart';
import 'mission_detail_sheet.dart';
import '../../../service/location/location_service.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  /// 0 = Achat (commandes chez un commerçant), 1 = Course (colis
  /// et trajets). Chaque onglet a sa propre API.
  int _onglet = 0;

  Timer? _rafraichissement;

  /// Les statuts avancent côté serveur sans prévenir l'app. Sans ce
  /// rappel, le client doit tirer la liste vers le bas pour voir qu'un
  /// coursier a pris sa commande — et l'écran paraît figé.
  static const _periode = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(commandeProvider.notifier).loadCommandes());

    _rafraichissement = Timer.periodic(_periode, (_) {
      final etat = ref.read(commandeProvider);
      // Plus rien en cours dans aucun onglet : inutile de continuer à
      // interroger le serveur. Le geste « tirer pour rafraîchir »
      // reste disponible si le client veut forcer.
      final rienEnCours =
          etat.achatsEnCours.isEmpty && etat.coursesEnCours.isEmpty;
      if (rienEnCours && !etat.isLoading) {
        _rafraichissement?.cancel();
        return;
      }
      ref.read(commandeProvider.notifier).loadCommandes(silencieux: true);
    });
  }

  @override
  void dispose() {
    _rafraichissement?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(commandeProvider);
    final achats  = state.achatsEnCours;
    final courses = state.coursesEnCours;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),

        // ── Titre ─────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.screenPadding, 14,
            AppDimens.screenPadding, 10,
          ),
          child: Row(
            children: [
              Text(
                'Mes commandes',
                style: AppTextStyles.h3.copyWith(
                  fontWeight : FontWeight.w700,
                  color      : AppColors.dark,
                ),
              ),
            ],
          ),
        ),

        // ── Onglets ───────────────────────────────────────────
        _Tabs(
          current : _onglet,
          onTap   : (i) => setState(() => _onglet = i),
          counts  : [achats.length, courses.length],
        ),

        // ── Erreur ────────────────────────────────────────────
        if (state.error != null)
          Container(
            width   : double.infinity,
            padding : EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding, vertical: 10),
            color   : AppColors.errorLight,
            child   : Row(
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
          // Le loader plein écran n'a de sens que s'il n'y a encore
          // rien à montrer. Sinon on garde la liste affichée : le
          // RefreshIndicator porte déjà son propre témoin.
          child: state.isLoading && achats.isEmpty && courses.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(commandeProvider.notifier).loadCommandes(),
                  child: _onglet == 0
                      ? _buildListe(
                          vide     : achats.isEmpty,
                          message  : 'Aucune commande en cours',
                          detail   : 'Vos achats chez un commerçant '
                              'apparaîtront ici.',
                          count    : achats.length,
                          builder  : (i) => CommandeStructureCard(
                            commande : achats[i],
                            onTap    : () => showCommandeDetailSheet(
                                context, achats[i].id),
                          ),
                        )
                      : _buildListe(
                          vide     : courses.isEmpty,
                          message  : 'Aucune course en cours',
                          detail   : 'Vos colis et trajets apparaîtront ici.',
                          count    : courses.length,
                          builder  : (i) => CommandeCard(
                            mission : courses[i],
                            onTap   : () => showMissionDetailSheet(context, courses[i].id),
                          ),
                        ),
                ),
        ),
      ],
    );
  }

  /// Liste d'un onglet, ou son état vide. Le `ListView` est conservé
  /// même vide pour que le geste « tirer pour rafraîchir » continue de
  /// fonctionner — sur un simple `Center`, il n'y a rien à tirer.
  Widget _buildListe({
    required bool   vide,
    required String message,
    required String detail,
    required int    count,
    required Widget Function(int) builder,
  }) {
    if (vide) {
      return ListView(
        physics : const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          _Empty(message: message, detail: detail),
        ],
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppDimens.screenPadding, 16,
        AppDimens.screenPadding, 24,
      ),
      physics         : const AlwaysScrollableScrollPhysics(),
      itemCount       : count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder     : (_, i) => builder(i),
    );
  }
}

// ── Onglets ───────────────────────────────────────────────────
class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.current,
    required this.onTap,
    required this.counts,
  });

  final int               current;
  final ValueChanged<int> onTap;
  final List<int>         counts;

  @override
  Widget build(BuildContext context) {
    const labels = ['Achat', 'Course'];
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
                          fontWeight :
                              active ? FontWeight.w700 : FontWeight.w500,
                          color      :
                              active ? AppColors.dark : AppColors.grey400,
                        ),
                      ),
                      if (counts[i] > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.grey200,
                            borderRadius: BorderRadius.circular(20),
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
        // Trait actif sous l'onglet retenu
        Row(
          children: List.generate(2, (i) {
            final active = i == current;
            return Expanded(
              child: AnimatedContainer(
                duration : const Duration(milliseconds: 200),
                height   : 2,
                color    : active ? AppColors.dark : AppColors.grey200,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Carte mission (publique : réutilisée par l'historique) ───
class CommandeCard extends StatelessWidget {
  const CommandeCard({super.key, required this.mission, required this.onTap});
  final LivraisonCourseModel mission;
  final VoidCallback         onTap;

  /// Statuts communs aux commandes d'établissement et aux missions
  /// de livraison/course.
  static ({String label, Color color, Color bgColor}) statusInfo(
      String statut) =>
      switch (statut) {
        // ── Cycle d'une commande d'établissement ──────────────
        'EN_ATTENTE' => (
            label   : 'En attente',
            color   : AppColors.grey600,
            bgColor : AppColors.grey100,
          ),
        'CONFIRME' => (
            label   : 'Confirmée',
            color   : AppColors.info,
            bgColor : AppColors.infoLight,
          ),
        'EN_PREPARATION' => (
            label   : 'En préparation',
            color   : AppColors.info,
            bgColor : AppColors.infoLight,
          ),
        'EN_ATTENTE_ORDONNANCE' => (
            label   : 'Ordonnance requise',
            color   : AppColors.warning,
            bgColor : AppColors.warningLight,
          ),
        'PARTIELLEMENT_DISPONIBLE' => (
            label   : 'Partiel',
            color   : AppColors.warning,
            bgColor : AppColors.warningLight,
          ),
        'PRET' => (
            label   : 'Prête',
            color   : AppColors.info,
            bgColor : AppColors.infoLight,
          ),
        // ── Cycle d'une mission (livraison / course) ──────────
        'EN_ATTENTE_LIVREUR' || 'RECHERCHE_COURSIER' => (
            label   : 'Recherche coursier',
            color   : AppColors.warning,
            bgColor : AppColors.warningLight,
          ),
        'LIVREUR_ASSIGNE' || 'COURSIER_ASSIGNE' => (
            label   : 'Coursier assigné',
            color   : AppColors.info,
            bgColor : AppColors.infoLight,
          ),
        'COURSIER_EN_ROUTE_VERS_DEPART' => (
            label   : 'En route',
            color   : AppColors.info,
            bgColor : AppColors.infoLight,
          ),
        'COURSIER_ARRIVE_AU_DEPART' => (
            label   : 'Sur place',
            color   : AppColors.info,
            bgColor : AppColors.infoLight,
          ),
        'PRISE_EN_CHARGE_EFFECTUEE' => (
            label   : 'Colis récupéré',
            color   : AppColors.info,
            bgColor : AppColors.infoLight,
          ),
        'EN_LIVRAISON' || 'COURSE_EN_COURS' => (
            label   : 'En cours',
            color   : AppColors.info,
            bgColor : AppColors.infoLight,
          ),
        'LIVRE' || 'COURSE_TERMINEE' => (
            label   : 'Terminée',
            color   : AppColors.success,
            bgColor : AppColors.successLight,
          ),
        'ANNULE' => (
            label   : 'Annulée',
            color   : AppColors.error,
            bgColor : AppColors.errorLight,
          ),
        'REJETE' => (
            label   : 'Rejetée',
            color   : AppColors.error,
            bgColor : AppColors.errorLight,
          ),
        _ => (
            label   : statut,
            color   : AppColors.grey500,
            bgColor : AppColors.grey100,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final status = statusInfo(mission.statut);
    final type   = mission.typeService;
    final ref    = mission.code.isNotEmpty
        ? mission.code
        : '#${mission.id}';

    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child: Container(
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
        child: Column(
          children: [
            // ── Top : type de service + statut ───────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width  : 38,
                    height : 38,
                    decoration: BoxDecoration(
                      color        : AppColors.primarySurface,
                      borderRadius : BorderRadius.circular(10),
                    ),
                    child: Icon(type.icon,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.label,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight : FontWeight.w700,
                            fontSize   : 14,
                            color      : AppColors.dark,
                          ),
                          maxLines : 1,
                          overflow : TextOverflow.ellipsis,
                        ),
                        Text(
                          'Réf: $ref',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey400,
                          ),
                          maxLines : 1,
                          overflow : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color        : status.bgColor,
                      borderRadius : BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color      : status.color,
                        fontWeight : FontWeight.w700,
                        fontSize   : 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.grey100),
            const SizedBox(height: 12),

            // ── Itinéraire ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icônes + ligne
                    Column(
                      children: [
                        const SizedBox(height: 3),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width  : 16,
                              height : 16,
                              decoration: BoxDecoration(
                                shape : BoxShape.circle,
                                border: Border.all(
                                  color : AppColors.primary
                                      .withValues(alpha: 0.3),
                                  width : 1.5,
                                ),
                              ),
                            ),
                            Container(
                              width  : 8,
                              height : 8,
                              decoration: const BoxDecoration(
                                color : AppColors.primary,
                                shape : BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                                width: 1.5, color: AppColors.grey200),
                          ),
                        ),
                        const Icon(Icons.location_on,
                            color: AppColors.secondary, size: 16),
                        const SizedBox(height: 3),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Textes départ / arrivée
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Départ',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.grey400)),
                          const SizedBox(height: 1),
                          Text(
                            LocationService.cleanAddress(
                                mission.adresseDepart),
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.dark),
                            maxLines : 1,
                            overflow : TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text('Arrivée',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.grey400)),
                          const SizedBox(height: 1),
                          Text(
                            LocationService.cleanAddress(
                                mission.adresseArrivee),
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.dark),
                            maxLines : 1,
                            overflow : TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.grey100),

            // ── Bas : montant + distance/durée ───────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Text(
                    mission.montantLabel,
                    style: const TextStyle(
                      fontFamily : 'PlusJakartaSans',
                      fontSize   : 18,
                      fontWeight : FontWeight.w800,
                      color      : AppColors.dark,
                    ),
                  ),
                  const Spacer(),
                  if (mission.metaLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color        : AppColors.grey100,
                        borderRadius : BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.route_rounded,
                              size: 12, color: AppColors.grey500),
                          const SizedBox(width: 4),
                          Text(
                            mission.metaLabel,
                            style: AppTextStyles.caption.copyWith(
                              color      : AppColors.grey600,
                              fontWeight : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte commande d'établissement ───────────────────────────
/// Rendu des éléments venant de `/commandes-clients`.
///
/// Deux différences avec [CommandeCard] : pas de trajet A → B, car
/// l'API ne renvoie que l'adresse de livraison ; et pas de tap, car
/// l'écran de détail exige un `LivraisonCourseModel` qu'une commande
/// sans mission ne possède pas.
class CommandeStructureCard extends StatelessWidget {
  const CommandeStructureCard({
    super.key,
    required this.commande,
    this.onTap,
  });

  final CommandeModel commande;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = CommandeCard.statusInfo(commande.statut);
    final ref    = commande.referenceCommande.isNotEmpty
        ? commande.referenceCommande
        : '#${commande.id}';

    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child: Container(
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
      child: Column(
        children: [
          // ── Top : type + statut ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width  : 38,
                  height : 38,
                  decoration: BoxDecoration(
                    color        : AppColors.primarySurface,
                    borderRadius : BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commande',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight : FontWeight.w700,
                          fontSize   : 14,
                          color      : AppColors.dark,
                        ),
                        maxLines : 1,
                        overflow : TextOverflow.ellipsis,
                      ),
                      Text(
                        'Réf: $ref',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey400),
                        maxLines : 1,
                        overflow : TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color        : status.bgColor,
                    borderRadius : BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color      : status.color,
                      fontWeight : FontWeight.w700,
                      fontSize   : 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.grey100),
          const SizedBox(height: 12),

          // ── Établissement puis destination ───────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ligne(
                  icone : Icons.storefront_rounded,
                  teinte: AppColors.primary,
                  label : 'Établissement',
                  valeur: commande.structureName,
                ),
                const SizedBox(height: 10),
                _ligne(
                  icone : Icons.location_on,
                  teinte: AppColors.secondary,
                  label : 'Livraison',
                  valeur: LocationService.cleanAddress(
                      commande.adresseLivraison),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.grey100),

          // ── Bas : montant + mode de réception ────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Text(
                  montantLabel(commande.montantTotal),
                  style: const TextStyle(
                    fontFamily : 'PlusJakartaSans',
                    fontSize   : 18,
                    fontWeight : FontWeight.w800,
                    color      : AppColors.dark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color        : AppColors.grey100,
                    borderRadius : BorderRadius.circular(20),
                  ),
                  child: Text(
                    commande.modeReceptionCommande == 'RETRAIT_CLIENT'
                        ? 'Retrait'
                        : 'Livraison',
                    style: AppTextStyles.caption.copyWith(
                      color      : AppColors.grey600,
                      fontWeight : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _ligne({
    required IconData icone,
    required Color    teinte,
    required String   label,
    required String   valeur,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 16, color: teinte),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.grey400)),
              const SizedBox(height: 1),
              Text(
                valeur,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.dark),
                maxLines : 1,
                overflow : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── État vide ─────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  const _Empty({required this.message, required this.detail});

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width  : 72,
            height : 72,
            decoration: const BoxDecoration(
              color : AppColors.grey100,
              shape : BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 32, color: AppColors.grey400),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w700,
              color      : AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
