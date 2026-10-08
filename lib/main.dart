import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/constants.dart';
import 'core/utils/app_router.dart';
import 'service/auth/token_storage.dart';
import 'service/notifications/push_service.dart';
import 'features/auth/providers/auth_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  rendererCarte = _choisirRendererCarte();

  final prefs = await SharedPreferences.getInstance();

  await TokenStorage.purgerAncienStockage(prefs);

  // Avant runApp : c'est ici que se récupère le message ayant réveillé
  // une app fermée. N'échoue jamais — sans Firebase configuré, le
  // service se désactive et l'app démarre normalement.
  await PushService.instance.initialiser();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const YaaApp(),
    ),
  );
}

/// Choix du renderer, en cours ou terminé.
///
/// Exposé pour que le pré-chauffage de carte puisse l'attendre :
/// créer une carte avant la fin de cette initialisation fige le
/// renderer hérité pour toute la durée du processus.
late final Future<void> rendererCarte;

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
  }
}

class YaaApp extends ConsumerStatefulWidget {
  const YaaApp({super.key});

  @override
  ConsumerState<YaaApp> createState() => _YaaAppState();
}

class _YaaAppState extends ConsumerState<YaaApp> {
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Le service reçoit les notifications, il ne sait pas naviguer :
    // on lui donne ici de quoi le faire, une fois le routeur construit.
    PushService.instance.onOuverture = (donnees) {
      final type = donnees['type']?.toString() ?? '';
      // Une notification de commande mène à la liste des commandes ;
      // tout le reste à l'écran Notifications, qui sert de repli.
      final destination = type.startsWith('COMMANDE') ||
              type == 'COURSIER_ASSIGNE' ||
              type == 'EN_LIVRAISON' ||
              type == 'LIVREE'
          ? RoutePaths.orders
          : RoutePaths.notifications;
      router.go(destination);
    };

    return ScreenUtilInit(
      designSize    : const Size(375, 812),
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
