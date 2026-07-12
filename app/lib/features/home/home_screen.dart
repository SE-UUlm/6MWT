import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Six Minute Walk Test')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/test'),
              child: const Text('Start Walking Test'),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => context.go('/debug/gps'),
              child: const Text('GPS Debug'),
            ),
          ],
        ),
      ),
    );
  }
}
