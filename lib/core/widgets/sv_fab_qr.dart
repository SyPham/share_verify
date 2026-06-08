import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/palette.dart';

class SvFabQr extends StatelessWidget {
  final VoidCallback? onPressed;

  const SvFabQr({super.key, this.onPressed});

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: FloatingActionButton(
        onPressed: onPressed,
        elevation: 4,
        backgroundColor: SvPalette.primary,
        foregroundColor: SvPalette.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.qr_code_scanner, size: 28),
      ),
    );
  }
}
