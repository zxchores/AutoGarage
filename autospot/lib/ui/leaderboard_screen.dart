import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../domain/game_logic.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final profile = app.profile;
    final city = profile?.city ?? '';
    final stats = statsFor(app.garage);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('ГОРОД', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            city.isEmpty ? 'Укажи город в профиле' : city,
            style: const TextStyle(color: AppColors.mute),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Text(
              'Других игроков в городе пока нет. Ты первый.',
              style: const TextStyle(height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          if (profile != null)
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  const Text(
                    '1',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.name} (ты)',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${profile.xp} XP • ${compact(stats.value)}',
                          style: const TextStyle(color: AppColors.mute, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          OrangeButton(
            label: 'Дуэли',
            icon: Icons.bolt_rounded,
            onPressed: () => context.push('/duels'),
          ),
        ],
      ),
    );
  }
}
