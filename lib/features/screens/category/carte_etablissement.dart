import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/image_reseau.dart';
import '../../favoris/providers/favori_notifier.dart';
import '../home/restaurant_card.dart' show RestaurantData;
import 'restaurant_bottom_sheet.dart';

/// Établissement en pleine largeur : image en bandeau, puis le nom, la
/// note, le délai et la catégorie en dessous.
///
/// Vivait en privé dans l'écran Catégorie. Extrait ici parce que les
/// favoris affichent la même chose : une liste d'établissements. Deux
/// présentations différentes pour un même objet obligeaient
/// l'utilisateur à réapprendre où regarder d'un écran à l'autre.
class CarteEtablissement extends ConsumerWidget {
  const CarteEtablissement({
    super.key,
    required this.restaurant,
    required this.structureId,
    required this.categoryName,
  });

  final RestaurantData restaurant;
  final int structureId;
  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriState = ref.watch(favoriProvider);
    final isFavori    = favoriState.isFavori(structureId);
    final isToggling  = favoriState.isToggling(structureId);

    return GestureDetector(
      onTap: () => showRestaurantBottomSheet(
        context,
        restaurant,
        structureId: structureId,
        categoryType: categoryName,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                child: ImageReseau(
                  url: restaurant.imageUrl,
                  height: 160.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fallback: Container(
                    height: 160.h,
                    width: double.infinity,
                    color: AppColors.grey200,
                    child: Icon(Icons.storefront_outlined,
                        color: AppColors.grey400, size: 48.r),
                  ),
                ),
              ),
              // ── Bouton cœur ─────────────────────────────────
              Positioned(
                top  : 10.h,
                right: 10.w,
                child: GestureDetector(
                  onTap: isToggling
                      ? null
                      : () => ref
                            .read(favoriProvider.notifier)
                            .toggleFavori(structureId),
                  child: isToggling
                      ? SizedBox(
                          width : 22.r,
                          height: 22.r,
                          child : CircularProgressIndicator(
                            strokeWidth : 2.r,
                            color       : Colors.white,
                          ),
                        )
                      : isFavori
                          ? Icon(Icons.favorite_rounded,
                              color: Colors.red, size: 26.r,
                              shadows: [
                                Shadow(color: Colors.black26, blurRadius: 6.r)
                              ])
                          : SvgPicture.asset(
                              'assets/icones/heart.svg',
                              width : 24.r,
                              height: 24.r,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // ── Nom + Rating ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    color: AppColors.dark,
                  ),
                ),
              ),
              Icon(Icons.star, size: 15.r, color: Colors.amber.shade600),
              SizedBox(width: 4.w),
              Text(
                restaurant.rating.toStringAsFixed(1),
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),

          SizedBox(height: 5.h),

          // ── Temps + Cuisine ─────────────────────────────────
          Row(
            children: [
              SvgPicture.asset(
                'assets/icones/motorcycle-fill.svg',
                width: 15.r,
                height: 15.r,
                colorFilter: const ColorFilter.mode(
                  AppColors.grey500,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                restaurant.deliveryTime,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.grey500,
                ),
              ),
              SizedBox(width: 16.w),
              // L'adresse est de longueur imprévisible : elle doit
              // céder la place plutôt que déborder
              Expanded(
                child: Text(
                  restaurant.cuisine,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
