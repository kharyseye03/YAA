import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/constants/app_colors.dart';

class HomeBottomNav extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: currentIndex == 4
                          ? Colors.white
                          : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: currentIndex == 4
                          ? AppColors.primary
                          : Colors.white,
                      size: 22,
                    ),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(),
            child: Icon(
              isActive ? icon : inactiveIcon,
              size: 22,
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
