import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_router.dart';
import '../widgets/onboarding_page_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    OnboardingPageData(
      imageUrl:
          'https://images.unsplash.com/photo-1553413077-190dd305871c?w=800&q=80',
      title: 'Votre solution\nde livraison',
      badge: '🚚  +2500 livraisons réussies',
      fallbackColor: Color(0xFFD4B896),
    ),
    OnboardingPageData(
      imageUrl:
          'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?w=800&q=80',
      title: 'Livrez plus\nvite et mieux.',
      badge: '🏆  Approuvé par 2500+ clients.',
      fallbackColor: Color(0xFF374151),
    ),
    OnboardingPageData(
      imageUrl:
          'https://images.unsplash.com/photo-1526367790999-0150786686a2?w=800&q=80',
      title: 'Livraison rapide\net fiable',
      badge: 'Envoyez et recevez vos colis\nn\'importe quand, n\'importe où',
      fallbackColor: Color(0xFF1F2937),
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_isLastPage) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _skip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full-screen PageView ──────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _buildPage(_pages[i]),
          ),

          // ── Top overlay: progress bar + Passer ───────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // Progress segments
                    Expanded(
                      child: Row(
                        children: List.generate(_pages.length, (i) {
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 2.5,
                              margin: EdgeInsets.only(
                                  right: i < _pages.length - 1 ? 5 : 0),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(i <= _currentPage ? 1.0 : 0.35),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Skip button
                    AnimatedOpacity(
                      opacity: _isLastPage ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: _skip,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 4, horizontal: 2),
                          child: Text(
                            'Passer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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

  Widget _buildPage(OnboardingPageData page) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // ── Full-screen background image ──────────────────────
        Positioned.fill(
          child: Image.network(
            page.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                ColoredBox(color: page.fallbackColor),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return ColoredBox(color: page.fallbackColor);
            },
          ),
        ),

        // ── Subtle gradient so card blends with image ─────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // ── White bottom card ─────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.fromLTRB(24, 28, 24, bottomPadding + 24),
            child: _buildCardContent(page),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(OnboardingPageData page) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          page.title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 10),

        // Badge / subtitle
        Text(
          page.badge,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF888888),
            height: 1.45,
          ),
        ),

        const SizedBox(height: 28),

        // Buttons
        if (_isLastPage) ...[
          _buildButton(
            'Commencer',
            onPressed: () => context.goNamed(RouteNames.register),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.goNamed(RouteNames.login),
            child: const Center(
              child: Text(
                'J\'ai déjà un compte',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ] else
          _buildButton('Suivant', onPressed: _nextPage),
      ],
    );
  }

  Widget _buildButton(String label, {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
