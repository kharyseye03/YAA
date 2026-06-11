import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class CategoryData {
  final String label;
  final IconData? icon;
  final String? imageUrl;
  final String? fallbackAsset;
  final Color color;
  final VoidCallback? onTap;

  const CategoryData({
    required this.label,
    this.icon,
    this.imageUrl,
    this.fallbackAsset,
    this.color = AppColors.primary,
    this.onTap,
  });
}

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
    return SizedBox(
      height: 88,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Largeur totale nécessaire : items (68) + espacements (16)
          final neededWidth =
              categories.length * 68 + (categories.length - 1) * 16;

          // Si tous les items tiennent → répartition équitable sur la ligne
          if (neededWidth <= constraints.maxWidth) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                categories.length,
                (i) => _CategoryItem(
                  data: categories[i],
                  isActive: i == activeIndex,
                ),
              ),
            );
          }

          // Sinon → scroll horizontal comme avant
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) => _CategoryItem(
              data: categories[i],
              isActive: i == activeIndex,
            ),
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.data, required this.isActive});

  final CategoryData data;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? data.color
                    : data.color.withOpacity(0.12),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: data.color.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: data.imageUrl != null
                    ? Image.network(
                        data.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            data.fallbackAsset != null
                                ? Image.asset(
                                    data.fallbackAsset!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Icon(
                                    data.icon ?? Icons.category_outlined,
                                    color:
                                        isActive ? Colors.white : data.color,
                                    size: 26,
                                  ),
                      )
                    : Icon(
                        data.icon ?? Icons.category_outlined,
                        color: isActive ? Colors.white : data.color,
                        size: 26,
                      ),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              data.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? data.color : AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
