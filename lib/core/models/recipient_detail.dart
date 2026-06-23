import 'package:share_verify/core/models/recipient_check_in.dart';

class RecipientDetail {
  final int personId;
  final String personFullName;
  final String? identityNo;
  final String? identityType;
  final List<RecipientCheckIn> checkIns;

  const RecipientDetail({
    required this.personId,
    required this.personFullName,
    this.identityNo,
    this.identityType,
    required this.checkIns,
  });
}
