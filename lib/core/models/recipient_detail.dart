import 'package:share_verify/core/models/linked_shareholder.dart';
import 'package:share_verify/core/models/travel_support_info.dart';

class RecipientDetail {
  final int personId;
  final String personFullName;
  final TravelSupportInfo travelSupport;
  final List<LinkedShareholder> linkedShareholders;

  const RecipientDetail({
    required this.personId,
    required this.personFullName,
    required this.travelSupport,
    required this.linkedShareholders,
  });
}
