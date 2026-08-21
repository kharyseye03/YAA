import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../service/storage/onboarding_storage.dart';

/// Accueil de première ouverture — un seul écran.
///
/// Trois promesses en une respiration, comme sur YAA PRO, plutôt
/// qu'un carrousel : un onboarding n'a qu'un travail, disparaître
/// vite. Le bouton d'entrée est visible dès la première seconde,
/// personne n'a à traverser quoi que ce soit pour entrer.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Visuel de fond. À remplacer par la photo définitive : c'est la
  /// seule ligne à changer, le reste de l'écran s'y adapte.
  static const _visuel = 'assets/images/l2.png';

  static const _titre = 'Commandez.\nEnvoyez.\nDéplacez-vous.';
  static const _accroche =
      'Vos commerçants, vos colis, vos trajets. YAA vous relie à '
      'tout Conakry, en quelques minutes.';

  @override
  void initState() {
    super.initState();
    // Fond sombre en bas de l'image : les icônes système doivent
    // rester lisibles en clair
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor          : Colors.transparent,
      statusBarIconBrightness : Brightness.light,
      statusBarBrightness     : Brightness.dark,
    ));
  }

  /// Quitte l'onboarding en retenant qu'il a été vu : on ne le
  /// réaffichera plus, même après une déconnexion.
  Future<void> _quitter(String route) async {
    await OnboardingStorage.instance.marquerVu();
    if (mounted) context.goNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Visuel plein écran ────────────────────────────────
          Image.asset(
            _visuel,
            fit: BoxFit.cover,
            // Si le visuel manque, l'écran reste présentable au lieu
            // d'afficher une zone cassée
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin  : Alignment.topCenter,
                  end    : Alignment.bottomCenter,
                  colors : [AppColors.primaryLight, AppColors.primaryDark],
                ),
              ),
            ),
          ),

          // ── Voile sombre, pour que le texte reste lisible ─────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin  : Alignment.topCenter,
                end    : Alignment.bottomCenter,
                stops  : [0.0, 0.35, 0.62, 1.0],
                colors : [
                  Color(0x00000000),
                  Color(0x33000000),
                  Color(0xCC000000),
                  Color(0xF2000000),
                ],
              ),
            ),
          ),

          // ── Contenu, aligné en bas ────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.screenPadding,
                0,
                AppDimens.screenPadding,
                AppDimens.xl,
              ),
              child: Column(
                mainAxisAlignment  : MainAxisAlignment.end,
                crossAxisAlignment : CrossAxisAlignment.start,
                children: [
                  Text(
                    _titre,
                    style: AppTextStyles.h1.copyWith(
                      color      : Colors.white,
                      fontSize   : 42,
                      fontWeight : FontWeight.w800,
                      height     : 1.08,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: AppDimens.lg),

                  Text(
                    _accroche,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color    : Colors.white.withValues(alpha: 0.82),
                      fontSize : 15,
                      height   : 1.55,
                    ),
                  ),

                  const SizedBox(height: AppDimens.xxxl),

                  // ── Entrée principale ───────────────────────────
                  SizedBox(
                    width  : double.infinity,
                    height : 56,
                    child  : ElevatedButton(
                      onPressed: () => _quitter(RouteNames.register),
                      style: ElevatedButton.styleFrom(
                        backgroundColor : AppColors.secondary,
                        foregroundColor : Colors.white,
                        elevation       : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusFull),
                        ),
                      ),
                      child: Text(
                        'Commencer',
                        style: AppTextStyles.labelMedium.copyWith(
                          color      : Colors.white,
                          fontSize   : 16,
                          fontWeight : FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimens.lg),

                  // ── Entrée secondaire ───────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap    : () => _quitter(RouteNames.login),
                      behavior : HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Déjà un compte ?',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Se connecter',
                              style: AppTextStyles.bodySmall.copyWith(
                                color         : Colors.white,
                                fontWeight    : FontWeight.w700,
                                decoration    : TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
