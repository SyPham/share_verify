import 'package:share_verify/core/data/dto/shareholder_dtos.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/models/travel_support_info.dart';

class ShareholderMapper {
  static TravelSupportInfo? _mapTravelSupport(TravelSupportInfoDto? dto) {
    if (dto == null) return null;
    return TravelSupportInfo(
      receiverName: dto.receiverName,
      receiverIdentityNo: dto.receiverIdentityNo,
      identityType: dto.identityType,
      attendanceType: dto.attendanceType,
      proxyPersonName: dto.proxyPersonName,
      proxyIdentityNo: dto.proxyIdentityNo,
      proxyIdentityType: dto.proxyIdentityType,
      receiveAmount: dto.receiveAmount,
      receiveTime: dto.receiveTime,
      photoPath: dto.photoPath,
      operatorName: dto.operatorName,
    );
  }

  static Shareholder fromSearchDto(
    ShareholderSearchDto dto, {
    String? idNumberOverride,
  }) {
    return Shareholder(
      code: dto.mcd,
      fullName: dto.fullName,
      idNumber: idNumberOverride ?? dto.registrationNo ?? '',
      shares: dto.totalShares.round(),
      status: dto.travelSupportReceived
          ? PaymentStatus.received
          : PaymentStatus.notReceived,
    );
  }

  static Shareholder fromDetailDto(ShareholderDetailDto dto) {
    return Shareholder(
      code: dto.mcd,
      fullName: dto.fullName,
      idNumber: dto.registrationNo ?? '',
      shares: dto.totalShares.round(),
      status: dto.allowanceReceived
          ? PaymentStatus.received
          : PaymentStatus.notReceived,
      personId: dto.personId,
      travelSupport: _mapTravelSupport(dto.travelSupport),
    );
  }
}
