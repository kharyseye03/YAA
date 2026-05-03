import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../core/constants/constants.dart';

/// Reusable header for auth screens.
/// Shows a back arrow on the left and "Français" language selector on the right.
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.grey300,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: AppColors.dark,
              ),
            ),
          ),

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