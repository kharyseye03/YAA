import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../user/providers/user_notifier.dart';

/// Personal info view screen (read-only) with "Modifier" button.
class PersonalInfoScreen extends ConsumerWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProvider).profile;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
              child: Column(
                children: [
                  const SizedBox(height: AppDimens.xxxl),
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.grey200, border: Border.all(color: AppColors.grey300, width: 2)),
                    child: const Icon(Icons.person, color: AppColors.grey500, size: 48),
                  ),
                  const SizedBox(height: AppDimens.xxxl),
                  _buildRow('Prénom', profile?.firstName ?? '—'),
                  const Divider(color: AppColors.grey200, height: 1),
                  _buildRow('Nom', profile?.lastName ?? '—'),
                  const Divider(color: AppColors.grey200, height: 1),
                  _buildRow('Numéro téléphone', profile?.telephone ?? '—'),
                  const Divider(color: AppColors.grey200, height: 1),
                  _buildRow('Email', profile?.email ?? '—'),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding, vertical: AppDimens.lg),
            color: AppColors.white,
            child: SafeArea(top: false, child: YaaButton(label: 'Modifier', onPressed: () => context.pushNamed(RouteNames.editPersonalInfo))),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: AppDimens.screenPadding, right: AppDimens.screenPadding, top: MediaQuery.of(context).padding.top + AppDimens.md, bottom: AppDimens.xl),
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1652F0), Color(0xFF3B7BF7)])),
      child: Row(children: [
        GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.chevron_left, color: AppColors.white, size: 28)),
        const SizedBox(width: AppDimens.md),
        Text('Informations personnelles', style: AppTextStyles.h4.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500)),
        Text(value, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}