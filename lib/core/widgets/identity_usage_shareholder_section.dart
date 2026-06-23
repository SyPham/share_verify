import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';
import 'package:share_verify/core/widgets/sv_result_info_row.dart';

class IdentityUsageShareholderSection extends StatefulWidget {
  final IdentityCheckResultDto check;
  final TextStyle? titleStyle;

  const IdentityUsageShareholderSection({
    super.key,
    required this.check,
    this.titleStyle,
  });

  @override
  State<IdentityUsageShareholderSection> createState() =>
      _IdentityUsageShareholderSectionState();
}

class _IdentityUsageShareholderSectionState
    extends State<IdentityUsageShareholderSection> {
  List<IdentityCheckUsedShareholderDto>? _shareholders;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _resolveShareholders();
  }

  @override
  void didUpdateWidget(covariant IdentityUsageShareholderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.check != widget.check) {
      _resolveShareholders();
    }
  }

  Future<void> _resolveShareholders() async {
    if (widget.check.usedForShareholders.isNotEmpty) {
      setState(() {
        _shareholders = widget.check.usedForShareholders;
        _loading = false;
      });
      return;
    }

    final mcds = widget.check.usedForMcds.isNotEmpty
        ? widget.check.usedForMcds
        : (widget.check.usedForMcd != null ? [widget.check.usedForMcd!] : []);

    if (mcds.isEmpty) {
      setState(() {
        _shareholders = const [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    final repo = Get.find<ShareholderRepository>();
    final loaded = <IdentityCheckUsedShareholderDto>[];
    for (final mcd in mcds) {
      try {
        final shareholder = await repo.findByMcd(mcd);
        loaded.add(
          IdentityCheckUsedShareholderDto(
            mcd: mcd,
            fullName: shareholder?.fullName,
            shares: shareholder?.shares ?? 0,
          ),
        );
      } catch (_) {
        loaded.add(IdentityCheckUsedShareholderDto(mcd: mcd));
      }
    }

    if (!mounted) return;
    setState(() {
      _shareholders = loaded;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: SvSpacing.xs),
        child: LinearProgressIndicator(),
      );
    }

    final shareholders = _shareholders ?? const [];
    if (shareholders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mã cổ đông đã nhận:',
          style: widget.titleStyle ??
              theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: SvPalette.onSurface,
              ),
        ),
        const SizedBox(height: SvSpacing.sm),
        for (var i = 0; i < shareholders.length; i++) ...[
          if (i > 0) const SizedBox(height: SvSpacing.sm),
          _ShareholderUsageCard(shareholder: shareholders[i]),
        ],
      ],
    );
  }
}

class _ShareholderUsageCard extends StatelessWidget {
  final IdentityCheckUsedShareholderDto shareholder;

  const _ShareholderUsageCard({required this.shareholder});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SvSpacing.sm),
      decoration: BoxDecoration(
        color: SvPalette.surfaceContainerLow,
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
        border: Border.all(color: SvPalette.outlineVariant),
      ),
      child: Column(
        children: [
          SvResultInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Mã cổ đông',
            value: shareholder.mcd,
          ),
          const SizedBox(height: SvSpacing.sm),
          SvResultInfoRow(
            icon: Icons.person_outline,
            label: 'Họ tên',
            value: shareholder.fullName?.trim().isNotEmpty == true
                ? shareholder.fullName!
                : '—',
          ),
          const SizedBox(height: SvSpacing.sm),
          SvResultInfoRow(
            icon: Icons.pie_chart_outline,
            label: 'Số cổ phiếu',
            value: '${shareholder.shares} CP',
          ),
        ],
      ),
    );
  }
}
