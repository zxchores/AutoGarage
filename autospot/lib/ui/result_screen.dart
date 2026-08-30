import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../domain/catalog.dart';
import '../domain/game_logic.dart';
import '../state/app_controller.dart';
import 'spot_screen.dart';
import 'widgets.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.payload});

  final SpotPayload payload;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  late IdentifiedSpot _spot;
  var _phase = 0; // 0 scan, 1 pick, 2 reveal, 3 card
  var _busy = false;
  late final AnimationController _scan;
  late final AnimationController _reveal;
  String _scanLine = 'Ищу кузов…';

  @override
  void initState() {
    super.initState();
    _spot = widget.payload.spot;
    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _runScan();
  }

  Future<void> _runScan() async {
    const lines = ['Ищу кузов…', 'Читаю шильдик…', 'Сверяю с базой…'];
    for (var i = 0; i < lines.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
      setState(() => _scanLine = lines[i]);
    }
    if (!mounted) return;
    if (_spot.needsCatalogPick || _spot.spec == null) {
      setState(() => _phase = 1);
    } else {
      _startReveal();
    }
  }

  void _startReveal() {
    setState(() => _phase = 2);
    _reveal.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _phase = 3);
    });
  }

  @override
  void dispose() {
    _scan.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 0) return _scanView();
    if (_phase == 1) return _picker();
    if (_phase == 2) return _revealView();
    return _card();
  }

  Widget _photo() {
    return Image.memory(
      Uint8List.fromList(_spot.photoBytes),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _scanView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _photo(),
          AnimatedBuilder(
            animation: _scan,
            builder: (context, _) {
              return Align(
                alignment: Alignment(0, -1 + 2 * _scan.value),
                child: Container(
                  height: 3,
                  color: AppColors.orange,
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                _scanLine,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _picker() {
    final query = ValueNotifier('');
    return Scaffold(
      appBar: AppBar(title: const Text('Выбери из базы')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Марка или модель',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => query.value = v,
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: query,
              builder: (context, q, _) {
                final needle = q.toLowerCase();
                final items = carCatalog.where((c) {
                  return needle.isEmpty ||
                      c.title.toLowerCase().contains(needle) ||
                      c.id.contains(needle);
                }).toList();
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final spec = items[i];
                    return GlassCard(
                      padding: EdgeInsets.zero,
                      onTap: () {
                        _spot = ref.read(appProvider.notifier).pickModel(_spot, spec);
                        _startReveal();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                            child: CatalogThumb(spec: spec),
                          )),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RarityBadge(rarity: spec.rarity, compact: true),
                                const SizedBox(height: 4),
                                Text(spec.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                Text(
                                  compact(spec.priceRub),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _revealView() {
    final color = AppColors.rarity(_spot.rarity);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _reveal, curve: Curves.easeOutBack),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: color, size: 64),
              const SizedBox(height: 12),
              Text(
                _spot.rarity.label,
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(_spot.title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card() {
    final extraction = _spot.extraction;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _photo()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                const SizedBox(height: 180),
                Row(
                  children: [
                    RarityBadge(rarity: _spot.rarity),
                    const Spacer(),
                    Text(
                      '+${_spot.xp} XP',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_spot.title, style: Theme.of(context).textTheme.headlineMedium),
                Text(
                  '${extraction.color} • ${_spot.spec?.bodyType ?? ''} • ${_spot.spec?.years ?? ''}',
                  style: const TextStyle(color: AppColors.mute),
                ),
                if (_spot.firstCatch)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Первый экземпляр модели',
                        style: TextStyle(color: Colors.greenAccent)),
                  ),
                if (_spot.duplicateModel)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Дубликат — XP снижен',
                        style: TextStyle(color: AppColors.gold)),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    StatChip(label: 'Цена', value: compact(_spot.priceRub)),
                    const SizedBox(width: 8),
                    StatChip(label: 'Л.с.', value: '${_spot.horsepower}'),
                    const SizedBox(width: 8),
                    StatChip(label: '0–100', value: '${_spot.zeroToHundred} с'),
                  ],
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Откуда XP',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      for (final line in _spot.breakdown.lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(line.$1)),
                              Text(line.$2,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_spot.photoHints.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ..._spot.photoHints.map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $h',
                          style: const TextStyle(color: AppColors.mute)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _phase = 1),
                  child: const Text('Это не та модель'),
                ),
                OrangeButton(
                  label: 'В гараж',
                  icon: Icons.garage_rounded,
                  busy: _busy,
                  onPressed: () async {
                    setState(() => _busy = true);
                    try {
                      final unlocked = await ref
                          .read(appProvider.notifier)
                          .commitSpot(_spot, widget.payload.geo);
                      if (!mounted) return;
                      if (unlocked.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Новые достижения: ${unlocked.join(', ')}',
                            ),
                          ),
                        );
                      }
                      context.go('/garage');
                    } on DuplicatePhotoException {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Это фото уже было в гараже'),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
