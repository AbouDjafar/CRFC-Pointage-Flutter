import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system.dart';
import '../data/app_controller.dart';
import 'router.dart';

class CrfcApp extends ConsumerWidget {
  const CrfcApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    final router = ref.watch(appRouterProvider);
    final isDarkMode = appState.value?.preferences.isDarkMode ?? false;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CRFC Pointage',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
