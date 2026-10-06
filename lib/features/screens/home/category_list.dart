import '../../../shared/widgets/image_reseau.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    /// -1 : aucune catégorie mise en avant. C'est l'état d'arrivée
    /// sur l'accueil — surligner la première laisserait croire à un
    /// filtre déjà appliqué, alors que la liste en dessous les
    /// contient toutes.
    this.activeIndex = -1,
  });

  final List<CategoryData> categories;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88.h,
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
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            itemCount: categories.length,
            separatorBuilder: (_, __) => SizedBox(width: 16.w),
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
        width: 68.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58.r,
              height: 58.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? data.color
                    : data.color.withValues(alpha: 0.12),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: data.color.withValues(alpha: 0.35),
                          blurRadius: 10.r,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: data.imageUrl != null
                    ? ImageReseau(
                        url: data.imageUrl!,
                        fit: BoxFit.cover,
                        fallback:
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
                                    size: 26.r,
                                  ),
                      )
                    : Icon(
                        data.icon ?? Icons.category_outlined,
                        color: isActive ? Colors.white : data.color,
                        size: 26.r,
                      ),
              ),
            ),

            SizedBox(height: 6.h),

            Text(
              data.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11.5.sp,
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
