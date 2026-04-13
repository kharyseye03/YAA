import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/constants.dart';
import 'core/utils/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize services (Firebase, API client, etc.)

  runApp(
    const ProviderScope(
      child: YaaApp(),
    ),
  );
}

class YaaApp extends ConsumerWidget {
  const YaaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
