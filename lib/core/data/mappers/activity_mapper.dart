import 'package:intl/intl.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/models/activity_item.dart';

class ActivityMapper {
  static ActivityItem fromDto(RecentTravelSupportDto dto) {
    return ActivityItem(
      shareholderCode: dto.mcd,
      fullName: dto.receiverName ?? dto.mcd,
      timeLabel: DateFormat('HH:mm').format(dto.receiveTime.toLocal()),
      statusLabel: 'Thành công',
    );
  }
}
