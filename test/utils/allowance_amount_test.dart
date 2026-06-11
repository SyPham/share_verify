import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/config/app_setting.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/utils/allowance_amount.dart';

void main() {
  test('forShareholder multiplies shares by configured rate', () {
    const shareholder = Shareholder(
      code: 'SH0001',
      fullName: 'Nguyễn Văn A',
      idNumber: '001234567890',
      shares: 10000,
      status: PaymentStatus.notReceived,
    );

    expect(
      AllowanceAmount.forShareholder(shareholder),
      10000 * AppSetting.travelSupportAmountPerShare,
    );
  });

  test('forShareholder falls back to minimum when shares is zero', () {
    const shareholder = Shareholder(
      code: 'SH0002',
      fullName: 'Nguyễn Văn B',
      idNumber: '001234567891',
      shares: 0,
      status: PaymentStatus.notReceived,
    );

    expect(
      AllowanceAmount.forShareholder(shareholder),
      AppSetting.minTravelSupportAmount,
    );
  });
}
