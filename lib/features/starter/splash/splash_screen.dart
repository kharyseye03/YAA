import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_router.dart';
import '../../auth/providers/auth_notifier.dart';

/// Splash screen — full blue background with centered logo.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    if (isAuthenticated) {
      context.goNamed(RouteNames.home);
    } else {
      context.goNamed(RouteNames.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TODO: Replace with actual SVG logo
              Icon(
                Icons.storefront_outlined,
                color: AppColors.white,
                size: 36,
              ),
              const SizedBox(width: AppDimens.md),
              Text(
                'LOGO',
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
