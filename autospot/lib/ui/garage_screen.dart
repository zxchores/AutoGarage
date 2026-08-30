import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../core/version.dart';
import '../data/update_service.dart';
import '../domain/game_logic.dart';
import '../state/app_controller.dart';
import 'spot_screen.dart';
import 'widgets.dart';

final updateCheckProvider = FutureProvider<AppUpdate?>((ref) {
  return UpdateService().check(appBuild);
});

class GarageScreen extends ConsumerStatefulWidget {
  const GarageScreen({super.key});

  @override
  ConsumerState<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends ConsumerState<GarageScreen> {
  var _query = '';
  Rarity? _rarity;
  var _retrying = false;

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final stats = statsFor(app.garage);
    final cars = app.garage.where((c) {
      if (_rarity != null && c.rarity != _rarity) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.title.toLowerCase().contains(q) ||
          c.color.toLowerCase().contains(q) ||
          c.generation.toLowerCase().contains(q) ||
          c.district.toLowerCase().contains(q);
    }).toList();
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
                  const SizedBox(height: 10),
                  ref.watch(updateCheckProvider).when(
                        data: (u) => u == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassCard(
                                  onTap: () => launchUrl(
                                    Uri.parse(u.apkUrl),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: Text(
                                    'Доступно ${u.version}: ${u.notes.isEmpty ? 'скачать APK' : u.notes}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                  if (app.pendingSpots.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        onTap: _retrying
                            ? null
                            : () async {
                                setState(() => _retrying = true);
                                try {
                                  final first = app.pendingSpots.first;
                                  final spot = await ref
                                      .read(appProvider.notifier)
                                      .retryPending(first);
                                  if (!mounted || spot == null) return;
                                  final geo = await ref
                                      .read(appProvider.notifier)
                                      .locate();
                                  if (!context.mounted) return;
                                  context.push(
                                    '/result',
                                    extra: SpotPayload(spot: spot, geo: geo),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')),
                                  );
                                } finally {
                                  if (mounted) setState(() => _retrying = false);
                                }
                              },
                        child: Text(
                          _retrying
                              ? 'Пробую распознать очередь…'
                              : 'Офлайн-очередь: ${app.pendingSpots.length}. Нажми, чтобы распознать',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Поиск: марка, цвет, поколение',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('Все', _rarity == null, () {
                          setState(() => _rarity = null);
                        }),
                        for (final r in Rarity.values)
                          _chip(r.ru, _rarity == r, () {
                            setState(() => _rarity = r);
                          }),
                      ],
                    ),
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
          else if (cars.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Нет машин по фильтру',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mute),
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
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final car = cars[index];
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
                                  [
                                    if (car.color.isNotEmpty) car.color,
                                    if (car.generation.isNotEmpty) car.generation,
                                  ].join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.mute,
                                    fontSize: 12,
                                  ),
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
                  childCount: cars.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback tap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => tap(),
        selectedColor: AppColors.orange.withValues(alpha: 0.24),
        side: BorderSide(color: on ? AppColors.orange : AppColors.line),
      ),
    );
  }
}
