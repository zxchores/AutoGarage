import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../domain/models.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class CarDetailScreen extends ConsumerWidget {
  const CarDetailScreen({super.key, required this.carId});

  final String carId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garage = ref.watch(appProvider).garage;
    GarageCar? car;
    for (final item in garage) {
      if (item.id == carId) car = item;
    }
    if (car == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Машина не найдена')),
      );
    }
    final item = car;
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SpotPhoto(photoId: item.photoId, height: 220, borderRadius: 22),
          const SizedBox(height: 16),
          Row(
            children: [
              RarityBadge(rarity: item.rarity),
              const Spacer(),
              Text(
                '+${item.xpEarned} XP',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
          Text(
            '${item.generation} • ${item.yearFrom}–${item.yearTo}',
            style: const TextStyle(color: AppColors.mute),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StatChip(label: 'Цена', value: compact(item.priceRub)),
              const SizedBox(width: 8),
              StatChip(label: 'Л.с.', value: '${item.horsepower}'),
              const SizedBox(width: 8),
              StatChip(label: '0–100', value: '${item.zeroToHundred} с'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatChip(label: 'Привод', value: item.drivetrain),
              const SizedBox(width: 8),
              StatChip(label: 'Состояние', value: item.condition.ru),
              const SizedBox(width: 8),
              StatChip(label: 'Кадр', value: item.photoQuality.ru),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Спот', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Дата: ${formatDate(item.spottedAt)}'),
                Text('Город: ${item.city.isEmpty ? 'не указан' : item.city}'),
                Text('Цвет: ${item.color}'),
                Text('Уверенность ИИ: ${item.confidence.name}'),
                Text(item.fromAi ? 'Источник: Vision API' : 'Источник: демо-режим'),
              ],
            ),
          ),
          if (item.tuning.chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in item.tuning.chips)
                  Chip(
                    label: Text(chip),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.line),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Назад в гараж'),
          ),
        ],
      ),
    );
  }
}
