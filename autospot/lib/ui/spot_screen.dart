import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../data/location_service.dart';
import '../domain/models.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class SpotPayload {
  const SpotPayload({required this.spot, required this.geo});
  final IdentifiedSpot spot;
  final GeoFix? geo;
}

class SpotScreen extends ConsumerStatefulWidget {
  const SpotScreen({super.key});

  @override
  ConsumerState<SpotScreen> createState() => _SpotScreenState();
}

class _SpotScreenState extends ConsumerState<SpotScreen> {
  var _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 72,
      );
      if (file == null) return;
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ScanDialog(),
      );
      final controller = ref.read(appProvider.notifier);
      final locFuture = controller.locate();
      final spot = await controller.identify(file);
      final geo = await locFuture;
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (!spot.extraction.isCar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('На фото не видно автомобиль')),
        );
        return;
      }
      context.push('/result', extra: SpotPayload(spot: spot, geo: geo));
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось распознать: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final demo = app.apiKey == null || app.apiKey!.isEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('СПОТ', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              demo
                  ? 'Демо-режим: машина выбирается стабильно по кадру. Добавь ключ Gemini/OpenAI в профиле.'
                  : 'Кадр уйдёт в Vision API. Номера и лица не распознаём специально.',
              style: const TextStyle(color: AppColors.mute, height: 1.35),
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.orange, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.25),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.center_focus_strong,
                  size: 84,
                  color: AppColors.orange,
                ),
              ),
            ),
            const Spacer(),
            OrangeButton(
              label: 'Открыть камеру',
              icon: Icons.photo_camera_rounded,
              busy: _busy,
              onPressed: () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Взять из галереи'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanDialog extends StatelessWidget {
  const _ScanDialog();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Material(
        color: Colors.transparent,
        child: GlassCard(
          child: SizedBox(
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.orange),
                SizedBox(height: 16),
                Text(
                  'Сканирую кузов, диски, обвес…',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
