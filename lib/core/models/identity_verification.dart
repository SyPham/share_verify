import 'dart:typed_data';

import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/models/open_ai_usage_info.dart';

class IdentityVerification {
  final String identityNo;
  final String identityType;
  final String receiverName;
  final String? dateOfBirth;
  final String? legacyIdentityNo;
  final String? photoPath;
  final Uint8List? photoBytes;
  final OpenAiUsageInfo? openAiUsage;
  final IdentityCheckResultDto? identityUsageCheck;
  final bool identityUsageAcknowledged;

  const IdentityVerification({
    required this.identityNo,
    required this.identityType,
    required this.receiverName,
    this.dateOfBirth,
    this.legacyIdentityNo,
    this.photoPath,
    this.photoBytes,
    this.openAiUsage,
    this.identityUsageCheck,
    this.identityUsageAcknowledged = false,
  });

  bool get isComplete =>
      identityNo.isNotEmpty &&
      receiverName.isNotEmpty &&
      identityType.isNotEmpty &&
      photoPath != null &&
      photoPath!.isNotEmpty;
}
