import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
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
      image: 'assets/images/test4.jpeg',
      title: 'Tout ce dont vous\navez besoin, ici',
      badge: 'Courses, restos, boutiques — en un seul endroit',
      imageAlignment: Alignment.topCenter,
    ),
    OnboardingPageData(
      image: 'assets/images/L1.jpeg',
      title: 'Livré directement\nchez vous',
      badge: 'Livraison rapide partout dans votre ville',
      imageAlignment: Alignment.centerLeft,
    ),
    OnboardingPageData(
      image: 'assets/images/ob3.jpeg',
      title: 'Des milliers de produits',
      badge: 'Nourriture, épicerie, vêtements et bien plus',
      imageAlignment: Alignment.topCenter,
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
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          // ── PageView plein écran ──────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _buildPage(_pages[i]),
          ),

          // ── Barre de progression (top) ────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: List.generate(_pages.length, (i) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 2.5,
                        margin: EdgeInsets.only(
                            right: i < _pages.length - 1 ? 6 : 0),
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
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STYLE NETFLIX — Image plein écran + overlay sombre + texte blanc
  // ═══════════════════════════════════════════════════════════

  Widget _buildPage(OnboardingPageData page) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // 1. Image plein écran
        Positioned.fill(
          child: Image.asset(
            page.image,
            fit: BoxFit.cover,
            alignment: page.imageAlignment,
          ),
        ),

        // 2. Overlay noir semi-transparent sur toute l'image
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
            ),
          ),
        ),

        // 3. Dégradé noir en bas pour faire ressortir le texte
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.75),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: SizedBox(height: 320),
          ),
        ),

        // 4. Contenu texte + boutons en bas
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, safeBottom + 24),
            child: _buildContent(page),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(OnboardingPageData page) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Titre blanc
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: AppTextStyles.h1.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 10),

        // Badge / sous-titre blanc atténué
        Text(
          page.badge,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.75),
            height: 1.5,
          ),
        ),

        const SizedBox(height: 32),

        // Bouton principal
        _buildPrimaryButton(
          _isLastPage ? 'Commencer' : 'Suivant',
          onPressed: _isLastPage
              ? () => context.goNamed(RouteNames.register)
              : _nextPage,
        ),

        const SizedBox(height: 14),

        // Bouton secondaire
        if (_isLastPage)
          _buildSecondaryButton(
            'J\'ai déjà un compte',
            onPressed: () => context.goNamed(RouteNames.login),
          )
        else
          GestureDetector(
            onTap: _skip,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Passer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrimaryButton(String label, {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.white,
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

  Widget _buildSecondaryButton(String label,
      {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ANCIEN STYLE — Dégradé blanc arc en bas (carte blanche)
  // Conservé en commentaire pour référence
  // ═══════════════════════════════════════════════════════════

  // Widget _buildPageArcStyle(OnboardingPageData page) {
  //   final safeBottom = MediaQuery.of(context).padding.bottom;
  //   return Stack(
  //     children: [
  //       Positioned.fill(
  //         child: Image.asset(page.image, fit: BoxFit.cover, alignment: page.imageAlignment),
  //       ),
  //       Positioned(
  //         bottom: 0, left: 0, right: 0,
  //         child: Container(
  //           height: 280,
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               begin: Alignment.topCenter,
  //               end: Alignment.bottomCenter,
  //               colors: [
  //                 Colors.white.withOpacity(0.0),
  //                 Colors.white.withOpacity(0.55),
  //                 Colors.white.withOpacity(0.92),
  //                 Colors.white,
  //               ],
  //               stops: [0.0, 0.28, 0.50, 0.68],
  //             ),
  //             borderRadius: BorderRadius.only(
  //               topLeft: Radius.circular(44),
  //               topRight: Radius.circular(44),
  //             ),
  //           ),
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.end,
  //             children: [
  //               Padding(
  //                 padding: EdgeInsets.fromLTRB(24, 0, 24, safeBottom + 20),
  //                 child: _buildContentArcStyle(page),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
