import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../domain/catalog.dart';
import '../domain/game_logic.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final profile = app.profile;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final level = levelFor(profile.xp);
    final unlocked = app.achievements;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('ПРОФИЛЬ', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
                if (profile.login.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('@${profile.login}',
                      style: const TextStyle(color: AppColors.mute)),
                ],
                const SizedBox(height: 4),
                Text(
                  '${level.title}  •  ур. ${level.level}',
                  style: const TextStyle(color: AppColors.orange),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.city.isEmpty ? 'Город не указан' : profile.city,
                  style: const TextStyle(color: AppColors.mute),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: level.progress(profile.xp),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.orange,
                  backgroundColor: AppColors.line,
                ),
                const SizedBox(height: 8),
                Text(
                  level.nextXp == null
                      ? '${profile.xp} XP • максимум'
                      : '${profile.xp} / ${level.nextXp} XP',
                  style: const TextStyle(color: AppColors.mute, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            onTap: () => context.push('/dex'),
            child: const Row(
              children: [
                Expanded(
                  child: Text('База машин',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                Icon(Icons.chevron_right, color: AppColors.mute),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            onTap: () => context.push('/collections'),
            child: const Row(
              children: [
                Expanded(
                  child: Text('Серии-коллекции',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                Icon(Icons.chevron_right, color: AppColors.mute),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            onTap: () => context.push('/achievements'),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Достижения',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                Text('${unlocked.length}/${achievements.length}'),
                const Icon(Icons.chevron_right, color: AppColors.mute),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            onTap: () => context.push('/settings'),
            child: const Row(
              children: [
                Expanded(
                  child: Text('Настройки и API-ключ',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                Icon(Icons.chevron_right, color: AppColors.mute),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
