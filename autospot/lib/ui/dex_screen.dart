import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../domain/catalog.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class DexScreen extends ConsumerStatefulWidget {
  const DexScreen({super.key});

  @override
  ConsumerState<DexScreen> createState() => _DexScreenState();
}

class _DexScreenState extends ConsumerState<DexScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final garage = ref.watch(appProvider).garage;
    final collected = garage
        .map((c) => (c.catalogId ?? '${c.make}|${c.model}').toLowerCase())
        .toSet();
    final items = carCatalog.where((spec) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return spec.title.toLowerCase().contains(q) ||
          spec.id.contains(q) ||
          spec.aliases.any((a) => a.toLowerCase().contains(q));
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text('База • ${carCatalog.length}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Марка или модель',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Поймано ${garage.map((c) => c.catalogId ?? c.title).toSet().length} из ${carCatalog.length}',
              style: const TextStyle(color: AppColors.mute),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.78,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final spec = items[index];
                final have = collected.contains(spec.id.toLowerCase()) ||
                    collected.contains('${spec.make}|${spec.model}'.toLowerCase());
                return GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CatalogThumb(spec: spec),
                              if (!have)
                                Container(color: Colors.black.withValues(alpha: 0.35)),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(
                                  have ? Icons.check_circle : Icons.lock_outline,
                                  color: have ? Colors.greenAccent : AppColors.mute,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RarityBadge(rarity: spec.rarity, compact: true),
                            const SizedBox(height: 4),
                            Text(
                              spec.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
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
            ),
          ),
        ],
      ),
    );
  }
}
