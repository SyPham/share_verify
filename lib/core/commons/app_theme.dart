import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/commons/app_typography.dart';

class SvAppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: SvPalette.primary,
      onPrimary: SvPalette.onPrimary,
      primaryContainer: SvPalette.primaryContainer,
      onPrimaryContainer: SvPalette.onPrimaryContainer,
      secondary: SvPalette.secondary,
      onSecondary: SvPalette.onPrimary,
      secondaryContainer: SvPalette.secondaryContainer,
      onSecondaryContainer: SvPalette.onSecondaryContainer,
      tertiary: SvPalette.tertiary,
      onTertiary: SvPalette.onTertiary,
      tertiaryContainer: SvPalette.tertiaryContainer,
      onTertiaryContainer: SvPalette.onTertiaryContainer,
      error: SvPalette.error,
      onError: SvPalette.onPrimary,
      errorContainer: SvPalette.errorContainer,
      onErrorContainer: SvPalette.onErrorContainer,
      surface: SvPalette.surface,
      onSurface: SvPalette.onSurface,
      onSurfaceVariant: SvPalette.onSurfaceVariant,
      outline: SvPalette.outline,
      outlineVariant: SvPalette.outlineVariant,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: SvPalette.background,
      textTheme: SvTypography.textTheme(base.textTheme),
    );
  }
}
