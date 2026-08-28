import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/constants.dart';
import 'core/utils/app_router.dart';
import 'features/auth/providers/auth_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const YaaApp(),
    ),
  );
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
