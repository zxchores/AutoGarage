import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../domain/game_logic.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final stats = statsFor(app.garage);
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ГАРАЖ', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    app.garage.isEmpty
                        ? 'Пока пусто. Первый спот откроет коллекцию.'
                        : '${app.garage.length} машин • ${compact(stats.value)}',
                    style: const TextStyle(color: AppColors.mute),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      StatChip(label: 'Л.с.', value: '${stats.horsepower}'),
                      const SizedBox(width: 8),
                      StatChip(label: 'Обвесы', value: '${stats.bodykits}'),
                      const SizedBox(width: 8),
                      StatChip(label: 'Топ', value: stats.rarest.ru),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          if (app.garage.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Нажми «Спот» и поймай первую машину',
                  style: TextStyle(color: AppColors.mute),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.separated(
                itemCount: app.garage.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final car = app.garage[index];
                  return GlassCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => context.push('/car/${car.id}'),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 92,
                          height: 72,
                          child: SpotPhoto(photoId: car.photoId, borderRadius: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RarityBadge(rarity: car.rarity, compact: true),
                              const SizedBox(height: 6),
                              Text(
                                car.title,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '${car.color} • +${car.xpEarned} XP',
                                style: const TextStyle(
                                  color: AppColors.mute,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.mute),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
