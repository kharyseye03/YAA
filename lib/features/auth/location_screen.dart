import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shared/widgets/auth_header.dart';

/// Location permission screen — "Où livrer vos commande ?"
class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  Future<void> _onUseLocation(BuildContext context) async {
    // TODO: Request actual location permission here

    await _showLocationSuccessSheet(context);
  }

  Future<void> _showLocationSuccessSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _LocationSuccessSheet(
        onLogin: () {
          Navigator.of(context).pop();
          context.goNamed(RouteNames.login);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AuthHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimens.lg),

                    Text(
                      'Où livrer vos\ncommande ?',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: AppDimens.md),

                    Text(
                      'Autorisez l\'accès à votre position pour voir les\nboutiques et restaurants proches de vous.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey600,
                        height: 1.5,
                      ),
                    ),

                    const Spacer(flex: 2),

                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primarySurface,
                        ),
                        child: Center(
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              size: 44,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    YaaButton(
                      label: 'Utiliser ma position actuelle',
                      onPressed: () => _onUseLocation(context),
                      icon: Icons.location_on,
                    ),

                    const SizedBox(height: AppDimens.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success bottom sheet
// ---------------------------------------------------------------------------

class _LocationSuccessSheet extends StatelessWidget {
  const _LocationSuccessSheet({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.screenPadding,
        16,
        AppDimens.screenPadding,
        AppDimens.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: AppDimens.xl),

          // Success icon — double circle like Figma
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySurface,
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppDimens.lg),

          // Title
          Text(
            'Position ajouté',
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppDimens.sm),

          // Subtitle
          Text(
            'Connectez-vous pour accéder à votre espace.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey600,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppDimens.xl),

          // CTA
          YaaButton(
            label: 'Se connecter',
            onPressed: onLogin,
          ),
        ],
      ),
    );
  }
}