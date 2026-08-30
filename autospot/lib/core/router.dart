import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_controller.dart';
import '../ui/achievements_screen.dart';
import '../ui/car_detail_screen.dart';
import '../ui/duels_screen.dart';
import '../ui/garage_screen.dart';
import '../ui/home_shell.dart';
import '../ui/leaderboard_screen.dart';
import '../ui/onboarding_screen.dart';
import '../ui/profile_screen.dart';
import '../ui/result_screen.dart';
import '../ui/settings_screen.dart';
import '../ui/spot_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(appProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/garage',
    refreshListenable: refresh,
    redirect: (context, state) {
      final app = ref.read(appProvider);
      final loc = state.matchedLocation;
      if (!app.ready) return loc == '/boot' ? null : '/boot';
      if (!app.onboarded) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      if (loc == '/onboarding' || loc == '/boot') return '/garage';
      return null;
    },
    routes: [
      GoRoute(
        path: '/boot',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! SpotPayload) {
            return const Scaffold(
              body: Center(child: Text('Нет карточки спота')),
            );
          }
          return ResultScreen(payload: extra);
        },
      ),
      GoRoute(
        path: '/car/:id',
        builder: (context, state) =>
            CarDetailScreen(carId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/duels',
        builder: (context, state) => const DuelsScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/garage',
                builder: (context, state) => const GarageScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/spot',
                builder: (context, state) => const SpotScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/city',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
