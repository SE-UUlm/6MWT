import 'package:flutter/material.dart';

import 'router.dart';

class SixMinuteWalkApp extends StatelessWidget {
  const SixMinuteWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '6MWT',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      routerConfig: router,
    );
  }
}
