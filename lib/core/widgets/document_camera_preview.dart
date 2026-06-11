import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:share_verify/core/widgets/document_scan_frame.dart';

class DocumentCameraPreview extends StatefulWidget {
  const DocumentCameraPreview({
    super.key,
    this.showDocumentFrame = false,
    this.frameAspectRatio = kIdCardAspectRatio,
  });

  final bool showDocumentFrame;
  final double frameAspectRatio;

  @override
  State<DocumentCameraPreview> createState() => DocumentCameraPreviewState();
}

class DocumentCameraPreviewState extends State<DocumentCameraPreview>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _errorMessage;
  bool _isCapturing = false;

  final GlobalKey frameKey = GlobalKey();
  final GlobalKey previewKey = GlobalKey();

  bool get isInitialized =>
      _controller != null && _controller!.value.isInitialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeController();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_controller != null) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'Không tìm thấy camera trên thiết bị');
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = await _createBestResolutionController(camera);
      if (!mounted) {
        await controller?.dispose();
        return;
      }
      if (controller == null) {
        setState(() {
          _errorMessage = 'Không khởi tạo được camera ở độ phân giải cao';
        });
        return;
      }

      setState(() {
        _controller = controller;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Không mở được camera. Kiểm tra quyền Camera trong Cài đặt.';
      });
    }
  }

  Future<CameraController?> _createBestResolutionController(
    CameraDescription camera,
  ) async {
    const presets = [
      ResolutionPreset.max,
      ResolutionPreset.ultraHigh,
      ResolutionPreset.veryHigh,
      ResolutionPreset.high,
    ];

    for (final preset in presets) {
      final controller = CameraController(
        camera,
        preset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      try {
        await controller.initialize();
        if (!controller.value.isInitialized) {
          await controller.dispose();
          continue;
        }

        try {
          await controller.setFocusMode(FocusMode.auto);
          await controller.setExposureMode(ExposureMode.auto);
        } catch (_) {}

        return controller;
      } catch (_) {
        await controller.dispose();
      }
    }

    return null;
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<Uint8List?> capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    if (_isCapturing) return null;

    _isCapturing = true;
    try {
      final file = await controller.takePicture();
      return await file.readAsBytes();
    } finally {
      _isCapturing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _CameraError(message: _errorMessage!);
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        KeyedSubtree(
          key: previewKey,
          child: CameraPreview(controller),
        ),
        if (widget.showDocumentFrame)
          DocumentScanFrame(
            frameKey: frameKey,
            aspectRatio: widget.frameAspectRatio,
          ),
      ],
    );
  }
}

class _CameraError extends StatelessWidget {
  final String message;

  const _CameraError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
