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
    return SvCard(
      padding: const EdgeInsets.all(SvSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hình thức nhận',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          SegmentedButton<AttendanceType>(
            segments: const [
              ButtonSegment(
                value: AttendanceType.direct,
                label: Text('Trực tiếp'),
                icon: Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: AttendanceType.proxy,
                label: Text('Ủy quyền'),
                icon: Icon(Icons.assignment_ind_outlined),
              ),
            ],
            selected: {attendanceType},
            onSelectionChanged: (selection) {
              onAttendanceTypeChanged(selection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
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
          const SizedBox(height: SvSpacing.sm),
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
