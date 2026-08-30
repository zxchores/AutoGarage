import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../domain/catalog.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(appProvider).achievements;
    return Scaffold(
      appBar: AppBar(title: const Text('Достижения')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: achievements.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = achievements[index];
          final on = unlocked.contains(item.id);
          return GlassCard(
            child: Row(
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: on ? AppColors.text : AppColors.mute,
                        ),
                      ),
                      Text(
                        item.description,
                        style: const TextStyle(color: AppColors.mute, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  on ? Icons.verified : Icons.lock_outline,
                  color: on ? AppColors.orange : AppColors.mute,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
