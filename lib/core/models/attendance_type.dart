enum AttendanceType { direct, proxy }

extension AttendanceTypeApi on AttendanceType {
  String get apiValue => this == AttendanceType.direct ? 'Direct' : 'Proxy';
}
