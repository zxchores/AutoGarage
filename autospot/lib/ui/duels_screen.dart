import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../domain/game_logic.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class DuelsScreen extends ConsumerWidget {
  const DuelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final profile = app.profile;
    final city = profile?.city ?? '';
    final rivals = rivalsForCity(city, userXp: profile?.xp ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Дуэли гаражей')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Асинхронное сравнение: редкость, стоимость гаража, сумма л.с. и число обвесов. Каждая метрика — одно очко.',
            style: TextStyle(color: AppColors.mute),
          ),
          const SizedBox(height: 16),
          Text('Соперники • ${city.isEmpty ? 'без города' : city}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final rival in rivals)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                onTap: () {
                  final record = ref.read(appProvider.notifier).duel(rival);
                  showDialog<void>(
                    context: context,
                    builder: (_) => _DuelDialog(record: record, rival: rival),
                  );
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rival.name,
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                            '${rival.xp} XP • ${compact(rival.garageValue)}',
                            style: const TextStyle(
                              color: AppColors.mute,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.bolt, color: AppColors.orange),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text('История', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (app.duels.isEmpty)
            const Text('Пока нет дуэлей', style: TextStyle(color: AppColors.mute))
          else
            for (final duel in app.duels)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  child: Text(
                    '${duel.won ? 'Победа' : duel.draw ? 'Ничья' : 'Поражение'} vs ${duel.rivalName}  ${duel.userPoints}:${duel.rivalPoints}',
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _DuelDialog extends StatelessWidget {
  const _DuelDialog({required this.record, required this.rival});

  final DuelRecord record;
  final Rival rival;

  @override
  Widget build(BuildContext context) {
    final title = record.draw
        ? 'Ничья'
        : record.won
            ? 'Победа'
            : 'Поражение';
    const labels = {
      'rarest': 'Самая редкая',
      'value': 'Стоимость гаража',
      'hp': 'Суммарные л.с.',
      'kits': 'Обвесы',
    };
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('$title  ${record.userPoints}:${record.rivalPoints}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in record.breakdown.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(labels[entry.key] ?? entry.key)),
                  Text(_line(entry.value)),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  String _line(String raw) {
    final parts = raw.split('|');
    if (parts.length < 3) return raw;
    final mark = switch (parts[0]) {
      'win' => '✓',
      'loss' => '✗',
      _ => '=',
    };
    return '$mark  ${parts[1]} / ${parts[2]}';
  }
}
