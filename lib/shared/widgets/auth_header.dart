import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../core/constants/constants.dart';

/// Reusable header for auth screens.
/// Shows "Français" language selector on the right.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.screenPadding,
        vertical: AppDimens.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Language selector
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                RemixIcons.global_fill,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Français',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}