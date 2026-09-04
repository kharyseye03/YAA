import '../../../shared/widgets/image_reseau.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';

class RestaurantData {
  final String name;
  final String cuisine;
  final double rating;
  final String deliveryTime;
  final String imageUrl;
  final String? distance; // ex: "487 m" — affiché si fourni

  const RestaurantData({
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
    required this.imageUrl,
    this.distance,
  });
}

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.onTap,
    this.onFavoriteTap,
  });

  final RestaurantData restaurant;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 270.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image avec overlay favori ────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  child: ImageReseau(
                    url     : restaurant.imageUrl,
                    height  : 130.h,
                    width   : 270.w,
                    radius  : AppDimens.radiusLg,
                    fallback: Container(
                      height: 130.h,
                      width: 270.w,
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusLg),
                      ),
                      child: Icon(
                        Icons.storefront_outlined,
                        color: AppColors.grey400,
                        size: 40.r,
                      ),
                    ),
                  ),
                ),

                // Bouton favori (cœur)
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: SvgPicture.asset(
                      'assets/icones/heart.svg',
                      width: 22.r,
                      height: 22.r,
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

            // ── Nom + Rating ─────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    restaurant.name,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                      color: AppColors.dark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.star, size: 14.r, color: Colors.black),
                SizedBox(width: 3.w),
                Text(
                  restaurant.rating.toStringAsFixed(1),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),

            SizedBox(height: 4.h),

            // ── Temps de livraison ────────────────────────────────
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icones/motorcycle-fill.svg',
                  width: 16.r,
                  height: 16.r,
                  colorFilter: const ColorFilter.mode(
                    AppColors.black,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 5.w),
                Text(
                  restaurant.deliveryTime,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey500,
                  ),
                ),
                if (restaurant.distance != null) ...[
                  SizedBox(width: 8.w),
                  Icon(Icons.location_on_outlined,
                      size: 14.r, color: AppColors.grey500),
                  const SizedBox(width: 2),
                  Text(
                    restaurant.distance!,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
