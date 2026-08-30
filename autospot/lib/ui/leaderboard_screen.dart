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
    final rivals = rivalsForCity(city, userXp: profile?.xp ?? 0);
    final rows = [
      ...rivals.map(
        (r) => (
          id: r.id,
          name: r.name,
          xp: r.xp,
          value: r.garageValue,
          me: false,
        ),
      ),
      if (profile != null)
        (
          id: profile.id,
          name: profile.name,
          xp: profile.xp,
          value: statsFor(app.garage).value,
          me: true,
        ),
    ]..sort((a, b) => b.xp.compareTo(a.xp));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('ГОРОД', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            city.isEmpty ? 'Укажи город в профиле' : 'Топ споттеров • $city',
            style: const TextStyle(color: AppColors.mute),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OrangeButton(
                  label: 'Дуэли',
                  icon: Icons.bolt_rounded,
                  onPressed: () => context.push('/duels'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: i < 3 ? AppColors.orange : AppColors.mute,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rows[i].me ? '${rows[i].name} (ты)' : rows[i].name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: rows[i].me ? AppColors.orange : AppColors.text,
                        ),
                      ),
                    ),
                    Text('${rows[i].xp} XP'),
                    const SizedBox(width: 10),
                    Text(
                      compact(rows[i].value),
                      style: const TextStyle(color: AppColors.mute, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
