import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/constants/app_colors.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            // ── Home ────────────────────────────────────────────
            Expanded(
              child: _NavItem(
                icon: RemixIcons.home_6_line,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
            ),

            // ── Search ──────────────────────────────────────────
            Expanded(
              child: _NavItem(
                icon: RemixIcons.search_2_line,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ),

            // ── Spacer pour le FAB ───────────────────────────────
            const SizedBox(width: 72),

            // ── Orders ──────────────────────────────────────────
            Expanded(
              child: _NavItem(
                icon: Icons.receipt_long_outlined,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),

            // ── Profile ─────────────────────────────────────────
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
