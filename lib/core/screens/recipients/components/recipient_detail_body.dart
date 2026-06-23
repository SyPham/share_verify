import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/models/recipient_check_in.dart';
import 'package:share_verify/core/models/recipient_detail.dart';
import 'package:share_verify/core/models/travel_support_info.dart';
import 'package:share_verify/core/widgets/evidence_photo_preview.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_result_info_row.dart';

class RecipientDetailBody extends StatelessWidget {
  final RecipientDetail detail;

  const RecipientDetailBody({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.personFullName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (detail.identityNo != null && detail.identityNo!.isNotEmpty) ...[
          const SizedBox(height: SvSpacing.xs),
          Text(
            [
              detail.identityNo,
              if (detail.identityType != null &&
                  detail.identityType!.isNotEmpty)
                detail.identityType,
            ].whereType<String>().join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: SvSpacing.md),
        if (detail.checkIns.isEmpty)
          Text(
            'Chưa có lượt check-in nào',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...detail.checkIns.asMap().entries.map((entry) {
            final checkInIndex = entry.key + 1;
            final checkIn = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: SvSpacing.md),
              child: _CheckInBlock(
                checkInIndex: checkInIndex,
                checkIn: checkIn,
                fallbackReceiverName: detail.personFullName,
              ),
            );
          }),
      ],
    );
  }
}

class _CheckInBlock extends StatelessWidget {
  final int checkInIndex;
  final RecipientCheckIn checkIn;
  final String fallbackReceiverName;

  const _CheckInBlock({
    required this.checkInIndex,
    required this.checkIn,
    required this.fallbackReceiverName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final travelSupport = checkIn.travelSupport;
    final amountText =
        '${NumberFormat('#,###').format(travelSupport.receiveAmount)} ₫';
    final timeText = DateFormat('HH:mm dd/MM/yyyy')
        .format(travelSupport.receiveTime.toLocal());

    return SvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lượt check-in #$checkInIndex',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          SvResultInfoRow(
            icon: Icons.badge_outlined,
            label: 'Mã cổ đông',
            value: checkIn.mcd,
          ),
          const SizedBox(height: SvSpacing.sm),
          SvResultInfoRow(
            icon: Icons.person_outline,
            label: 'Tên cổ đông',
            value: checkIn.shareholderFullName,
          ),
          const SizedBox(height: SvSpacing.sm),
          SvResultInfoRow(
            icon: Icons.pie_chart_outline,
            label: 'Số cổ phần',
            value: '${NumberFormat('#,###').format(checkIn.totalShares)} CP',
          ),
          const SizedBox(height: SvSpacing.sm),
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
              icon: Icons.badge,
              label: 'Nhân viên xác nhận',
              value: travelSupport.operatorName!,
            ),
          ],
          const SizedBox(height: SvSpacing.md),
          Text(
            'Thông tin người nhận',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          ..._buildRecipientCards(
            travelSupport: travelSupport,
            fallbackReceiverName: fallbackReceiverName,
          ).map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: SvSpacing.sm),
              child: card,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecipientCards({
    required TravelSupportInfo travelSupport,
    required String fallbackReceiverName,
  }) {
    final cards = <Widget>[];

    if (travelSupport.isProxy) {
      if (travelSupport.proxyPersonName != null &&
          travelSupport.proxyPersonName!.isNotEmpty) {
        cards.add(
          _PersonEvidenceCard(
            role: 'Người ủy quyền nhận',
            name: travelSupport.proxyPersonName!,
            identityNo: travelSupport.proxyIdentityNo,
            identityType: travelSupport.proxyIdentityType,
            photoPath: travelSupport.photoPath,
          ),
        );
      }
      if (travelSupport.receiverName != null &&
          travelSupport.receiverName!.isNotEmpty) {
        cards.add(
          _PersonEvidenceCard(
            role: 'Cổ đông',
            name: travelSupport.receiverName!,
            identityNo: travelSupport.receiverIdentityNo,
            identityType: travelSupport.identityType,
          ),
        );
      }
    } else if (travelSupport.receiverName != null &&
        travelSupport.receiverName!.isNotEmpty) {
      cards.add(
        _PersonEvidenceCard(
          role: 'Người nhận trực tiếp',
          name: travelSupport.receiverName!,
          identityNo: travelSupport.receiverIdentityNo,
          identityType: travelSupport.identityType,
          photoPath: travelSupport.photoPath,
        ),
      );
    }

    if (cards.isEmpty) {
      cards.add(
        _PersonEvidenceCard(
          role: 'Người nhận',
          name: fallbackReceiverName,
          photoPath: travelSupport.photoPath,
        ),
      );
    }

    return cards;
  }
}

class _PersonEvidenceCard extends StatelessWidget {
  final String role;
  final String name;
  final String? identityNo;
  final String? identityType;
  final String? photoPath;

  const _PersonEvidenceCard({
    required this.role,
    required this.name,
    this.identityNo,
    this.identityType,
    this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: theme.textTheme.labelLarge?.copyWith(
              color: SvPalette.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          SvResultInfoRow(
            icon: Icons.person_outline,
            label: 'Họ và tên',
            value: name,
          ),
          if (identityNo != null && identityNo!.isNotEmpty) ...[
            const SizedBox(height: SvSpacing.sm),
            SvResultInfoRow(
              icon: Icons.badge_outlined,
              label: 'Số giấy tờ',
              value: identityNo!,
            ),
          ],
          if (identityType != null && identityType!.isNotEmpty) ...[
            const SizedBox(height: SvSpacing.sm),
            SvResultInfoRow(
              icon: Icons.category_outlined,
              label: 'Loại giấy tờ',
              value: identityType!,
            ),
          ],
          const SizedBox(height: SvSpacing.sm),
          EvidencePhotoPreview(
            photoPath: photoPath,
            label: 'Ảnh chứng cứ',
          ),
        ],
      ),
    );
  }
}
