import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/travel_support_info.dart';

class Shareholder {
  final String code;
  final String fullName;
  final String idNumber;
  final int shares;
  final PaymentStatus status;
  final int? personId;
  final TravelSupportInfo? travelSupport;

  const Shareholder({
    required this.code,
    required this.fullName,
    required this.idNumber,
    required this.shares,
    required this.status,
    this.personId,
    this.travelSupport,
  });

  Shareholder copyWith({
    PaymentStatus? status,
    int? personId,
    TravelSupportInfo? travelSupport,
  }) =>
      Shareholder(
        code: code,
        fullName: fullName,
        idNumber: idNumber,
        shares: shares,
        status: status ?? this.status,
        personId: personId ?? this.personId,
        travelSupport: travelSupport ?? this.travelSupport,
      );
}
