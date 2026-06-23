import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/data/dto/recipient_dtos.dart';
import 'package:share_verify/core/data/mappers/recipient_mapper.dart';

void main() {
  test('maps RecipientListItemDto to RecipientListItem', () {
    final dto = RecipientListItemDto(
      personId: 42,
      displayName: 'Nguyen Van A',
      identityNo: '001234567890',
      identityType: 'CCCD',
      primaryMcd: 'MCD001',
      receiveAmount: 500000,
      receiveTime: DateTime.parse('2026-06-20T08:30:00Z'),
      attendanceType: 'Proxy',
      proxyPersonName: 'Tran Thi B',
      linkedMcdCount: 2,
    );

    final model = RecipientMapper.fromListDto(dto);

    expect(model.personId, 42);
    expect(model.displayName, 'Nguyen Van A');
    expect(model.identityNo, '001234567890');
    expect(model.identityType, 'CCCD');
    expect(model.primaryMcd, 'MCD001');
    expect(model.receiveAmount, 500000);
    expect(model.isProxy, isTrue);
    expect(model.proxyPersonName, 'Tran Thi B');
    expect(model.linkedMcdCount, 2);
  });

  test('maps RecipientDetailDto with multiple check-ins', () {
    final dto = RecipientDetailDto.fromJson({
      'personId': 7,
      'personFullName': 'Le Van C',
      'identityNo': '079123456789',
      'identityType': 'CCCD',
      'checkIns': [
        {
          'mcd': 'MCD010',
          'shareholderFullName': 'Le Van C',
          'totalShares': 1000,
          'travelSupport': {
            'receiverName': 'Le Van C',
            'receiverIdentityNo': '079123456789',
            'identityType': 'CCCD',
            'attendanceType': 'Direct',
            'receiveAmount': 500000,
            'receiveTime': '2026-06-20T08:30:00Z',
            'photoPath': '/uploads/1.jpg',
            'operatorName': 'NV01',
          },
        },
        {
          'mcd': 'MCD011',
          'shareholderFullName': 'Le Van C',
          'totalShares': 1500,
          'travelSupport': {
            'receiverName': 'Tran Thi D',
            'attendanceType': 'Proxy',
            'proxyPersonName': 'Tran Thi D',
            'proxyIdentityNo': '123456789',
            'proxyIdentityType': 'CMND',
            'receiveAmount': 750000,
            'receiveTime': '2026-06-19T08:30:00Z',
          },
        },
      ],
    });

    final model = RecipientMapper.fromDetailDto(dto);

    expect(model.personId, 7);
    expect(model.personFullName, 'Le Van C');
    expect(model.identityNo, '079123456789');
    expect(model.identityType, 'CCCD');
    expect(model.checkIns, hasLength(2));

    expect(model.checkIns.first.mcd, 'MCD010');
    expect(model.checkIns.first.totalShares, 1000);
    expect(model.checkIns.first.travelSupport.receiveAmount, 500000);

    expect(model.checkIns.last.mcd, 'MCD011');
    expect(model.checkIns.last.travelSupport.isProxy, isTrue);
    expect(model.checkIns.last.travelSupport.proxyPersonName, 'Tran Thi D');
  });

  test('uses fallback travel support when payload is invalid', () {
    final dto = RecipientDetailDto.fromJson({
      'personId': 9,
      'personFullName': 'Pham Van E',
      'checkIns': [
        {
          'mcd': 'MCD123',
          'shareholderFullName': 'Pham Van E',
          'totalShares': 2000,
          'travelSupport': {
            'receiverName': 'Pham Van E',
            'receiveAmount': 1000000,
          },
        },
      ],
    });

    final model = RecipientMapper.fromDetailDto(dto);

    expect(model.checkIns, hasLength(1));
    expect(model.checkIns.first.travelSupport.receiverName, 'Pham Van E');
    expect(model.checkIns.first.travelSupport.receiveAmount, 0);
  });
}
