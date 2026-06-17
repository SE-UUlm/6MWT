import 'package:flutter/material.dart';

import 'screens/gps_test_screen.dart';

void main() {
  runApp(const SixMinuteWalkApp());
}

class SixMinuteWalkApp extends StatelessWidget {
  const SixMinuteWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "6MWT",
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const GpsTestScreen(),
    );
  }
}
