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
    this.isFavori = false,
    this.isToggling = false,
    this.width,
  });

  /// Largeur imposée. Null suit le parent — ce qu'il faut dans une
  /// liste verticale. La valeur par défaut de 270 cadre le défilé
  /// horizontal de l'accueil, où plusieurs cartes se côtoient.
  final double? width;

  final RestaurantData restaurant;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  /// Cœur plein rouge quand vrai. La carte ne décide de rien : elle
  /// affiche l'état que l'appelant lui donne, et signale l'intention
  /// par [onFavoriteTap]. C'est le provider qui tranche.
  final bool isFavori;

  /// Appel en cours pour cette structure : le cœur laisse place à un
  /// indicateur et cesse de répondre, pour qu'un double appui
  /// n'envoie pas deux bascules qui s'annulent.
  final bool isToggling;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width ?? 270.w,
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
                    width   : double.infinity,
                    radius  : AppDimens.radiusLg,
                    fallback: Container(
                      height: 130.h,
                      width: double.infinity,
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
                  // Même rendu que la liste de l'écran Catégorie :
                  // cœur plein rouge une fois aimé, contour blanc
                  // sinon, indicateur pendant l'appel. Deux écrans
                  // qui montrent les mêmes structures ne doivent pas
                  // avoir deux façons de dire « favori ».
                  child: GestureDetector(
                    onTap: isToggling ? null : onFavoriteTap,
                    // 22 px, c'est petit pour un pouce : le padding
                    // élargit la zone tactile sans déplacer l'icône.
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.all(AppDimens.xs),
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
                              ? Icon(
                                  Icons.favorite_rounded,
                                  color : Colors.red,
                                  size  : 26.r,
                                  shadows: [
                                    Shadow(
                                      color      : Colors.black26,
                                      blurRadius : 6.r,
                                    ),
                                  ],
                                )
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
