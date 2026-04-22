import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shared/widgets/auth_header.dart';

/// Location permission screen — "Où livrer vos commande ?"
/// Shows a location pin icon in a circle and a CTA button.
class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  void _onUseLocation(BuildContext context) {
    // TODO: Request location permission, then navigate
    context.goNamed(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const AuthHeader(),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimens.lg),

                    // Title
                    Text(
                      'Où livrer vos\ncommande ?',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: AppDimens.md),

                    // Subtitle
                    Text(
                      'Autorisez l\'accès à votre position pour voir les\nboutiques et restaurants proches de vous.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey600,
                        height: 1.5,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Location pin illustration
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
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 44,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Use location button
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