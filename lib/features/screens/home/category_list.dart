import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';

/// Data model for a category item.
class CategoryData {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const CategoryData({
    required this.label,
    required this.icon,
    this.onTap,
  });
}

/// Horizontal row of category buttons.
/// The first one is highlighted (active).
class CategoryList extends StatelessWidget {
  const CategoryList({
    super.key,
    required this.categories,
    this.activeIndex = 0,
  });

  final List<CategoryData> categories;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(categories.length, (index) {
        final category = categories[index];
        final isActive = index == activeIndex;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == categories.length - 1 ? 0 : AppDimens.sm,
            ),
            child: _CategoryButton(
              data: category,
              isActive: isActive,
            ),
          ),
        );
      }),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.data,
    required this.isActive,
  });

  final CategoryData data;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Column(
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              color:
              isActive ? AppColors.primary : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Center(
              child: Icon(
                data.icon,
                color: isActive ? AppColors.white : AppColors.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            data.label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}