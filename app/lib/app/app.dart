import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

import 'app_colors.dart';
import 'router.dart';
import '../features/walk/presentation/walk_session_lifecycle.dart';

/// Used when the device language is not supported by the app.
const fallbackLocale = Locale('en');

class SixMinuteWalkApp extends StatelessWidget {
  const SixMinuteWalkApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: kDebugMode ? '6MWT Debug' : '6MWT',
      locale: locale,

      // Widgets without an explicit color (dialog buttons, text selection,
      // progress indicators) use the app's blue instead of a generated one.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
        ),
      ),

      // Flutter falls back to the first supported locale.
      supportedLocales: [
        fallbackLocale,
        ...AppLocalizations.supportedLocales.where((l) => l != fallbackLocale),
      ],
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      routerConfig: router,
      builder: (context, child) =>
          WalkSessionLifecycle(child: child ?? const SizedBox.shrink()),
    );
  }
}
