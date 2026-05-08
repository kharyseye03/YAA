import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';

class PromoBannerData {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> gradient;

  const PromoBannerData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradient,
  });
}

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
  late final PageController _controller;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88, initialPage: 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Cartes ──────────────────────────────────────────────
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _BannerCard(
                data: widget.banners[i],
                onTap: () => widget.onBannerTap?.call(i),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppDimens.md),

        // ── Dots ────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? widget.banners[_currentPage].gradient.first
                    : AppColors.grey300,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.data, this.onTap});

  final PromoBannerData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: data.gradient,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            // ── Cercles décoratifs en arrière-plan ─────────────
            Positioned(
              right: -18,
              top: -18,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            // ── Contenu ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                children: [
                  // Texte
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge promo
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data.badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          data.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          data.subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Icône dans cercle blanc
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.icon,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
