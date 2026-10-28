import '../features/about/about_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/app/log.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';
import 'package:six_minute_walk_test/features/history/history_screen.dart';
import 'package:six_minute_walk_test/features/walk/domain/walk_session_provider.dart';
import 'package:six_minute_walk_test/features/walk/presentation/result_screen.dart';
import 'package:six_minute_walk_test/features/walk/presentation/video_screen.dart';

import '../features/home/home_screen.dart';
import '../features/instructions/instructions_screen.dart';
import '../features/walk/presentation/walk_screen.dart';
import '../features/walk/presentation/information_screen.dart';

final _log = appLogger('Router');

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
          // The information screen sets the profile on the session before a
          // test. Without one, for example after the app was restored, no
          // result could be saved.
          redirect: (context, state) {
            final session = ProviderScope.containerOf(
              context,
            ).read(walkSessionProvider);
            if (session.profileId != null) return null;
            _log.w('No profile set on the walk session, returning home');
            return '/';
          },
          builder: (context, state) => const WalkScreen(),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: 'video',
          builder: (context, state) => const VideoScreen(),
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
