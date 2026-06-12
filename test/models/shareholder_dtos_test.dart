import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/data/dto/shareholder_dtos.dart';

void main() {
  test('ShareholderDetailDto tolerates invalid travelSupport payload', () {
    final dto = ShareholderDetailDto.fromJson({
      'mcd': 'SH0002',
      'fullName': 'Nguyễn Văn B',
      'totalShares': 5000,
      'allowanceReceived': true,
      'travelSupport': {
        'receiverName': 'Nguyễn Văn B',
        'receiveAmount': 5000000,
      },
    });

    expect(dto.mcd, 'SH0002');
    expect(dto.allowanceReceived, isTrue);
    expect(dto.travelSupport, isNull);
  });

  test('TravelSupportInfoDto parses ISO receiveTime', () {
    final dto = TravelSupportInfoDto.tryFromJson({
      'receiverName': 'Nguyễn Văn B',
      'receiveAmount': 5000000,
      'receiveTime': '2026-06-10T08:40:00Z',
    });

    expect(dto, isNotNull);
    expect(dto!.receiverName, 'Nguyễn Văn B');
    expect(dto.receiveAmount, 5000000);
  });
}
