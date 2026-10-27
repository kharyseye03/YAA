import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../model/notification/notification_model.dart';
import '../../../shared/widgets/bouton_retour.dart';
import '../../notifications/providers/notification_notifier.dart';
import '../order/commande_detail_sheet.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(notificationProvider.notifier).charger());
  }

  @override
  Widget build(BuildContext context) {
    final etat           = ref.watch(notificationProvider);
    final notifications  = etat.notifications;
    final nonLues        = etat.nonLues;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              top    : MediaQuery.of(context).padding.top + 12,
              left   : AppDimens.screenPadding,
              right  : AppDimens.screenPadding,
              bottom : 16.h,
            ),
            child: Row(
              children: [
                BoutonRetour(onTap: () => context.goNamed(RouteNames.home)),
                SizedBox(width: 12.w),
                Text(
                  'Notifications',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight : FontWeight.w800,
                    color      : AppColors.dark,
                  ),
                ),
                const Spacer(),
                // « Tout lire » plutôt qu'un simple compteur : le
                // nombre se lit déjà sur les pastilles de la liste, et
                // une personne qui ouvre cet écran veut souvent tout
                // solder d'un geste.
                if (nonLues > 0)
                  GestureDetector(
                    onTap: () => ref
                        .read(notificationProvider.notifier)
                        .marquerToutesLues(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color        : AppColors.grey100,
                        borderRadius :
                            BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Text(
                        'Tout lire ($nonLues)',
                        style: AppTextStyles.labelSmall.copyWith(
                          color      : AppColors.grey600,
                          fontWeight : FontWeight.w600,
                          fontSize   : 12.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Liste ───────────────────────────────────────────
          Expanded(
            child: etat.isLoading && notifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(notificationProvider.notifier).charger(),
                    child: notifications.isEmpty
                        ? ListView(
                            // Même vide, la liste doit pouvoir être
                            // tirée : sans ça, impossible de
                            // rafraîchir un écran sans contenu.
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                  height: MediaQuery.of(context)
                                          .size
                                          .height *
                                      0.18),
                              _buildEmpty(),
                            ],
                          )
                        : ListView.separated(
                            padding  : EdgeInsets.zero,
                            physics  :
                                const AlwaysScrollableScrollPhysics(),
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: AppColors.grey200),
                            itemBuilder: (_, i) {
                              final n = notifications[i];
                              // Glisser pour supprimer, comme dans une
                              // boîte de réception.
                              return Dismissible(
                                key             : ValueKey(n.id),
                                direction       :
                                    DismissDirection.endToStart,
                                onDismissed     : (_) => ref
                                    .read(notificationProvider.notifier)
                                    .supprimer(n.id),
                                background: Container(
                                  color     : AppColors.errorLight,
                                  alignment : Alignment.centerRight,
                                  padding   : EdgeInsets.only(right: 20.w),
                                  child: Icon(Icons.delete_outline_rounded,
                                      color: AppColors.error, size: 22.r),
                                ),
                                child: _NotifTile(
                                  notification : n,
                                  onTap        : () => _ouvrir(n),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width  : 72.r,
            height : 72.r,
            decoration: const BoxDecoration(
              color : AppColors.grey100,
              shape : BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size  : 32.r,
              color : AppColors.grey400,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'Aucune notification',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w700,
              color      : AppColors.dark,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Vous serez informé de vos commandes ici.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  /// Toucher une notification : on la marque lue, puis on va là où
  /// elle mène.
  ///
  /// La destination vient de son champ `data` — une commande, le plus
  /// souvent. Sans identifiant exploitable, on ne va nulle part
  /// plutôt que d'ouvrir un écran au hasard : la notification a déjà
  /// dit l'essentiel dans son texte.
  void _ouvrir(NotificationModel n) {
    ref.read(notificationProvider.notifier).marquerLue(n.id);

    final commandeId = n.commandeId;
    if (commandeId != null) {
      showCommandeDetailSheet(context, commandeId);
    }
  }
}

// ── Tuile ─────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  /// Icône et couleurs selon le type, avec un repli neutre : le
  /// serveur ajoutera des types, et une notification inconnue doit
  /// s'afficher plutôt que disparaître.
  ({IconData icone, Color fond, Color teinte}) get _apparence =>
      switch (notification.type) {
        'COMMANDE_STATUT' => (
            icone  : Icons.shopping_bag_outlined,
            fond   : AppColors.primarySurface,
            teinte : AppColors.primary,
          ),
        'COURSE_STATUT' || 'LIVRAISON_STATUT' => (
            icone  : Icons.two_wheeler_rounded,
            fond   : AppColors.successLight,
            teinte : AppColors.success,
          ),
        'PROMOTION' => (
            icone  : Icons.local_offer_outlined,
            fond   : const Color(0xFFFFF0E6),
            teinte : AppColors.secondary,
          ),
        _ => (
            icone  : Icons.notifications_outlined,
            fond   : AppColors.grey100,
            teinte : AppColors.grey600,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final apparence = _apparence;

    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child: ColoredBox(
        // Les non lues sur fond légèrement teinté : on repère d'un
        // coup d'œil ce qu'on n'a pas encore vu.
        color: notification.lue
            ? Colors.white
            : AppColors.grey100.withValues(alpha: 0.6),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal : AppDimens.screenPadding,
            vertical   : 14.h,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width  : 44.r,
                height : 44.r,
                decoration: BoxDecoration(
                  color        : apparence.fond,
                  borderRadius : BorderRadius.circular(12.r),
                ),
                child: Icon(apparence.icone,
                    color: apparence.teinte, size: 20.r),
              ),

              SizedBox(width: 14.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.titre,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight : FontWeight.w700,
                              color      : AppColors.dark,
                              fontSize   : 13.sp,
                            ),
                          ),
                        ),
                        if (!notification.lue) ...[
                          SizedBox(width: 8.w),
                          Container(
                            width  : 8.r,
                            height : 8.r,
                            decoration: const BoxDecoration(
                              shape : BoxShape.circle,
                              color : AppColors.secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color  : AppColors.grey600,
                        height : 1.4,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      dateRelative(notification.creeLe),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grey400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « Il y a 2 min », « Hier », « 12 oct. ».
///
/// Une date absolue oblige à calculer soi-même l'ancienneté ; sur une
/// liste de notifications, c'est le temps écoulé qui renseigne.
String dateRelative(DateTime? date) {
  if (date == null) return '';
  final ecart = DateTime.now().difference(date);

  if (ecart.inMinutes < 1)  return 'À l\'instant';
  if (ecart.inMinutes < 60) return 'Il y a ${ecart.inMinutes} min';
  if (ecart.inHours   < 24) return 'Il y a ${ecart.inHours} h';
  if (ecart.inDays    == 1) return 'Hier';
  if (ecart.inDays    < 7)  return 'Il y a ${ecart.inDays} jours';

  const mois = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  return '${date.day} ${mois[date.month - 1]}';
}
