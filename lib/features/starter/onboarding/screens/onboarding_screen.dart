import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/dot_indicator.dart';
import '../widgets/onboarding_image_diamonds.dart';
import '../widgets/onboarding_image_grid.dart';
import '../widgets/onboarding_page_data.dart';
import '../widgets/onboarding_image_hexagons.dart';

/// Onboarding screen with swipeable pages.
///
/// Pages 0..n-2 use the grid mosaic layout with "Suivant" + "Passer".
/// Last page uses the diamond mosaic with "Créer un compte" + "Se connecter".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  // ── Page Content ──────────────────────────────────────────
  static const _pages = [
    OnboardingPageData(
      title: 'Tout ce dont vous avez\nbesoin, livré chez vous',
      description:
          'Des boutiques locales aux pharmacies,\ncommandez en quelques clics et recevez vos\nproduits rapidement.',
      images: [
        'assets/images/img1_ob1.png',
        'assets/images/img2_ob1.png',
        'assets/images/img3_ob1.png',
        'assets/images/img4_ob1.png',
        'assets/images/img5_ob1.png',
        'assets/images/img6_ob1.png',
      ],
    ),
    OnboardingPageData(
      title: 'Explorez des centaines\nde boutiques',
      description:
          'Restaurants, pharmacies, supermarchés\net boutiques — tout est à portée de main.',
      images: [
        'assets/images/img4_ob1.png',
        'assets/images/img5_ob1.png',
        'assets/images/img3_ob1.png',
        'assets/images/img1_ob1.png',
        'assets/images/img6_ob1.png',
        'assets/images/img2_ob1.png',
        'assets/images/img1_ob1.png',

      ],
    ),
    // Last page — uses diamond layout
    OnboardingPageData(
      title: 'Prêt à commander ?',
      description:
          'Rejoignez-nous pour simplifier votre\nquotidien et profiter de nos\nmeilleurs services.',
      images: [
        'assets/images/img1_ob1.png',
        'assets/images/img2_ob1.png',
        'assets/images/img3_ob1.png',
        'assets/images/img4_ob1.png',
        'assets/images/img5_ob1.png',
        'assets/images/img6_ob1.png',
        'assets/images/img1_ob3.jpg',
        'assets/images/img2_ob3.png',
      ],
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_isLastPage) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _goToLogin() {
    context.goNamed(RouteNames.login);
  }

  void _goToRegister() {
    context.goNamed(RouteNames.register);
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: Logo + Passer ────────────────────────
            _buildHeader(),

            // ── PageView ─────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),

            // ── Bottom Section ───────────────────────────────
            _buildBottomSection(),

            const SizedBox(height: AppDimens.xxl),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.screenPadding,
        vertical: AppDimens.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppDimens.sm),
              Text(
                'LOGO',
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),

          // "Passer" button — hidden on last page
          if (!_isLastPage)
            GestureDetector(
              onTap: _skip,
              child: Text(
                'Passer',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ── Single Page Content ──────────────────────────────────
  Widget _buildPage(OnboardingPageData page, int index) {
    final isLast = index == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: AppDimens.xxxl),

          // Image layout
          // Image layout
          Expanded(
            flex: 5,
            child: index == 0
                ? OnboardingImageGrid(images: page.images)
                : index == 1
                ? OnboardingImageHexagons(images: page.images)
                : OnboardingImageDiamonds(images: page.images),
          ),

          const SizedBox(height: AppDimens.xxl),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h1.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
              height: 1.25,
            ),
          ),

          const SizedBox(height: AppDimens.md),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey600,
              height: 1.6,
            ),
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }

  // ── Bottom Section ───────────────────────────────────────
  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
      child: _isLastPage ? _buildAuthButtons() : _buildNextSection(),
    );
  }

  /// Pages 0..n-2: Dot indicator + "Suivant" button
  Widget _buildNextSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DotIndicator(
          count: _pages.length,
          currentIndex: _currentPage,
        ),
        const SizedBox(height: AppDimens.xxl),
        YaaButton(
          label: 'Suivant',
          onPressed: _nextPage,
          icon: Icons.arrow_forward,
        ),
      ],
    );
  }

  /// Last page: "Créer un compte" + "Se connecter"
  Widget _buildAuthButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        YaaButton(
          label: 'Créer un compte',
          onPressed: _goToRegister,
        ),
        const SizedBox(height: AppDimens.md),
        YaaButton(
          label: 'Se connecter',
          onPressed: _goToLogin,
          isOutlined: true,
          backgroundColor: AppColors.grey100,
          foregroundColor: AppColors.primary,
        ),
      ],
    );
  }
}
