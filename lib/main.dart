import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/constants.dart';
import 'core/utils/app_router.dart';
import 'features/auth/providers/auth_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Les deux en parallèle : le renderer n'a rien à voir avec les
  // préférences, les enchaîner ajouterait leurs durées au démarrage.
  final resultats = await Future.wait([
    SharedPreferences.getInstance(),
    _choisirRendererCarte(),
  ]);
  final prefs = resultats.first as SharedPreferences;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const YaaApp(),
    ),
  );
}

/// Demande le renderer Maps récent, plus rapide à initialiser que
/// l'ancien.
///
/// Doit être appelé avant la création de la toute première carte,
/// sans quoi Android garde le renderer hérité pour toute la durée du
/// processus. C'est aussi pour ça que l'appel est ici et pas dans un
/// écran : à partir du moment où une carte existe, il est trop tard.
///
/// Sans effet hors Android — l'implémentation n'y est pas celle-là.
Future<void> _choisirRendererCarte() async {
  final maps = GoogleMapsFlutterPlatform.instance;
  if (maps is! GoogleMapsFlutterAndroid) return;
  try {
    await maps.initializeWithRenderer(AndroidMapRenderer.latest);
  } catch (_) {
    // Renderer indisponible sur cet appareil : Android retombe seul
    // sur l'ancien. Le démarrage ne doit pas échouer pour autant.
  }
}

class YaaApp extends ConsumerWidget {
  const YaaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Taille de référence de la maquette : tout ce qui passe par
    // AppDimens et AppTextStyles est mis à l'échelle depuis cette
    // base. 375 × 812 correspond à un téléphone courant ; sur un
    // écran plus étroit ou plus large, les tailles suivent.
    return ScreenUtilInit(
      designSize    : const Size(375, 812),
      // Évite que le texte devienne illisible sur les très petits
      // écrans : la taille ne descend pas en dessous du raisonnable.
      minTextAdapt  : true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
