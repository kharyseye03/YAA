import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/orders/providers/commande_notifier.dart';
import 'commande_detail_sheet.dart';
import 'mission_detail_sheet.dart';
import 'orders_screen.dart';

/// Historique des commandes terminées (LIVRE, ANNULE, REJETE).
/// Accessible depuis le profil.
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() =>
      _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(commandeProvider.notifier).loadCommandes());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commandeProvider);
    final list  = state.terminees;

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
                GestureDetector(
                  onTap    : () => Navigator.of(context).pop(),
                  behavior : HitTestBehavior.opaque,
                  child: Container(
                    width  : 38.r,
                    height : 38.r,
                    decoration: BoxDecoration(
                      color        : AppColors.grey100,
                      borderRadius : BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.chevron_left_rounded,
                        color: AppColors.dark, size: 22.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Historique',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight : FontWeight.w800,
                    color      : AppColors.dark,
                  ),
                ),
                const Spacer(),
                if (list.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color        : AppColors.grey100,
                      borderRadius : BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: Text(
                      '${list.length}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color      : AppColors.dark,
                        fontWeight : FontWeight.w700,
                        fontSize   : 13.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.grey200),

          // ── Erreur ──────────────────────────────────────────
          if (state.error != null)
            Container(
              width   : double.infinity,
              padding : EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding, vertical: 10.h),
              color   : AppColors.errorLight,
              child   : Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 16.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(state.error!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            ),

          // ── Contenu ─────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const _EmptyHistory()
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(commandeProvider.notifier)
                            .loadCommandes(),
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            AppDimens.screenPadding, 16,
                            AppDimens.screenPadding, 24,
                          ),
                          itemCount       : list.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: 12.h),
                          // Mêmes sheets que « Mes commandes » : une
                          // commande terminée doit se lire comme une
                          // commande en cours, pas dans un autre écran.
                          itemBuilder: (_, i) => switch (list[i]) {
                            ElementMission(:final mission) => CommandeCard(
                                mission : mission,
                                onTap   : () => showMissionDetailSheet(
                                    context, mission.id),
                              ),
                            ElementCommandeStructure(:final commande) =>
                              CommandeStructureCard(
                                commande : commande,
                                onTap    : () => showCommandeDetailSheet(
                                    context, commande.id),
                              ),
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── État vide ─────────────────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
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
            child: Icon(Icons.history_rounded,
                size: 32.r, color: AppColors.grey400),
          ),
          SizedBox(height: 14.h),
          Text(
            'Aucune commande terminée',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w700,
              color      : AppColors.dark,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Vos commandes livrées apparaîtront ici.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}
