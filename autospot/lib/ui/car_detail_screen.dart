import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/city.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/cloud_sync.dart';
import '../domain/models.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class CarDetailScreen extends ConsumerStatefulWidget {
  const CarDetailScreen({super.key, required this.carId});

  final String carId;

  @override
  ConsumerState<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends ConsumerState<CarDetailScreen> {
  List<Sighting> _seen = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSeen);
  }

  Future<void> _loadSeen() async {
    final garage = ref.read(appProvider).garage;
    GarageCar? car;
    for (final item in garage) {
      if (item.id == widget.carId) car = item;
    }
    final id = car?.catalogId;
    if (id == null || id.isEmpty) return;
    final list = await ref.read(appProvider.notifier).carSightings(id);
    if (mounted) setState(() => _seen = list);
  }

  @override
  Widget build(BuildContext context) {
    final garage = ref.watch(appProvider).garage;
    GarageCar? car;
    for (final item in garage) {
      if (item.id == widget.carId) car = item;
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
            [
              if (item.color.isNotEmpty) item.color,
              if (item.generation.isNotEmpty) item.generation,
              '${item.yearFrom}–${item.yearTo}',
            ].join(' • '),
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
                Text('Город: ${item.city.isEmpty ? 'не указан' : cityLabel(item.city)}'),
                if (item.district.isNotEmpty) Text('Район: ${item.district}'),
                Text('Цвет: ${item.color}'),
                Text('Поколение: ${item.generation}'),
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
          const SizedBox(height: 16),
          const Text('Видел такую', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (_seen.isEmpty)
            const Text(
              'Пока никто из города не отметил эту модель',
              style: TextStyle(color: AppColors.mute),
            )
          else
            for (final s in _seen)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text('${s.nick} • ${formatDate(s.at)}'),
                ),
              ),
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
