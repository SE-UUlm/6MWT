import 'package:go_router/go_router.dart';

import '../features/debug/gps_test_screen.dart';
import '../features/home/home_screen.dart';
import '../features/walk/walk_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/walk',
      builder: (context, state) => const WalkScreen(),
    ),
    GoRoute(
      path: '/debug/gps',
      builder: (context, state) => const GpsTestScreen(),
    ),
  ],
);
