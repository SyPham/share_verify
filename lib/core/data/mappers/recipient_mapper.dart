import 'package:share_verify/core/data/dto/recipient_dtos.dart';
import 'package:share_verify/core/data/dto/shareholder_dtos.dart';
import 'package:share_verify/core/data/mappers/shareholder_mapper.dart';
import 'package:share_verify/core/models/recipient_check_in.dart';
import 'package:share_verify/core/models/recipient_detail.dart';
import 'package:share_verify/core/models/recipient_list_item.dart';
import 'package:share_verify/core/models/travel_support_info.dart';

class RecipientMapper {
  static RecipientListItem fromListDto(RecipientListItemDto dto) {
    return RecipientListItem(
      personId: dto.personId,
      displayName: dto.displayName,
      identityNo: dto.identityNo,
      identityType: dto.identityType,
      primaryMcd: dto.primaryMcd,
      receiveAmount: dto.receiveAmount,
      receiveTime: dto.receiveTime,
      isProxy: dto.attendanceType.toLowerCase() == 'proxy',
      proxyPersonName: dto.proxyPersonName,
      linkedMcdCount: dto.linkedMcdCount,
    );
  }

  static RecipientDetail fromDetailDto(RecipientDetailDto dto) {
    return RecipientDetail(
      personId: dto.personId,
      personFullName: dto.personFullName,
      identityNo: dto.identityNo,
      identityType: dto.identityType,
      checkIns: dto.checkIns.map(_mapCheckIn).toList(),
    );
  }

  static RecipientCheckIn _mapCheckIn(RecipientCheckInDto dto) {
    final travelSupportDto = TravelSupportInfoDto.tryFromJson(
      dto.travelSupportJson,
    );

    final fallbackTravelSupport = TravelSupportInfo(
      receiverName: dto.shareholderFullName,
      receiveAmount: 0,
      receiveTime: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );

    return RecipientCheckIn(
      mcd: dto.mcd,
      shareholderFullName: dto.shareholderFullName,
      totalShares: dto.totalShares,
      travelSupport: ShareholderMapper.mapTravelSupport(travelSupportDto) ??
          fallbackTravelSupport,
    );
  }
}
