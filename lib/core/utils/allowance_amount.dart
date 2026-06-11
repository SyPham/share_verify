import 'package:share_verify/core/config/app_setting.dart';
import 'package:share_verify/core/models/shareholder.dart';

class AllowanceAmount {
  AllowanceAmount._();

  static num forShareholder(Shareholder shareholder) {
    final amount = shareholder.shares * AppSetting.travelSupportAmountPerShare;
    if (amount > 0) return amount;
    return AppSetting.minTravelSupportAmount;
  }
}
