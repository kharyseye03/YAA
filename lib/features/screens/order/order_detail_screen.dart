import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/api/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/orders/providers/commande_notifier.dart';
import '../../../model/order/commande_detail_model.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, this.commandeId});
  final int? commandeId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Timer? _pollTimer;

  // Statuts terminés : plus rien ne bougera, inutile de rafraîchir
  static const _statutsFinaux = {'LIVRE', 'ANNULE', 'REJETE'};

  @override
  void initState() {
    super.initState();
    if (widget.commandeId != null) {
      Future.microtask(
        () => ref.read(commandeProvider.notifier).loadDetail(widget.commandeId!),
      );
      // Rafraîchissement silencieux tant que la commande est "vivante" :
      // le statut et le livreur se mettent à jour sans quitter l'écran
      _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        final statut = ref.read(commandeProvider).detail?.statut;
        if (statut != null && _statutsFinaux.contains(statut)) {
          _pollTimer?.cancel();
          return;
        }
        ref.read(commandeProvider.notifier).refreshDetail(widget.commandeId!);
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Mapping statut ─────────────────────────────────────────
  static ({String label, Color color, Color bgColor}) _statusInfo(
          String statut) =>
      switch (statut) {
        'EN_ATTENTE'               => (label: 'En attente',             color: AppColors.grey600,  bgColor: AppColors.grey100),
        'CONFIRME'                 => (label: 'Confirmée',              color: AppColors.info,     bgColor: AppColors.infoLight),
        'EN_PREPARATION'           => (label: 'En préparation',         color: AppColors.info,     bgColor: AppColors.infoLight),
        'EN_ATTENTE_ORDONNANCE'    => (label: 'Ordonnance requise',     color: AppColors.warning,  bgColor: AppColors.warningLight),
        'PARTIELLEMENT_DISPONIBLE' => (label: 'Partiellement disponible', color: AppColors.warning, bgColor: AppColors.warningLight),
        'PRET'                     => (label: 'Prête pour livraison',   color: AppColors.info,     bgColor: AppColors.infoLight),
        'EN_ATTENTE_LIVREUR'       => (label: 'Recherche de livreur',   color: AppColors.warning,  bgColor: AppColors.warningLight),
        'LIVREUR_ASSIGNE'          => (label: 'Livreur assigné',        color: AppColors.info,     bgColor: AppColors.infoLight),
        'EN_LIVRAISON'             => (label: 'En cours de livraison',  color: AppColors.info,     bgColor: AppColors.infoLight),
        'LIVRE'                    => (label: 'Livrée',                 color: AppColors.success,  bgColor: AppColors.successLight),
        'ANNULE'                   => (label: 'Annulée',                color: AppColors.error,    bgColor: AppColors.errorLight),
        'REJETE'                   => (label: 'Rejetée',                color: AppColors.error,    bgColor: AppColors.errorLight),
        _                          => (label: statut,                   color: AppColors.grey500,  bgColor: AppColors.grey100),
      };

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(commandeProvider);
    final detail = state.detail;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Corps scrollable ───────────────────────────────
          state.isLoadingDetail
              ? const Center(child: CircularProgressIndicator())
              : state.detailError != null
                  ? _buildError(state.detailError!)
                  : detail == null
                      ? const Center(child: Text('Commande introuvable'))
                      : _buildContent(context, detail),

          // ── Back button overlay ────────────────────────────
          Positioned(
            top   : MediaQuery.of(context).padding.top + 8,
            left  : AppDimens.screenPadding,
            right : AppDimens.screenPadding,
            child : Row(
              children: [
                GestureDetector(
                  onTap    : () => Navigator.of(context).pop(),
                  behavior : HitTestBehavior.opaque,
                  child: Container(
                    width  : 40,
                    height : 40,
                    decoration: BoxDecoration(
                      color        : AppColors.dark.withValues(alpha: 0.55),
                      shape        : BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color        : AppColors.dark.withValues(alpha: 0.55),
                    borderRadius : BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    'Détail commande',
                    style: const TextStyle(
                      fontFamily : 'Archivo',
                      fontSize   : 13,
                      fontWeight : FontWeight.w600,
                      color      : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bannière + contenu ─────────────────────────────────────
  Widget _buildContent(BuildContext context, CommandeDetailModel d) {
    final status = _statusInfo(d.statut);
    final ref    = d.referenceCommande.length >= 8
        ? d.referenceCommande.substring(0, 8).toUpperCase()
        : d.referenceCommande.toUpperCase();

    return CustomScrollView(
      slivers: [
        // ── Bannière header ──────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fond dégradé navy
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin   : Alignment.topLeft,
                      end     : Alignment.bottomRight,
                      colors  : [Color(0xFF1A1A2E), Color(0xFF2A2A45)],
                    ),
                  ),
                ),
                // Motif décoratif
                Positioned(
                  top   : -40,
                  right : -40,
                  child : Container(
                    width  : 200,
                    height : 200,
                    decoration: BoxDecoration(
                      shape : BoxShape.circle,
                      color : Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  bottom : -60,
                  left   : -30,
                  child  : Container(
                    width  : 220,
                    height : 220,
                    decoration: BoxDecoration(
                      shape : BoxShape.circle,
                      color : Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                // Dégradé bas → fond blanc
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin  : Alignment.topCenter,
                        end    : Alignment.bottomCenter,
                        colors : [
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.95),
                        ],
                        stops  : const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // Statut badge centré en bas
                Positioned(
                  bottom : 20,
                  left   : 0,
                  right  : 0,
                  child  : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color        : status.bgColor,
                          borderRadius : BorderRadius.circular(AppDimens.radiusFull),
                          border       : Border.all(
                            color : status.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width  : 7,
                              height : 7,
                              decoration: BoxDecoration(
                                color : status.color,
                                shape : BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              status.label,
                              style: TextStyle(
                                fontFamily : 'Archivo',
                                fontSize   : 13,
                                fontWeight : FontWeight.w700,
                                color      : status.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Réf: $ref',
                        style: TextStyle(
                          fontFamily : 'Archivo',
                          fontSize   : 12,
                          color      : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Carte contenu (arrondie en haut) ─────────────────
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              decoration: const BoxDecoration(
                color        : AppColors.background,
                borderRadius : BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Montant + mode livraison ───────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.screenPadding),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total payé',
                              style: AppTextStyles.bodySmall.copyWith(
                                color    : AppColors.grey500,
                                fontSize : 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${d.montantTotal.toStringAsFixed(0)} F',
                              style: const TextStyle(
                                fontFamily : 'Archivo',
                                fontSize   : 28,
                                fontWeight : FontWeight.w800,
                                color      : AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color        : AppColors.primarySurface,
                            borderRadius : BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_shipping_outlined,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                d.modeLivraison == 'GROUPAGE'
                                    ? 'Groupée'
                                    : 'Individuelle',
                                style: AppTextStyles.labelSmall.copyWith(
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

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.grey200),
                  const SizedBox(height: 20),

                  // ── Articles commandés ─────────────────────
                  _SectionHeader(
                    icon  : Icons.shopping_bag_outlined,
                    label : 'Articles',
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(d.commandeProduits.length, (i) {
                    final p = d.commandeProduits[i];
                    return Column(
                      children: [
                        _ProduitRow(produit: p),
                        if (i < d.commandeProduits.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppDimens.screenPadding),
                            child: Divider(height: 1, color: AppColors.grey200),
                          ),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.grey200),
                  const SizedBox(height: 20),

                  // ── Itinéraire ─────────────────────────────
                  _SectionHeader(
                    icon  : Icons.route_outlined,
                    label : 'Itinéraire',
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.screenPadding),
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
                                    width  : 18,
                                    height : 18,
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
                                    width  : 9,
                                    height : 9,
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
                                      width: 1.5, color: AppColors.grey300),
                                ),
                              ),
                              const Icon(Icons.location_on,
                                  color: AppColors.secondary, size: 18),
                              const SizedBox(height: 3),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Départ',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.grey400)),
                                const SizedBox(height: 2),
                                Text(
                                  d.structureAdresse.isNotEmpty
                                      ? d.structureAdresse
                                      : d.structureName,
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: AppColors.dark),
                                ),
                                const SizedBox(height: 18),
                                Text('Votre adresse',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.grey400)),
                                const SizedBox(height: 2),
                                Text(
                                  d.adresseLivraison.isNotEmpty
                                      ? d.adresseLivraison
                                      : 'Adresse non renseignée',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: AppColors.dark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.grey200),
                  const SizedBox(height: 20),

                  // ── Établissement ──────────────────────────
                  _SectionHeader(
                    icon  : Icons.storefront_outlined,
                    label : 'Établissement',
                  ),
                  const SizedBox(height: 16),
                  _ContactCard(
                    icon       : Icons.storefront_outlined,
                    iconBg     : AppColors.primarySurface,
                    iconColor  : AppColors.primary,
                    name       : d.structureName,
                    detail     : d.structureAdresse,
                    phone      : d.structureTelephone,
                  ),

                  // ── Livreur (si assigné) ───────────────────
                  if (d.hasLivreur) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.grey200),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      icon  : Icons.delivery_dining_outlined,
                      label : 'Livreur',
                    ),
                    const SizedBox(height: 16),
                    _ContactCard(
                      icon      : Icons.person_outline_rounded,
                      iconBg    : AppColors.infoLight,
                      iconColor : AppColors.info,
                      name      : d.livreurFullName ?? '',
                      phone     : d.livreurTelephone,
                    ),
                  ]
                  // ── Recherche de livreur en cours ──────────
                  else if (d.statut == 'EN_ATTENTE_LIVREUR') ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.grey200),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      icon  : Icons.delivery_dining_outlined,
                      label : 'Livreur',
                    ),
                    const SizedBox(height: 16),
                    const _LivreurSearchCard(),
                  ],

                  // ── Note de commande ───────────────────────
                  if (d.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.grey200),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      icon  : Icons.notes_rounded,
                      label : 'Note de commande',
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.screenPadding),
                      child: Container(
                        width   : double.infinity,
                        padding : const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color        : Colors.white,
                          borderRadius : BorderRadius.circular(12),
                          border       : Border.all(color: AppColors.grey200),
                        ),
                        child: Text(
                          d.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color  : AppColors.grey700,
                            height : 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.grey600)),
          ],
        ),
      ),
    );
  }
}

// ── En-tête de section ────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.grey500),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color         : AppColors.grey500,
              fontSize      : 11,
              letterSpacing : 0.8,
              fontWeight    : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ligne produit ─────────────────────────────────────────────
class _ProduitRow extends StatelessWidget {
  const _ProduitRow({required this.produit});
  final CommandeProduit produit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.screenPadding, vertical: 12),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: produit.imageUrl != null
                ? Image.network(
                    produit.imageUrl!,
                    width  : 52,
                    height : 52,
                    fit    : BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nom,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight : FontWeight.w700,
                    color      : AppColors.dark,
                    fontSize   : 14,
                  ),
                  maxLines : 1,
                  overflow : TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${produit.prixUnitaire.toStringAsFixed(0)} F × ${produit.quantite}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Text(
            '${produit.prixTotal.toStringAsFixed(0)} F',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w700,
              color      : AppColors.dark,
              fontSize   : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width  : 52,
        height : 52,
        color  : AppColors.grey100,
        child  : const Icon(Icons.fastfood_outlined,
            color: AppColors.grey400, size: 22),
      );
}

// ── Carte contact ─────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.name,
    this.detail,
    this.phone,
  });

  final IconData icon;
  final Color    iconBg;
  final Color    iconColor;
  final String   name;
  final String?  detail;
  final String?  phone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color        : Colors.white,
          borderRadius : BorderRadius.circular(14),
          border       : Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              width  : 44,
              height : 44,
              decoration: BoxDecoration(
                color        : iconBg,
                shape        : BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight : FontWeight.w700,
                      color      : AppColors.dark,
                    ),
                  ),
                  if (detail != null && detail!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(detail!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500)),
                  ],
                  if (phone != null && phone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(phone!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey400)),
                  ],
                ],
              ),
            ),
            if (phone != null && phone!.isNotEmpty)
              Container(
                width  : 38,
                height : 38,
                decoration: const BoxDecoration(
                  color : AppColors.successLight,
                  shape : BoxShape.circle,
                ),
                child: const Icon(Icons.phone_rounded,
                    color: AppColors.success, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Recherche de livreur — animation radar ────────────────────
// Cercles concentriques qui pulsent autour d'une icône scooter,
// affiché tant que le statut est EN_ATTENTE_LIVREUR. Le polling
// remplace automatiquement cette carte par la carte livreur dès
// qu'un livreur accepte la commande.
class _LivreurSearchCard extends StatefulWidget {
  const _LivreurSearchCard();

  @override
  State<_LivreurSearchCard> createState() => _LivreurSearchCardState();
}

class _LivreurSearchCardState extends State<_LivreurSearchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync    : this,
    duration : const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
      child: Container(
        width   : double.infinity,
        padding : const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color        : Colors.white,
          borderRadius : BorderRadius.circular(14),
          border       : Border.all(color: AppColors.grey200),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                // ── Radar : 2 ondes décalées + icône au centre ──
                SizedBox(
                  width  : 96,
                  height : 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < 2; i++)
                        _buildRipple((_controller.value + i * 0.5) % 1.0),
                      Container(
                        width  : 52,
                        height : 52,
                        decoration: const BoxDecoration(
                          color : AppColors.warningLight,
                          shape : BoxShape.circle,
                        ),
                        child: const Icon(Icons.sports_motorsports_outlined,
                            color: AppColors.warning, size: 26),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Recherche d\'un livreur${_dots()}',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight : FontWeight.w700,
                    color      : AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Un livreur va bientôt accepter votre commande',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Onde radar : grandit de la taille de l'icône jusqu'au bord
  /// en s'estompant
  Widget _buildRipple(double progress) {
    final size    = 52 + progress * 44; // 52 → 96
    final opacity = (1 - progress) * 0.35;
    return Container(
      width  : size,
      height : size,
      decoration: BoxDecoration(
        shape : BoxShape.circle,
        color : AppColors.warning.withValues(alpha: opacity),
      ),
    );
  }

  /// Points de suspension animés : . .. ...
  String _dots() => '.' * ((_controller.value * 3).floor() + 1);
}
