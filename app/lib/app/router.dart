import '../features/about/about_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';
import 'package:six_minute_walk_test/features/history/history_screen.dart';
import 'package:six_minute_walk_test/features/walk/presentation/result_screen.dart';
import 'package:six_minute_walk_test/features/walk/presentation/video_screen.dart';

import '../features/home/home_screen.dart';
import '../features/instructions/instructions_screen.dart';
import '../features/walk/presentation/walk_screen.dart';
import '../features/walk/presentation/information_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      // Every screen is nested under home so that `go(...)` always builds a stack
      // with home at the bottom. `push(...)` only adds the leaf page.
      routes: [
        GoRoute(
          path: 'about',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          path: 'walk',
          builder: (context, state) {
            final profileId = state.extra as int;

            return WalkScreen(profileId: profileId);
          },
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: 'video',
          builder: (context, state) {
            final profileId = state.extra as int;

            return VideoScreen(profileId: profileId);
          },
        ),

        GoRoute(
          path: 'history',
          builder: (context, state) => const HistoryScreen(),
        ),

        GoRoute(
          path: 'instructions',
          builder: (context, state) => const InstructionsScreen(),
        ),

        GoRoute(
          path: 'result',
          builder: (context, state) {
            final session = state.extra as WalkSessionWithProfile;

            return ResultScreen(session: session);
          },
        ),
      ],
    ),
  ],
);
