import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/models/linked_shareholder.dart';
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
    final travelSupport = detail.travelSupport;
    final amountText =
        '${NumberFormat('#,###').format(travelSupport.receiveAmount)} ₫';
    final timeText = DateFormat('HH:mm dd/MM/yyyy')
        .format(travelSupport.receiveTime.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.personFullName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: SvSpacing.xs),
        Text(
          travelSupport.isProxy ? 'Nhận qua ủy quyền' : 'Nhận trực tiếp',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: SvSpacing.md),
        SvCard(
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
            ],
          ),
        ),
        const SizedBox(height: SvSpacing.md),
        Text(
          'Thông tin người nhận',
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: SvSpacing.sm),
        ..._buildRecipientCards(travelSupport).map(
          (card) => Padding(
            padding: const EdgeInsets.only(bottom: SvSpacing.sm),
            child: card,
          ),
        ),
        const SizedBox(height: SvSpacing.sm),
        Text(
          'Mã cổ đông đã liên kết',
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: SvSpacing.sm),
        SvCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < detail.linkedShareholders.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: SvPalette.outlineVariant,
                    indent: SvSpacing.cardPadding,
                    endIndent: SvSpacing.cardPadding,
                  ),
                _LinkedShareholderTile(
                  shareholder: detail.linkedShareholders[i],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRecipientCards(TravelSupportInfo travelSupport) {
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
          name: detail.personFullName,
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

class _LinkedShareholderTile extends StatelessWidget {
  final LinkedShareholder shareholder;

  const _LinkedShareholderTile({required this.shareholder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SvSpacing.cardPadding,
        vertical: SvSpacing.xs,
      ),
      title: Text(
        shareholder.mcd,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: shareholder.isReceiveMcd ? SvPalette.primary : null,
        ),
      ),
      subtitle: Text(
        shareholder.fullName,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${NumberFormat('#,###').format(shareholder.totalShares)} CP',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (shareholder.isReceiveMcd)
            Text(
              'MCD nhận',
              style: theme.textTheme.labelSmall?.copyWith(
                color: SvPalette.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
