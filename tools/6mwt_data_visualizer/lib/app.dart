import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';

class VisualizerApp extends StatelessWidget {
  const VisualizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '6MWT Visualizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
