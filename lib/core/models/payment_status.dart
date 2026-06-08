enum PaymentStatus {
  notReceived,
  received;

  String get verificationBadgeLabel => switch (this) {
        PaymentStatus.notReceived => 'CHƯA NHẬN',
        PaymentStatus.received => 'ĐÃ NHẬN',
      };

  String get dashboardKpiLabel => switch (this) {
        PaymentStatus.notReceived => 'Chưa nhận hỗ trợ',
        PaymentStatus.received => 'Đã nhận hỗ trợ',
      };
}
