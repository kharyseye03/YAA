import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/cart/providers/cart_notifier.dart';

class HomeBottomNav extends ConsumerWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCartTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).cart?.totalArticles ?? 0;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 16.h),
      child: Container(
        height: 68.h,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(40.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24.r,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              icon: RemixIcons.home_6_fill,
              inactiveIcon: RemixIcons.home_6_line,
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.receipt_long,
              inactiveIcon: Icons.receipt_long_outlined,
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),

            // ── Cart central ─────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: onCartTap,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46.r,
                        height: 46.r,
                        decoration: BoxDecoration(
                          color: currentIndex == 4
                              ? Colors.white
                              : AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 12.r,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: currentIndex == 4
                              ? AppColors.primary
                              : Colors.white,
                          size: 22.r,
                        ),
                      ),
                      // ── Badge rouge ────────────────────────
                      if (cartCount > 0)
                        Positioned(
                          top  : -4,
                          right: -4,
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: const BoxDecoration(
                              color : Colors.red,
                              shape : BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth : 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              cartCount > 9 ? '9+' : '$cartCount',
                              style: TextStyle(
                                color     : Colors.white,
                                fontSize  : 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            _NavItem(
              icon: RemixIcons.heart_3_fill,
              inactiveIcon: RemixIcons.heart_3_line,
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: RemixIcons.user_3_fill,
              inactiveIcon: RemixIcons.user_3_line,
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.inactiveIcon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData inactiveIcon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: const BoxDecoration(),
            child: Icon(
              isActive ? icon : inactiveIcon,
              size: 22.r,
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
