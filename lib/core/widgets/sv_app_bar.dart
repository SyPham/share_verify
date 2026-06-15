import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/palette.dart';

enum _SvAppBarVariant { verification, dashboard }

class SvAppBar extends StatelessWidget implements PreferredSizeWidget {
  final _SvAppBarVariant _variant;
  final String? clockText;
  final VoidCallback? onBack;
  final VoidCallback? onOpenSettings;

  const SvAppBar.verification({
    super.key,
    required this.clockText,
    this.onBack,
    this.onOpenSettings,
  }) : _variant = _SvAppBarVariant.verification;

  const SvAppBar.dashboard({
    super.key,
    this.onOpenSettings,
  })  : _variant = _SvAppBarVariant.dashboard,
        clockText = null,
        onBack = null;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: _variant != _SvAppBarVariant.dashboard,
      leading: _variant == _SvAppBarVariant.dashboard
          ? null
          : onBack != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: SvPalette.onSurface),
                  onPressed: onBack,
                )
              : Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.corporate_fare,
                    color: SvPalette.primary,
                    size: 28,
                  ),
                ),
      leadingWidth: _variant == _SvAppBarVariant.dashboard ? null : 48,
      title: _variant == _SvAppBarVariant.verification
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ĐẠI HỘI CỔ ĐÔNG 2026',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: SvPalette.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  clockText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: SvPalette.onSurfaceVariant,
                  ),
                ),
              ],
            )
          : Text(
              'Xác minh Trợ cấp',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: SvPalette.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
      centerTitle: _variant == _SvAppBarVariant.dashboard,
      actions: [
        if (onOpenSettings != null)
          IconButton(
            icon: Icon(
              Icons.settings,
              color: _variant == _SvAppBarVariant.dashboard
                  ? SvPalette.primary
                  : SvPalette.onSurfaceVariant,
            ),
            onPressed: onOpenSettings,
          ),
      ],
    );
  }
}
