import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/city.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/city_board.dart';
import '../domain/game_logic.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  var _loading = true;
  List<CityPlayer> _players = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_reload);
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final players = await ref.read(appProvider.notifier).cityPlayers();
    if (!mounted) return;
    setState(() {
      _players = players;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final profile = app.profile;
    final city = cityLabel(profile?.city ?? '');
    final stats = statsFor(app.garage);
    final online = _players.where((p) => p.online).length;
    final others = _players.where((p) => p.id != profile?.id).toList();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text('Город', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              city.isEmpty ? 'Укажи город в профиле' : city,
              style: const TextStyle(color: AppColors.mute),
            ),
            if (city.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _loading
                    ? 'Сверяю, кто сейчас в городе…'
                    : 'Онлайн сейчас: $online • в рейтинге: ${_players.length}',
                style: const TextStyle(color: AppColors.mute, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            if (city.isEmpty)
              const GlassCard(
                child: Text(
                  'Напиши город в настройках — например Красноярск, красноярск или Krasnoyarsk. Это один и тот же город.',
                  style: TextStyle(height: 1.4),
                ),
              )
            else if (_loading)
              const GlassCard(
                child: Text('Загружаю игроков города…'),
              )
            else if (others.isEmpty)
              const GlassCard(
                child: Text(
                  'Других игроков в этом городе пока нет. Ты первый — как только кто-то ещё откроет рейтинг, он появится здесь.',
                  style: TextStyle(height: 1.4),
                ),
              ),
            const SizedBox(height: 12),
            ..._players.asMap().entries.map((entry) {
              final index = entry.key;
              final player = entry.value;
              final mine = player.id == profile?.id;
              final xp = mine ? (profile?.xp ?? player.xp) : player.xp;
              final cars = mine
                  ? stats.count
                  : player.cars;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: mine ? AppColors.orange : AppColors.mute,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mine ? '${player.name} (ты)' : player.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '$xp XP • $cars авто',
                              style: const TextStyle(
                                color: AppColors.mute,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: player.online
                              ? const Color(0xFF16A34A).withValues(alpha: 0.16)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          player.online ? 'онлайн' : 'был',
                          style: TextStyle(
                            color: player.online
                                ? const Color(0xFF4ADE80)
                                : AppColors.mute,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (!_loading && profile != null && _players.isEmpty)
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Row(
                  children: [
                  const Text(
                    '1',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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
                            style: const TextStyle(
                              color: AppColors.mute,
                              fontSize: 12,
                            ),
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
      ),
    );
  }
}
