import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';

class PromoBannerData {
  final String title;
  final String subtitle;
  final String badge;
  final Color  badgeColor; // couleur de la pastille + du dot actif
  final String? image;     // image de fond (asset)

  const PromoBannerData({
    required this.title,
    required this.subtitle,
    required this.badge,
    this.badgeColor = AppColors.primary,
    this.image,
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
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
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
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            padEnds: false, // aligne la 1ère carte à gauche
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
                    ? widget.banners[_currentPage].badgeColor
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Image de fond (ou couleur unie en fallback) ────
            if (data.image != null)
              Image.asset(
                data.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: data.badgeColor),
              )
            else
              Container(color: data.badgeColor),

            // ── Filtre sombre pour la lisibilité du texte ──────
            // Dégradé : plus sombre en bas (là où est le texte)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin  : Alignment.topRight,
                  end    : Alignment.bottomLeft,
                  colors : [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),

            // ── Contenu texte ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment : CrossAxisAlignment.start,
                mainAxisAlignment  : MainAxisAlignment.spaceBetween,
                children: [
                  // Badge en haut à gauche
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color        : data.badgeColor,
                      borderRadius : BorderRadius.circular(6),
                    ),
                    child: Text(
                      data.badge.toUpperCase(),
                      style: const TextStyle(
                        fontFamily    : 'PlusJakartaSans',
                        fontSize      : 10,
                        fontWeight    : FontWeight.w800,
                        color         : Colors.white,
                        letterSpacing : 0.5,
                      ),
                    ),
                  ),

                  // Titre + sous-titre en bas
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          color      : Colors.white,
                          fontSize   : 19,
                          fontWeight : FontWeight.w800,
                          height     : 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color    : Colors.white.withValues(alpha: 0.9),
                          fontSize : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
