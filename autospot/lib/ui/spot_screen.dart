import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../data/app_permissions.dart';
import '../data/location_service.dart';
import '../domain/game_logic.dart';
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

class _SpotScreenState extends ConsumerState<SpotScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  var _busy = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _camera?.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed) {
      _openCamera();
    }
  }

  Future<void> _openCamera() async {
    await AppPermissions.requestAll();
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _cameraError = 'Камера не найдена');
        return;
      }
      final rear = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final controller = CameraController(
        rear,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _cameraError = null;
      });
    } catch (e) {
      setState(() => _cameraError = 'Нет доступа к камере');
    }
  }

  Future<void> _process(Uint8List bytes) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final controller = ref.read(appProvider.notifier);
      final locFuture = controller.locate();
      final spot = await controller.identifyBytes(bytes);
      final geo = await locFuture;
      if (!mounted) return;
      context.push('/result', extra: SpotPayload(spot: spot, geo: geo));
    } on DuplicatePhotoException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Это фото уже было в гараже')),
        );
      }
    } on NoCarFoundException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } on RecognitionFailedException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось обработать кадр: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shutter() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized || _busy) return;
    final file = await cam.takePicture();
    await _process(Uint8List.fromList(await file.readAsBytes()));
  }

  Future<void> _gallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 72,
    );
    if (file == null) return;
    await _process(Uint8List.fromList(await file.readAsBytes()));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appProvider);
    final hunt = ref.read(appProvider.notifier).hunt;
    final huntDone = ref.read(appProvider.notifier).huntDone;
    final ready = _camera?.value.isInitialized == true;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (ready)
          CameraPreview(_camera!)
        else
          Container(
            color: AppColors.bg,
            child: Center(
              child: Text(
                _cameraError ?? 'Открываю камеру…',
                style: const TextStyle(color: AppColors.mute),
              ),
            ),
          ),
        IgnorePointer(
          child: CustomPaint(painter: _ViewfinderPainter()),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        huntDone ? Icons.check_circle : Icons.flag,
                        color: huntDone ? Colors.greenAccent : AppColors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hunt.title,
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text(
                              huntDone ? 'Уже выполнена сегодня' : hunt.description,
                              style: const TextStyle(
                                color: AppColors.mute,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('+${hunt.bonusXp}',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Определяю модель… обычно 5–8 сек',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _roundBtn(Icons.photo_library_outlined, _busy ? null : _gallery),
                    GestureDetector(
                      onTap: _busy || !ready ? null : _shutter,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.orange, width: 4),
                          color: AppColors.orange.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _roundBtn(Icons.cameraswitch_outlined, _busy ? null : _openCamera),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Наведи на машину — модель определится сама',
                  style: TextStyle(color: AppColors.mute, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.card.withValues(alpha: 0.85),
        child: Icon(icon, color: AppColors.text),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const inset = 36.0;
    final rect = Rect.fromLTWH(
      inset,
      size.height * 0.22,
      size.width - inset * 2,
      size.height * 0.42,
    );
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    canvas.drawRRect(r, paint);
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawPath(
      Path()
        ..addRect(Offset.zero & size)
        ..addRRect(r)
        ..fillType = PathFillType.evenOdd,
      dim,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
