import 'package:share_verify/core/config/app_setting.dart';
import 'package:share_verify/core/data/dto/photo_dtos.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/data/sources/photo_remote_source.dart';
import 'package:share_verify/core/data/sources/travel_support_remote_source.dart';
import 'package:share_verify/core/models/attendance_type.dart';
import 'package:share_verify/core/models/identity_verification.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/utils/allowance_amount.dart';

abstract class TravelSupportRepository {
  Future<void> receive({
    required Shareholder shareholder,
    required IdentityVerification identity,
    required AttendanceType attendanceType,
    String? proxyPersonName,
    String? proxyIdentityNo,
    String? proxyIdentityType,
    String? photoPath,
    num receiveAmount = 0,
  });

  Future<PhotoUploadResultDto?> uploadPhoto({
    required List<int> bytes,
    required String fileName,
  });

  Future<IdentityCheckResultDto> checkIdentity({
    required String identityNo,
    required String identityType,
    String? fullName,
    String? dateOfBirth,
  });
}

class TravelSupportRepositoryImpl implements TravelSupportRepository {
  final TravelSupportRemoteSource _remoteSource;
  final PhotoRemoteSource _photoSource;

  TravelSupportRepositoryImpl({
    required TravelSupportRemoteSource remoteSource,
    required PhotoRemoteSource photoSource,
  })  : _remoteSource = remoteSource,
        _photoSource = photoSource;

  @override
  Future<void> receive({
    required Shareholder shareholder,
    required IdentityVerification identity,
    required AttendanceType attendanceType,
    String? proxyPersonName,
    String? proxyIdentityNo,
    String? proxyIdentityType,
    String? photoPath,
    num receiveAmount = 0,
  }) async {
    final effectiveAmount = receiveAmount > 0
        ? receiveAmount
        : AllowanceAmount.forShareholder(shareholder);

    await _remoteSource.receive(
      ReceiveTravelSupportRequest(
        mcd: shareholder.code,
        attendanceType: attendanceType.apiValue,
        receiverName: identity.receiverName,
        receiverIdentityNo: identity.identityNo,
        identityType: identity.identityType,
        proxyPersonName: attendanceType == AttendanceType.proxy
            ? proxyPersonName
            : null,
        proxyIdentityNo: attendanceType == AttendanceType.proxy
            ? proxyIdentityNo
            : null,
        proxyIdentityType: attendanceType == AttendanceType.proxy
            ? proxyIdentityType
            : null,
        receiverDateOfBirth: identity.dateOfBirth,
        receiverLegacyIdentityNo: identity.legacyIdentityNo,
        receiveAmount: effectiveAmount,
        operatorName: AppSetting.operatorName,
        deviceId: AppSetting.deviceId,
        photoPath: photoPath ?? identity.photoPath,
      ),
    );
  }

  @override
  Future<PhotoUploadResultDto?> uploadPhoto({
    required List<int> bytes,
    required String fileName,
  }) async {
    return _photoSource.upload(bytes, fileName);
  }

  @override
  Future<IdentityCheckResultDto> checkIdentity({
    required String identityNo,
    required String identityType,
    String? fullName,
    String? dateOfBirth,
  }) {
    return _remoteSource.checkIdentity(
      identityNo: identityNo,
      identityType: identityType,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
    );
  }
}
