enum VerificationStep { attendance, identity, evidence, barcode }

extension VerificationStepX on VerificationStep {
  int get number => switch (this) {
        VerificationStep.attendance => 1,
        VerificationStep.identity => 2,
        VerificationStep.evidence => 3,
        VerificationStep.barcode => 4,
      };

  String get title => switch (this) {
        VerificationStep.attendance => 'Hình thức nhận',
        VerificationStep.identity => 'Xác minh giấy tờ',
        VerificationStep.evidence => 'Chụp ảnh chứng cứ',
        VerificationStep.barcode => 'Quét mã cổ đông',
      };
}
