import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../features/orders/providers/commande_notifier.dart';
import '../../../model/order/commande_model.dart';
import '../../../service/location/location_service.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(commandeProvider.notifier).loadCommandes());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commandeProvider);
    final list  = state.enCours;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),

        // ── Titre ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
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

        // ── Erreur ────────────────────────────────────────────
        if (state.error != null)
          Container(
            width   : double.infinity,
            padding : const EdgeInsets.symmetric(
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
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? const _Empty()
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(commandeProvider.notifier).loadCommandes(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.screenPadding, 16,
                          AppDimens.screenPadding, 24,
                        ),
                        itemCount      : list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => CommandeCard(
                          commande : list[i],
                          onTap    : () => context.pushNamed(
                            RouteNames.orderDetail,
                            extra: list[i].id,
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── Carte commande (publique : réutilisée par l'historique) ───
class CommandeCard extends StatelessWidget {
  const CommandeCard({super.key, required this.commande, required this.onTap});
  final CommandeModel commande;
  final VoidCallback  onTap;

  static ({String label, Color color, Color bgColor}) _statusInfo(
      String statut) =>
      switch (statut) {
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
        'EN_ATTENTE_LIVREUR' => (
            label   : 'Cherche livreur',
            color   : AppColors.warning,
            bgColor : AppColors.warningLight,
          ),
        'LIVREUR_ASSIGNE' => (
            label   : 'Livreur assigné',
            color   : AppColors.info,
            bgColor : AppColors.infoLight,
          ),
        'EN_LIVRAISON' => (
            label   : 'En livraison',
            color   : AppColors.info,
            bgColor : AppColors.infoLight,
          ),
        'LIVRE' => (
            label   : 'Livré',
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
    final status = _statusInfo(commande.statut);
    final ref    = commande.referenceCommande.length >= 8
        ? commande.referenceCommande.substring(0, 8).toUpperCase()
        : commande.referenceCommande.toUpperCase();

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
            // ── Top : structure + statut ─────────────────────
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
                    child: const Icon(Icons.storefront_outlined,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commande.structureName,
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
                            commande.structureAdresse.isNotEmpty
                                ? commande.structureAdresse
                                : commande.structureName,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.dark),
                            maxLines : 1,
                            overflow : TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text('Livraison',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.grey400)),
                          const SizedBox(height: 1),
                          Text(
                            LocationService.cleanAddress(
                                commande.adresseLivraison),
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

            // ── Bas : montant + mode livraison ───────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Text(
                    '${commande.montantTotal.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontFamily : 'Archivo',
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
                      color        : AppColors.primarySurface,
                      borderRadius : BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          commande.modeLivraison == 'GROUPAGE'
                              ? 'Groupée'
                              : 'Individuelle',
                          style: AppTextStyles.caption.copyWith(
                            color      : AppColors.primary,
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

// ── État vide ─────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  const _Empty();

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
            'Aucune commande en cours',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w700,
              color      : AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vos commandes apparaîtront ici.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}
