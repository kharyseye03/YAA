import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_router.dart';
import '../../auth/providers/auth_notifier.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _progressFade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  // ── Logique YAA : vérification auth avant navigation ──────
  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 3000));
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Bracket top-left (primary) ───────────────────────
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.primary, width: 6),
                  left: BorderSide(color: AppColors.primary, width: 6),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                ),
              ),
            ),
          ),

          // ── Bracket bottom-right (secondary) ─────────────────
          Positioned(
            bottom: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.secondary, width: 6),
                  right: BorderSide(color: AppColors.secondary, width: 6),
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),

          // ── Contenu centré ───────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Logo centré
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Image.asset(
                            'assets/images/logo2.jpeg',
                            width: size.width * 0.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // LinearProgressIndicator discret en bas
                AnimatedBuilder(
                  animation: _progressFade,
                  builder: (_, __) => Opacity(
                    opacity: _progressFade.value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 52),
                      child: SizedBox(
                        width: 48,
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
