import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

import 'router.dart';

class SixMinuteWalkApp extends StatelessWidget {
  const SixMinuteWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '6MWT',

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      supportedLocales: const [
        Locale('de'),
        Locale('en'),
      ],

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: router,
    );
  }
}