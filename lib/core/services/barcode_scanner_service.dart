import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerService {
  Future<String?> scanInvitation(BuildContext context) {
    return _openScanner(
      context,
      title: 'Quét Mã Thiệp Mời',
      instruction: 'Đưa mã QR trên thiệp mời vào giữa khung hình',
    );
  }

  Future<String?> scanCccdQr(BuildContext context) {
    return _openScanner(
      context,
      title: 'Quét QR CCCD',
      instruction: 'Đưa mã QR trên căn cước vào giữa khung hình',
      qrOnly: true,
    );
  }

  Future<String?> scan(BuildContext context) => scanInvitation(context);

  Future<String?> _openScanner(
    BuildContext context, {
    required String title,
    required String instruction,
    bool qrOnly = false,
  }) {
    return Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => _BarcodeScannerPage(
          title: title,
          instruction: instruction,
          qrOnly: qrOnly,
        ),
      ),
    );
  }
}

class _BarcodeScannerPage extends StatefulWidget {
  final String title;
  final String instruction;
  final bool qrOnly;

  const _BarcodeScannerPage({
    required this.title,
    required this.instruction,
    this.qrOnly = false,
  });

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _handled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      formats: widget.qrOnly
          ? const [BarcodeFormat.qrCode]
          : const [
              BarcodeFormat.qrCode,
              BarcodeFormat.code128,
              BarcodeFormat.code39,
              BarcodeFormat.ean13,
              BarcodeFormat.dataMatrix,
            ],
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.stop();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final raw = _readBarcodeValue(barcode);
      if (raw != null && raw.isNotEmpty) {
        _handled = true;
        await _controller.stop();
        if (mounted) Navigator.of(context).pop(raw);
        return;
      }
    }
  }

  String? _readBarcodeValue(Barcode barcode) {
    final raw = barcode.rawValue?.trim();
    if (raw != null && raw.isNotEmpty) return raw;

    final display = barcode.displayValue?.trim();
    if (display != null && display.isNotEmpty) return display;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              _errorMessage ??= error.toString();
              return _ScannerErrorView(
                message:
                    'Không mở được camera. Vui lòng cấp quyền Camera trong Cài đặt hệ thống.',
                detail: error.errorCode.name,
              );
            },
          ),
          const _ScanOverlay(),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Text(
              widget.instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_errorMessage != null)
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  final String message;
  final String? detail;

  const _ScannerErrorView({required this.message, this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
