import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/models/attendance_type.dart';
import 'package:share_verify/core/widgets/sv_card.dart';

class VerificationAttendanceSection extends StatelessWidget {
  final AttendanceType attendanceType;
  final ValueChanged<AttendanceType> onAttendanceTypeChanged;

  const VerificationAttendanceSection({
    super.key,
    required this.attendanceType,
    required this.onAttendanceTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segmentStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final segmentStyle2 = theme.textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w600, color: Colors.white);
    return SvCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SvSpacing.cardPadding,
        vertical: SvSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hình thức nhận',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SvSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AttendanceType>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: AttendanceType.direct,
                  label: Text(
                    'Trực tiếp',
                    style: segmentStyle2,
                  ),
                  icon: const Icon(Icons.person_outline, size: 22),
                ),
                ButtonSegment(
                  value: AttendanceType.proxy,
                  label: Text('Ủy quyền', style: segmentStyle),
                  icon: const Icon(Icons.assignment_ind_outlined, size: 22),
                ),
              ],
              selected: {attendanceType},
              onSelectionChanged: (selection) {
                onAttendanceTypeChanged(selection.first);
              },
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(
                  const Size(double.infinity, SvSpacing.touchTarget),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: SvSpacing.xs),
                ),
                iconSize: WidgetStateProperty.all(22),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return SvPalette.onPrimary;
                  }
                  return SvPalette.onSurface;
                }),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return SvPalette.primary;
                  }
                  return SvPalette.surfaceContainerLow;
                }),
              ),
            ),
          ),
          const SizedBox(height: SvSpacing.xs),
          Text(
            attendanceType == AttendanceType.direct
                ? 'Lưu thông tin giấy tờ của người nhận trực tiếp (họ tên, số giấy tờ, loại, ảnh).'
                : 'Lưu thông tin giấy tờ của người được ủy quyền đến nhận (họ tên, số giấy tờ, loại, ảnh).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
