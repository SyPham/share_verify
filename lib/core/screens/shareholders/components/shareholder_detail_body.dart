import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/widgets/evidence_photo_preview.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_result_info_row.dart';

class ShareholderDetailBody extends StatelessWidget {
  final Shareholder detail;

  const ShareholderDetailBody({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReceived = detail.status == PaymentStatus.received;
    final travelSupport = detail.travelSupport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.fullName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: SvSpacing.xs),
        Text(
          isReceived
              ? 'Đã check-in và nhận hỗ trợ'
              : 'Chưa check-in nhận hỗ trợ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: SvSpacing.md),
        SvCard(
          child: Column(
            children: [
              SvResultInfoRow(
                icon: Icons.qr_code_2,
                label: 'Mã cổ đông',
                value: detail.code,
              ),
              const SizedBox(height: SvSpacing.sm),
              SvResultInfoRow(
                icon: Icons.badge_outlined,
                label: 'Số giấy tờ',
                value: detail.idNumber.isNotEmpty ? detail.idNumber : 'Chưa có',
              ),
              const SizedBox(height: SvSpacing.sm),
              SvResultInfoRow(
                icon: Icons.stacked_bar_chart,
                label: 'Số cổ phần',
                value: '${NumberFormat('#,###').format(detail.shares)} CP',
              ),
            ],
          ),
        ),
        if (isReceived && travelSupport != null) ...[
          const SizedBox(height: SvSpacing.md),
          Text(
            'Thông tin check-in',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          SvCard(
            child: Column(
              children: [
                SvResultInfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Số tiền đã phát',
                  value:
                      '${NumberFormat('#,###').format(travelSupport.receiveAmount)} ₫',
                ),
                const SizedBox(height: SvSpacing.sm),
                SvResultInfoRow(
                  icon: Icons.schedule,
                  label: 'Thời gian nhận',
                  value: DateFormat('HH:mm dd/MM/yyyy').format(
                    travelSupport.receiveTime.toLocal(),
                  ),
                ),
                const SizedBox(height: SvSpacing.sm),
                SvResultInfoRow(
                  icon: Icons.how_to_vote,
                  label: 'Hình thức',
                  value: travelSupport.isProxy ? 'Ủy quyền' : 'Trực tiếp',
                ),
                if (travelSupport.receiverName != null &&
                    travelSupport.receiverName!.isNotEmpty) ...[
                  const SizedBox(height: SvSpacing.sm),
                  SvResultInfoRow(
                    icon: Icons.person_outline,
                    label: 'Người nhận',
                    value: travelSupport.receiverName!,
                  ),
                ],
                if (travelSupport.receiverIdentityNo != null &&
                    travelSupport.receiverIdentityNo!.isNotEmpty) ...[
                  const SizedBox(height: SvSpacing.sm),
                  SvResultInfoRow(
                    icon: Icons.badge,
                    label: 'Giấy tờ người nhận',
                    value: travelSupport.receiverIdentityNo!,
                  ),
                ],
                if (travelSupport.proxyPersonName != null &&
                    travelSupport.proxyPersonName!.isNotEmpty) ...[
                  const SizedBox(height: SvSpacing.sm),
                  SvResultInfoRow(
                    icon: Icons.groups_2_outlined,
                    label: 'Người được ủy quyền',
                    value: travelSupport.proxyPersonName!,
                  ),
                ],
                if (travelSupport.operatorName != null &&
                    travelSupport.operatorName!.isNotEmpty) ...[
                  const SizedBox(height: SvSpacing.sm),
                  SvResultInfoRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Nhân viên xác nhận',
                    value: travelSupport.operatorName!,
                  ),
                ],
                if (travelSupport.photoPath != null &&
                    travelSupport.photoPath!.isNotEmpty) ...[
                  const SizedBox(height: SvSpacing.sm),
                  EvidencePhotoPreview(
                    photoPath: travelSupport.photoPath,
                    label: 'Ảnh chứng cứ',
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
