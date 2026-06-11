import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/models/travel_support_info.dart';
import 'package:share_verify/core/widgets/evidence_photo_preview.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_result_info_row.dart';

class RecipientInfoSheet extends StatelessWidget {
  final Shareholder shareholder;
  final TravelSupportInfo travelSupport;

  const RecipientInfoSheet({
    super.key,
    required this.shareholder,
    required this.travelSupport,
  });

  static Future<void> show(
    BuildContext context, {
    required Shareholder shareholder,
    required TravelSupportInfo travelSupport,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SvSpacing.radiusXl),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              SvSpacing.containerMargin,
              SvSpacing.md,
              SvSpacing.containerMargin,
              SvSpacing.lg,
            ),
            child: RecipientInfoSheet(
              shareholder: shareholder,
              travelSupport: travelSupport,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipients = _buildRecipientEntries();
    final amountText = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(travelSupport.receiveAmount);
    final timeText = DateFormat('HH:mm dd/MM/yyyy')
        .format(travelSupport.receiveTime.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: SvSpacing.md),
            decoration: BoxDecoration(
              color: SvPalette.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(
          'Thông tin người nhận phụ cấp',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: SvSpacing.xs),
        Text(
          'MCD ${shareholder.code} · ${shareholder.fullName}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: SvSpacing.md),
        SvCard(
          padding: const EdgeInsets.all(SvSpacing.md),
          child: Column(
            children: [
              SvResultInfoRow(
                icon: Icons.payments_outlined,
                label: 'Số tiền đã phát',
                value: amountText,
              ),
              const SizedBox(height: SvSpacing.sm),
              SvResultInfoRow(
                icon: Icons.schedule,
                label: 'Thời gian nhận',
                value: timeText,
              ),
              if (travelSupport.operatorName != null &&
                  travelSupport.operatorName!.isNotEmpty) ...[
                const SizedBox(height: SvSpacing.sm),
                SvResultInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Nhân viên xác nhận',
                  value: travelSupport.operatorName!,
                ),
              ],
              const SizedBox(height: SvSpacing.sm),
              SvResultInfoRow(
                icon: Icons.how_to_reg_outlined,
                label: 'Hình thức',
                value: travelSupport.isProxy ? 'Ủy quyền' : 'Trực tiếp',
              ),
            ],
          ),
        ),
        const SizedBox(height: SvSpacing.md),
        Text(
          'Danh sách người nhận',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SvSpacing.sm),
        ...recipients.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: SvSpacing.sm),
            child: _RecipientCard(entry: entry),
          ),
        ),
      ],
    );
  }

  List<_RecipientEntry> _buildRecipientEntries() {
    final entries = <_RecipientEntry>[];

    if (travelSupport.isProxy) {
      entries.add(
        _RecipientEntry(
          role: 'Cổ đông',
          name: travelSupport.receiverName ?? shareholder.fullName,
          identityNo: shareholder.idNumber.isNotEmpty
              ? shareholder.idNumber
              : null,
          identityType: 'CCCD',
        ),
      );
      if (travelSupport.proxyPersonName != null &&
          travelSupport.proxyPersonName!.isNotEmpty) {
        entries.add(
          _RecipientEntry(
            role: 'Người ủy quyền nhận',
            name: travelSupport.proxyPersonName!,
            identityNo: travelSupport.proxyIdentityNo,
            identityType: travelSupport.proxyIdentityType,
            photoPath: travelSupport.photoPath,
          ),
        );
      }
    } else if (travelSupport.receiverName != null &&
        travelSupport.receiverName!.isNotEmpty) {
      entries.add(
        _RecipientEntry(
          role: 'Người nhận trực tiếp',
          name: travelSupport.receiverName!,
          identityNo: travelSupport.receiverIdentityNo,
          identityType: travelSupport.identityType,
          photoPath: travelSupport.photoPath,
        ),
      );
    }

    if (entries.isEmpty) {
      entries.add(
        _RecipientEntry(
          role: 'Người nhận',
          name: shareholder.fullName,
          photoPath: travelSupport.photoPath,
        ),
      );
    }

    return entries;
  }
}

class _RecipientEntry {
  final String role;
  final String name;
  final String? identityNo;
  final String? identityType;
  final String? photoPath;

  const _RecipientEntry({
    required this.role,
    required this.name,
    this.identityNo,
    this.identityType,
    this.photoPath,
  });
}

class _RecipientCard extends StatelessWidget {
  final _RecipientEntry entry;

  const _RecipientCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SvCard(
      padding: const EdgeInsets.all(SvSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.role,
            style: theme.textTheme.labelLarge?.copyWith(
              color: SvPalette.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          SvResultInfoRow(
            icon: Icons.person_outline,
            label: 'Họ và tên',
            value: entry.name,
          ),
          if (entry.identityNo != null && entry.identityNo!.isNotEmpty) ...[
            const SizedBox(height: SvSpacing.sm),
            SvResultInfoRow(
              icon: Icons.badge_outlined,
              label: 'Số giấy tờ',
              value: entry.identityNo!,
            ),
          ],
          if (entry.identityType != null &&
              entry.identityType!.isNotEmpty) ...[
            const SizedBox(height: SvSpacing.sm),
            SvResultInfoRow(
              icon: Icons.category_outlined,
              label: 'Loại giấy tờ',
              value: entry.identityType!,
            ),
          ],
          const SizedBox(height: SvSpacing.sm),
          EvidencePhotoPreview(
            photoPath: entry.photoPath,
            label: 'Ảnh chứng cứ',
          ),
        ],
      ),
    );
  }
}
