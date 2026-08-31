import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/city.dart';
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
          Text('Профиль', style: Theme.of(context).textTheme.headlineMedium),
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
                  profile.city.isEmpty ? 'Город не указан' : cityLabel(profile.city),
                  style: const TextStyle(color: AppColors.mute),
                ),
                if (profile.clan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Клан ${profile.clan}',
                      style: const TextStyle(color: AppColors.gold)),
                ],
                const SizedBox(height: 4),
                Text(
                  profile.streak > 0
                      ? 'Серия спотов: ${profile.streak} дн.'
                      : 'Серия спотов ещё не начата',
                  style: const TextStyle(color: AppColors.orange),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: level.progress(profile.xp),
                  minHeight: 6,
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
          const SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ProfileLink(
                  label: 'База машин',
                  onTap: () => context.push('/dex'),
                ),
                const Divider(height: 1, color: AppColors.line),
                _ProfileLink(
                  label: 'Серии-коллекции',
                  onTap: () => context.push('/collections'),
                ),
                const Divider(height: 1, color: AppColors.line),
                _ProfileLink(
                  label: 'Достижения',
                  trailing: '${unlocked.length}/${achievements.length}',
                  onTap: () => context.push('/achievements'),
                ),
                const Divider(height: 1, color: AppColors.line),
                _ProfileLink(
                  label: 'Настройки',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!, style: const TextStyle(color: AppColors.mute)),
          const Icon(Icons.chevron_right, color: AppColors.mute),
        ],
      ),
    );
  }
}

