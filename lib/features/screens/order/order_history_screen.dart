import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../features/orders/providers/commande_notifier.dart';
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
              bottom : 16,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap    : () => Navigator.of(context).pop(),
                  behavior : HitTestBehavior.opaque,
                  child: Container(
                    width  : 38,
                    height : 38,
                    decoration: BoxDecoration(
                      color        : AppColors.grey100,
                      borderRadius : BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: AppColors.dark, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color        : AppColors.grey100,
                      borderRadius : BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: Text(
                      '${list.length}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color      : AppColors.dark,
                        fontWeight : FontWeight.w700,
                        fontSize   : 13,
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
                          padding: const EdgeInsets.fromLTRB(
                            AppDimens.screenPadding, 16,
                            AppDimens.screenPadding, 24,
                          ),
                          itemCount       : list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => CommandeCard(
                            mission : list[i],
                            onTap   : () => context.pushNamed(
                              RouteNames.orderDetail,
                              extra: list[i],
                            ),
                          ),
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
            width  : 72,
            height : 72,
            decoration: const BoxDecoration(
              color : AppColors.grey100,
              shape : BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 32, color: AppColors.grey400),
          ),
          const SizedBox(height: 14),
          Text(
            'Aucune commande terminée',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w700,
              color      : AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vos commandes livrées apparaîtront ici.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}
