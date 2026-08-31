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
        ResolutionPreset.high,
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
          SnackBar(content: Text('$e Кадр сохранён в очередь.')),
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
      maxWidth: 1920,
      imageQuality: 88,
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          huntDone ? Icons.check_circle_outline : Icons.flag_outlined,
                          size: 16,
                          color: huntDone ? Colors.greenAccent : AppColors.orange,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            huntDone ? 'Охота выполнена' : hunt.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${hunt.bonusXp}',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Определяю машину…',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _roundBtn(Icons.photo_library_outlined, _busy ? null : _gallery),
                    GestureDetector(
                      onTap: _busy || !ready ? null : _shutter,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.4),
                        ),
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _busy ? AppColors.mute : Colors.white,
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
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Любой ракурс — машину целиком',
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
        radius: 20,
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        child: Icon(icon, color: AppColors.text, size: 20),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final insetX = size.width * 0.06;
    final insetY = size.height * 0.08;
    final rect = Rect.fromLTWH(
      insetX,
      insetY,
      size.width - insetX * 2,
      size.height - insetY * 2,
    );
    const arm = 22.0;
    void corner(Offset a, Offset b, Offset c) {
      canvas.drawLine(a, b, paint);
      canvas.drawLine(a, c, paint);
    }

    corner(rect.topLeft, rect.topLeft + const Offset(arm, 0), rect.topLeft + const Offset(0, arm));
    corner(rect.topRight, rect.topRight + const Offset(-arm, 0), rect.topRight + const Offset(0, arm));
    corner(rect.bottomLeft, rect.bottomLeft + const Offset(arm, 0), rect.bottomLeft + const Offset(0, -arm));
    corner(rect.bottomRight, rect.bottomRight + const Offset(-arm, 0), rect.bottomRight + const Offset(0, -arm));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
