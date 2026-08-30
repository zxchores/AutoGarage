import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../domain/catalog.dart';
import '../domain/models.dart';
import '../state/app_controller.dart';
import 'spot_screen.dart';
import 'widgets.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.payload});

  final SpotPayload payload;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final spot = widget.payload.spot;
    final extraction = spot.extraction;
    return Scaffold(
      appBar: AppBar(title: const Text('Карточка спота')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.memory(
                Uint8List.fromList(spot.photoBytes),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              RarityBadge(rarity: spot.rarity),
              const Spacer(),
              Text(
                '+${spot.xp} XP',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(spot.title, style: Theme.of(context).textTheme.headlineMedium),
          Text(
            '${extraction.color} • ${extraction.bodyType} • ${extraction.yearFrom}–${extraction.yearTo}',
            style: const TextStyle(color: AppColors.mute),
          ),
          if (spot.duplicateModel) ...[
            const SizedBox(height: 8),
            const Text(
              'Эта модель уже есть в гараже — XP снижен.',
              style: TextStyle(color: AppColors.gold, fontSize: 13),
            ),
          ],
          if (!spot.fromAi) ...[
            const SizedBox(height: 8),
            const Text(
              'Демо-распознавание. Для живого ИИ вставь API-ключ в профиле.',
              style: TextStyle(color: AppColors.mute, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              StatChip(label: 'Цена', value: compact(spot.priceRub)),
              const SizedBox(width: 8),
              StatChip(label: 'Л.с.', value: '${spot.horsepower}'),
              const SizedBox(width: 8),
              StatChip(label: '0–100', value: '${spot.zeroToHundred} с'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatChip(label: 'Привод', value: spot.drivetrain),
              const SizedBox(width: 8),
              StatChip(label: 'Состояние', value: extraction.condition.ru),
              const SizedBox(width: 8),
              StatChip(label: 'Кадр', value: extraction.photoQuality.ru),
            ],
          ),
          const SizedBox(height: 16),
          if (extraction.tuning.chips.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in extraction.tuning.chips)
                  Chip(
                    label: Text(chip),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.line),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          OrangeButton(
            label: 'В гараж',
            icon: Icons.garage_rounded,
            busy: _busy,
            onPressed: () async {
              setState(() => _busy = true);
              try {
                final unlocked = await ref
                    .read(appProvider.notifier)
                    .commitSpot(spot, widget.payload.geo);
                if (!context.mounted) return;
                if (unlocked.isNotEmpty) {
                  final titles = achievements
                      .where((a) => unlocked.contains(a.id))
                      .map((a) => a.title)
                      .join(', ');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Новые достижения: $titles')),
                  );
                }
                context.go('/garage');
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
        ],
      ),
    );
  }
}
