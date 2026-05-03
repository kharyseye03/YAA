import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/constants/app_colors.dart';

/// Custom bottom navigation bar with 4 items + centered cart FAB.
/// Layout: [Home] [Search] [cart FAB] [Orders] [Profile]
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.cartItemCount,
    this.onCartTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartItemCount;
  final VoidCallback? onCartTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Bottom bar background ────────────────────────
          // ── Bottom bar background with notch ────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PhysicalShape(
              color: AppColors.white,
              elevation: 8,
              shadowColor: AppColors.black.withValues(alpha: 0.08),
              clipper: _NavBarClipper(),
              child: SizedBox(
                height: 76,
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavItem(
                          icon: RemixIcons.home_6_line,
                          isActive: currentIndex == 0,
                          onTap: () => onTap(0),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: RemixIcons.search_2_line,
                          isActive: currentIndex == 1,
                          onTap: () => onTap(1),
                        ),
                      ),
                      // Spacer for the FAB notch
                      const SizedBox(width: 72),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.receipt_long_outlined,
                          isActive: currentIndex == 2,
                          onTap: () => onTap(2),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: RemixIcons.user_3_line,
                          isActive: currentIndex == 3,
                          onTap: () => onTap(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Cart FAB (centered, floating) ─────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onCartTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),

                    // Cart count badge
                    if (cartItemCount >= 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$cartItemCount',
                              style: TextStyle(
                                fontFamily: 'Archivo',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Icon(
          icon,
          size: 26,
          color: isActive ? AppColors.primary : AppColors.grey500,
        ),
      ),
    );
  }
}
/// Clipper that creates a circular notch in the top-center of the nav bar
/// to accommodate the floating cart FAB.
class _NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notchRadius = 40.0;
    const notchMargin = 8.0;
    const notchDepth = 28.0;

    final path = Path();
    final centerX = size.width / 2;

    path.moveTo(0, 0);
    path.lineTo(centerX - notchRadius - notchMargin, 0);

    // Left curve into notch
    path.quadraticBezierTo(
      centerX - notchRadius,
      0,
      centerX - notchRadius + 6,
      notchDepth * 0.6,
    );

    // Semi-circle notch
    path.arcToPoint(
      Offset(centerX + notchRadius - 6, notchDepth * 0.6),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    // Right curve out of notch
    path.quadraticBezierTo(
      centerX + notchRadius,
      0,
      centerX + notchRadius + notchMargin,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}