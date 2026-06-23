import 'package:share_verify/core/models/travel_support_info.dart';

class RecipientCheckIn {
  final String mcd;
  final String shareholderFullName;
  final num totalShares;
  final TravelSupportInfo travelSupport;

  const RecipientCheckIn({
    required this.mcd,
    required this.shareholderFullName,
    required this.totalShares,
    required this.travelSupport,
  });
}
