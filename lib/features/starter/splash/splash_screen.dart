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
  late final Animation<double> _spinnerFade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _spinnerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2600));
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Logo centré ──────────────────────────────────────
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        width: 200,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Spinner discret en bas ───────────────────────────
            AnimatedBuilder(
              animation: _spinnerFade,
              builder: (_, __) => Opacity(
                opacity: _spinnerFade.value,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 52),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Style bg.jpeg (à tester plus tard) ─────────────────────────────────────
// Stack(
//   children: [
//     Column(
//       children: [
//         SizedBox(
//           height: size.height * 0.55,
//           width: double.infinity,
//           child: ShaderMask(
//             shaderCallback: (rect) => const LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [Colors.white, Colors.transparent],
//               stops: [0.55, 1.0],
//             ).createShader(rect),
//             blendMode: BlendMode.dstIn,
//             child: Image.asset(
//               'assets/images/bg.jpeg',
//               fit: BoxFit.cover,
//               alignment: Alignment.topCenter,
//             ),
//           ),
//         ),
//         Expanded(child: Container(color: Colors.white)),
//       ],
//     ),
//     SafeArea(
//       child: Column(
//         children: [
//           const Spacer(),
//           Center(child: Image.asset('assets/images/logo.jpeg', width: 180)),
//           const Spacer(),
//           // spinner...
//         ],
//       ),
//     ),
//   ],
// )
