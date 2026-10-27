import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

/// A [MaterialApp] with the app's localizations, showing [home].
Widget localizedApp({
  required Widget home,
  Locale locale = const Locale('en'),
  TransitionBuilder? builder,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: builder,
  home: home,
);

/// A [MaterialApp.router] with the app's localizations, driven by [router].
Widget localizedRouterApp({
  required GoRouter router,
  Locale locale = const Locale('en'),
}) => MaterialApp.router(
  routerConfig: router,
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);
