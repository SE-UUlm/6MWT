import 'package:go_router/go_router.dart';

import '../features/debug/gps_test_screen.dart';
import '../features/debug/recordings_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/test/walking_test_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/test',
      builder: (context, state) => const WalkingTestScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/debug/recordings',
      builder: (context, state) => const RecordingsScreen(),
    ),
    GoRoute(
      path: '/debug/gps',
      builder: (context, state) => const GpsTestScreen(),
    ),
  ],
);
