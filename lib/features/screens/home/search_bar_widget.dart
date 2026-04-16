import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';

/// Search bar with text input and filter icon button.
class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterTap,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search field
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.grey300, width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppDimens.md),
                Icon(
                  Icons.search,
                  color: AppColors.grey500,
                  size: 22,
                ),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.dark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un trajet',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey500,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppDimens.md),

        // Filter button
        GestureDetector(
          onTap: onFilterTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.grey300, width: 1),
            ),
            child: const Icon(
              Icons.tune,
              color: AppColors.dark,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}