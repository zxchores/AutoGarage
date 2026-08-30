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
                  Row(
                    children: [
                      Expanded(
                        child: Text('ГАРАЖ',
                            style: Theme.of(context).textTheme.headlineMedium),
                      ),
                      IconButton(
                        onPressed: () => context.push('/map'),
                        icon: const Icon(Icons.map_outlined),
                      ),
                      IconButton(
                        onPressed: () => context.push('/dex'),
                        icon: const Icon(Icons.grid_view_rounded),
                      ),
                      IconButton(
                        onPressed: () => context.push('/collections'),
                        icon: const Icon(Icons.collections_bookmark_outlined),
                      ),
                    ],
                  ),
                  Text(
                    app.garage.isEmpty
                        ? 'Пока пусто'
                        : '${app.garage.length} машин • ${compact(stats.value)}',
                    style: const TextStyle(color: AppColors.mute),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (app.garage.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_car, size: 64, color: AppColors.mute),
                    const SizedBox(height: 12),
                    const Text(
                      'Гараж пуст. Поймай первую машину на улице.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mute),
                    ),
                    const SizedBox(height: 18),
                    OrangeButton(
                      label: 'Спотнуть',
                      icon: Icons.camera_alt_rounded,
                      onPressed: () => context.go('/spot'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final car = app.garage[index];
                    return GlassCard(
                      padding: EdgeInsets.zero,
                      onTap: () => context.push('/car/${car.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(22),
                              ),
                              child: SpotPhoto(
                                photoId: car.photoId,
                                borderRadius: 0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RarityBadge(rarity: car.rarity, compact: true),
                                const SizedBox(height: 4),
                                Text(
                                  car.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '+${car.xpEarned} XP',
                                  style: const TextStyle(
                                    color: AppColors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: app.garage.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
