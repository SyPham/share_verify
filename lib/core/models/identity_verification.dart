import 'dart:typed_data';

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

  const IdentityVerification({
    required this.identityNo,
    required this.identityType,
    required this.receiverName,
    this.dateOfBirth,
    this.legacyIdentityNo,
    this.photoPath,
    this.photoBytes,
    this.openAiUsage,
  });

  bool get isComplete =>
      identityNo.isNotEmpty &&
      receiverName.isNotEmpty &&
      identityType.isNotEmpty &&
      photoPath != null &&
      photoPath!.isNotEmpty;
}
