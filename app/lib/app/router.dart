import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../features/debug/gps_test_screen.dart';
import '../features/home/home_screen.dart';
import '../features/instructions/instructions_screen_2.dart';
import '../features/instructions/instructions_screen_3.dart';
import '../features/instructions/instructions_screen_4.dart';
import '../features/instructions/instructions_screen_5.dart';
import '../features/instructions/instructions_screen_6.dart';
import '../features/instructions/instructions_screen_7.dart';
import '../features/walk/presentation/walk_screen.dart';
import '../features/instructions/instructions_screen_1.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/walk', builder: (context, state) => const WalkScreen()),
    GoRoute(
      path: '/debug/gps',
      builder: (context, state) => const GpsTestScreen(),
    ),

    // Route +  Animation - Instructions-1 Page
    GoRoute(
      path: '/instructions-1',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const InstructionsScreen1(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
        );
      },
    ),

    // Route + Animation - Instructions-2 Page
    GoRoute(
      path: '/instructions-2',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const InstructionsScreen2(),
          transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
              ) {
            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(
                  CurveTween(
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
              child: child,
            );
          },
        );
      },
    ),
    // Route + Animation - Instructions-3 Page
    GoRoute(
      path: '/instructions-3',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const InstructionsScreen3(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        );
      },
    ),
    // Route + Animation - Instructions-4 Page
    GoRoute(
      path: '/instructions-4',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const InstructionsScreen4(),
          transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
              ) {
            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(
                  CurveTween(
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
              child: child,
            );
          },
        );
      },
    ),
    // Route + Animation - Instructions-5 Page
    GoRoute(
      path: '/instructions-5',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const InstructionsScreen5(),
          transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
              ) {
            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(
                  CurveTween(
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
              child: child,
            );
          },
        );
      },
    ),
    // Route + Animation - Instructions-6 Page
    GoRoute(
      path: '/instructions-6',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const InstructionsScreen6(),
          transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
              ) {
            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(
                  CurveTween(
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
              child: child,
            );
          },
        );
      },
    ),
    // Route + Animation - Instructions-7 Page
    GoRoute(
      path: '/instructions-7',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const InstructionsScreen7(),
          transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
              ) {
            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(
                  CurveTween(
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
              child: child,
            );
          },
        );
      },
    ),
  ],
);
