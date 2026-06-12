import 'package:share_verify/core/data/dto/recipient_dtos.dart';
import 'package:share_verify/core/data/dto/shareholder_dtos.dart';
import 'package:share_verify/core/data/mappers/shareholder_mapper.dart';
import 'package:share_verify/core/models/linked_shareholder.dart';
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
    final travelSupportDto = TravelSupportInfoDto.tryFromJson(
      dto.travelSupportJson,
    );

    return RecipientDetail(
      personId: dto.personId,
      personFullName: dto.personFullName,
      travelSupport: travelSupportDto != null
          ? ShareholderMapper.mapTravelSupport(travelSupportDto)!
          : TravelSupportInfo(
              receiverName: dto.personFullName,
              receiveAmount: 0,
              receiveTime: DateTime.now(),
            ),
      linkedShareholders: dto.linkedShareholders
          .map(
            (link) => LinkedShareholder(
              mcd: link.mcd,
              fullName: link.fullName,
              totalShares: link.totalShares,
              isReceiveMcd: link.isReceiveMcd,
            ),
          )
          .toList(),
    );
  }
}
