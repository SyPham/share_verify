import 'dart:typed_data';

class IdentityVerification {
  final String identityNo;
  final String identityType;
  final String receiverName;
  final String? dateOfBirth;
  final String? legacyIdentityNo;
  final String? photoPath;
  final Uint8List? photoBytes;

  const IdentityVerification({
    required this.identityNo,
    required this.identityType,
    required this.receiverName,
    this.dateOfBirth,
    this.legacyIdentityNo,
    this.photoPath,
    this.photoBytes,
  });

  bool get isComplete =>
      identityNo.isNotEmpty &&
      receiverName.isNotEmpty &&
      identityType.isNotEmpty &&
      photoPath != null &&
      photoPath!.isNotEmpty;
}
