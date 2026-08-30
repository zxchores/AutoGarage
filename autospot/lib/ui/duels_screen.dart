import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/city_board.dart';
import '../domain/game_logic.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class DuelsScreen extends ConsumerStatefulWidget {
  const DuelsScreen({super.key});

  @override
  ConsumerState<DuelsScreen> createState() => _DuelsScreenState();
}

class _DuelsScreenState extends ConsumerState<DuelsScreen> {
  final _picked = <String>{};
  List<CityPlayer> _rivals = const [];
  String? _rivalId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final players = await ref.read(appProvider.notifier).cityPlayers();
      if (!mounted) return;
      final me = ref.read(appProvider).profile?.id;
      setState(() {
        _rivals = players.where((p) => p.id != me).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final left = duelCooldownLeft(app.lastDuelAt);
    final rival = _rivals.where((p) => p.id == _rivalId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Дуэль из 3 машин')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Выбери 3 карточки. Сравнение: редкость, цена, л.с., обвесы. Победа +40 XP, ничья +15, поражение +5. Кулдаун 3 минуты. Можно вызвать игрока города или тренировку.',
            style: TextStyle(color: AppColors.mute),
          ),
          const SizedBox(height: 12),
          const Text('Соперник', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Тренировка'),
                selected: _rivalId == null,
                onSelected: (_) => setState(() => _rivalId = null),
              ),
              for (final p in _rivals)
                ChoiceChip(
                  label: Text('${p.name}${p.online ? ' • онлайн' : ''}'),
                  selected: _rivalId == p.id,
                  onSelected: (_) => setState(() => _rivalId = p.id),
                ),
            ],
          ),
          if (left != null) ...[
            const SizedBox(height: 12),
            Text(
              'Следующая дуэль через ${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.gold),
            ),
          ],
          const SizedBox(height: 16),
          if (app.garage.length < 3)
            const Text('Нужно минимум 3 машины в гараже.')
          else
            ...app.garage.map((car) {
              final on = _picked.contains(car.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  onTap: () {
                    setState(() {
                      if (on) {
                        _picked.remove(car.id);
                      } else if (_picked.length < 3) {
                        _picked.add(car.id);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        on ? Icons.check_circle : Icons.circle_outlined,
                        color: on ? AppColors.orange : AppColors.mute,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          car.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      RarityBadge(rarity: car.rarity, compact: true),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          OrangeButton(
            label: 'В бой (${_picked.length}/3)',
            icon: Icons.bolt_rounded,
            onPressed: _picked.length == 3 && left == null
                ? () {
                    final lineup = app.garage
                        .where((c) => _picked.contains(c.id))
                        .toList();
                    try {
                      final record = ref
                          .read(appProvider.notifier)
                          .duelWith(lineup, rival: rival);
                      showDialog<void>(
                        context: context,
                        builder: (_) => _DuelDialog(record: record),
                      );
                      setState(() => _picked.clear());
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                : null,
          ),
          const SizedBox(height: 18),
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
                    '${duel.won ? 'Победа' : duel.draw ? 'Ничья' : 'Поражение'} vs ${duel.rivalName}  ${duel.userPoints}:${duel.rivalPoints}  (+${duelXp(duel)} XP)',
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _DuelDialog extends StatelessWidget {
  const _DuelDialog({required this.record});

  final DuelRecord record;

  @override
  Widget build(BuildContext context) {
    final title = record.draw
        ? 'Ничья'
        : record.won
            ? 'Победа'
            : 'Поражение';
    const labels = {
      'rarest': 'Самая редкая',
      'value': 'Стоимость',
      'hp': 'Л.с.',
      'kits': 'Обвесы',
    };
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('$title  ${record.userPoints}:${record.rivalPoints}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('+${duelXp(record)} XP'),
          const SizedBox(height: 12),
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
