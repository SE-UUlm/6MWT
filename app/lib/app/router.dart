import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:six_minute_walk_test/features/walk/presentation/result_screen.dart';
import 'package:six_minute_walk_test/features/walk/presentation/video_screen.dart';

import '../features/debug/gps_test_screen.dart';
import '../features/home/home_screen.dart';
import '../features/instructions/instructions_screen_1.dart';
import '../features/instructions/instructions_screen_2.dart';
import '../features/instructions/instructions_screen_3.dart';
import '../features/instructions/instructions_screen_4.dart';
import '../features/instructions/instructions_screen_5.dart';
import '../features/instructions/instructions_screen_6.dart';
import '../features/instructions/instructions_screen_7.dart';
import '../features/walk/presentation/walk_screen.dart';
import '../features/walk/presentation/information_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

    GoRoute(
      path: '/walk',
      builder: (context, state) {
        final profileId = state.extra as int;
        return WalkScreen(profileId: profileId);
      },
    ),

    GoRoute(
      path: '/debug/gps',
      builder: (context, state) => const GpsTestScreen(),
    ),

    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    GoRoute(
      path: '/video',
      builder: (context, state) {
        final profileId = state.extra as int;
        return VideoScreen(profileId: profileId);
      },
    ),

    GoRoute(
      path: '/result',
      builder: (context, state) {
        final profileId = state.extra as int;
        return ResultScreen(profileId: profileId);
      },
    ),

    // Instructions 1–7: Standard-Übergänge
    GoRoute(
      path: '/instructions-1',
      builder: (context, state) => const InstructionsScreen1(),
    ),

    GoRoute(
      path: '/instructions-2',
      builder: (context, state) => const InstructionsScreen2(),
    ),

    GoRoute(
      path: '/instructions-3',
      builder: (context, state) => const InstructionsScreen3(),
    ),

    GoRoute(
      path: '/instructions-4',
      builder: (context, state) => const InstructionsScreen4(),
    ),

    GoRoute(
      path: '/instructions-5',
      builder: (context, state) => const InstructionsScreen5(),
    ),

    GoRoute(
      path: '/instructions-6',
      builder: (context, state) => const InstructionsScreen6(),
    ),

    GoRoute(
      path: '/instructions-7',
      builder: (context, state) => const InstructionsScreen7(),
    ),
  ],
);
