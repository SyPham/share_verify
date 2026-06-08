import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/controllers/capture_controller.dart';
import 'package:share_verify/core/screens/capture/components/capture_overlay_card.dart';

class CaptureEvidenceScreen extends GetView<CaptureController> {
  const CaptureEvidenceScreen({super.key});

  static const routeName = '/capture';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Chụp Minh Chứng'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            child: const Center(child: _ScannerFrame()),
          ),
          Positioned(
            left: SvSpacing.containerMargin,
            right: SvSpacing.containerMargin,
            bottom: SvSpacing.lg,
            child: CaptureOverlayCard(
              shareholder: controller.shareholder,
              onRetake: controller.retake,
              onConfirm: controller.confirm,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.78,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: SvSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54, width: 1.5),
          borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
        ),
        child: const Stack(
          children: [
            _CornerAccent(top: 0, left: 0),
            _CornerAccent(top: 0, right: 0),
            _CornerAccent(bottom: 0, left: 0),
            _CornerAccent(bottom: 0, right: 0),
          ],
        ),
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  const _CornerAccent({
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: top != null
                ? const BorderSide(color: SvPalette.primaryFixed, width: 3)
                : BorderSide.none,
            right: right != null
                ? const BorderSide(color: SvPalette.primaryFixed, width: 3)
                : BorderSide.none,
            bottom: bottom != null
                ? const BorderSide(color: SvPalette.primaryFixed, width: 3)
                : BorderSide.none,
            left: left != null
                ? const BorderSide(color: SvPalette.primaryFixed, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
