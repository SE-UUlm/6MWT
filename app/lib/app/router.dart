import 'package:go_router/go_router.dart';

import '../features/debug/gps_test_screen.dart';
import '../features/home/home_screen.dart';
import '../features/test/walking_test_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/test',
      builder: (context, state) => const WalkingTestScreen(),
    ),
    GoRoute(
      path: '/debug/gps',
      builder: (context, state) => const GpsTestScreen(),
    ),
  ],
);
