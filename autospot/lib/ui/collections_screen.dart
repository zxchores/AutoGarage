import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../domain/meta.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garage = ref.watch(appProvider).garage;
    return Scaffold(
      appBar: AppBar(title: const Text('Серии')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: carSeries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final series = carSeries[index];
          final progress = series.progress(garage);
          final done = progress >= series.target;
          return GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(series.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(series.description, style: const TextStyle(color: AppColors.mute)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: series.target == 0 ? 0 : progress / series.target,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: done ? Colors.greenAccent : AppColors.orange,
                  backgroundColor: AppColors.line,
                ),
                const SizedBox(height: 6),
                Text(
                  '$progress / ${series.target}',
                  style: TextStyle(
                    color: done ? Colors.greenAccent : AppColors.mute,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
