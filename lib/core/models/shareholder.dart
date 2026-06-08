import 'package:share_verify/core/models/payment_status.dart';

class Shareholder {
  final String code;
  final String fullName;
  final String idNumber;
  final int shares;
  final PaymentStatus status;

  const Shareholder({
    required this.code,
    required this.fullName,
    required this.idNumber,
    required this.shares,
    required this.status,
  });

  Shareholder copyWith({PaymentStatus? status}) => Shareholder(
        code: code,
        fullName: fullName,
        idNumber: idNumber,
        shares: shares,
        status: status ?? this.status,
      );
}
