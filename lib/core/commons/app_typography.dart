import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_verify/core/commons/palette.dart';

class SvTypography {
  static TextTheme textTheme(TextTheme base) =>
      GoogleFonts.beVietnamProTextTheme(base).copyWith(
        displayLarge: GoogleFonts.beVietnamPro(
          fontSize: 40, height: 48 / 40, fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 40, color: SvPalette.primary,
        ),
        headlineLarge: GoogleFonts.beVietnamPro(
          fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w700,
          color: SvPalette.tertiary,
        ),
        headlineMedium: GoogleFonts.beVietnamPro(
          fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w600,
          color: SvPalette.primary,
        ),
        headlineSmall: GoogleFonts.beVietnamPro(
          fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w600,
          color: SvPalette.onSurface,
        ),
        bodyLarge: GoogleFonts.beVietnamPro(
          fontSize: 18, height: 28 / 18, fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.beVietnamPro(
          fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.beVietnamPro(
          fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      );
}
