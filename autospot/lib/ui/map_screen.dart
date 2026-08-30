import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../state/app_controller.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(appProvider).garage.where((c) => c.lat != null && c.lng != null);
    final points = cars
        .map((c) => LatLng(c.lat!, c.lng!))
        .toList();
    final center = points.isNotEmpty ? points.first : const LatLng(55.751244, 37.618423);

    return Scaffold(
      appBar: AppBar(title: const Text('Карта спотов')),
      body: points.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Пока нет спотов с геометкой. Разреши локацию на следующем кадре.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mute),
                ),
              ),
            )
          : FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 11),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.zxchores.autospot',
                ),
                MarkerLayer(
                  markers: [
                    for (final car in cars)
                      Marker(
                        point: LatLng(car.lat!, car.lng!),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: AppColors.orange, size: 36),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
