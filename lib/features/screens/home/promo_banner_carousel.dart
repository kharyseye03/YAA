import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';

/// Data model for a promo banner slide.
class PromoBannerData {
  final String title;
  final String description;
  final IconData icon;

  const PromoBannerData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Swipeable promo banner carousel with dot indicators.
class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  final List<PromoBannerData> banners;
  final void Function(int index)? onBannerTap;

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  final _controller = PageController(viewportFraction: 1);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PageView
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PromoBanner(
                  data: widget.banners[index],
                  onTap: () => widget.onBannerTap?.call(index),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppDimens.md),

        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.grey300,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.data, this.onTap});

  final PromoBannerData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1652F0),
              Color(0xFF08399A),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Row(
          children: [
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppDimens.md),

            // Icon circle
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                data.icon,
                color: AppColors.primary,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}