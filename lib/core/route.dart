import 'package:get/get.dart';
import 'package:share_verify/core/bindings/dashboard_drilldown_binding.dart';
import 'package:share_verify/core/bindings/open_ai_stats_binding.dart';
import 'package:share_verify/core/bindings/recipients_binding.dart';
import 'package:share_verify/core/bindings/settings_binding.dart';
import 'package:share_verify/core/bindings/shareholders_binding.dart';
import 'package:share_verify/core/bindings/shell_binding.dart';
import 'package:share_verify/core/screens/capture/capture_evidence_screen.dart';
import 'package:share_verify/core/screens/dashboard/received_support_screen.dart';
import 'package:share_verify/core/screens/dashboard/warning_recipients_screen.dart';
import 'package:share_verify/core/screens/openai_stats/open_ai_stats_screen.dart';
import 'package:share_verify/core/screens/recipients/recipient_detail_screen.dart';
import 'package:share_verify/core/screens/recipients/recipients_list_screen.dart';
import 'package:share_verify/core/screens/settings/settings_screen.dart';
import 'package:share_verify/core/screens/shareholders/shareholder_detail_screen.dart';
import 'package:share_verify/core/screens/shareholders/shareholders_list_screen.dart';
import 'package:share_verify/core/screens/shell/shell_screen.dart';
import 'package:share_verify/core/screens/success/success_screen.dart';
import 'package:share_verify/core/screens/verification/shareholder_identity_screen.dart';
import 'package:share_verify/core/screens/verification/verification_barcode_screen.dart';

class AppRoutes {
  static List<GetPage> pages() => [
        GetPage(
          name: ShellScreen.routeName,
          page: () => const ShellScreen(),
          binding: ShellBinding(),
        ),
        GetPage(
          name: ShareholderIdentityScreen.routeName,
          page: () => const ShareholderIdentityScreen(),
        ),
        GetPage(
          name: VerificationBarcodeScreen.routeName,
          page: () => const VerificationBarcodeScreen(),
        ),
        GetPage(
          name: CaptureEvidenceScreen.routeName,
          page: () => const CaptureEvidenceScreen(),
          binding: CaptureBinding(),
        ),
        GetPage(
          name: SuccessScreen.routeName,
          page: () => const SuccessScreen(),
        ),
        GetPage(
          name: SettingsScreen.routeName,
          page: () => const SettingsScreen(),
          binding: SettingsBinding(),
        ),
        GetPage(
          name: OpenAiStatsScreen.routeName,
          page: () => const OpenAiStatsScreen(),
          binding: OpenAiStatsBinding(),
        ),
        GetPage(
          name: RecipientsListScreen.routeName,
          page: () {
            final args = Get.arguments is RecipientsListArgs
                ? Get.arguments as RecipientsListArgs
                : const RecipientsListArgs();
            return RecipientsListScreen(
              embedded: args.embedded,
              title: args.title,
            );
          },
          binding: RecipientsListBinding(),
        ),
        GetPage(
          name: RecipientDetailScreen.routeName,
          page: () => const RecipientDetailScreen(),
          binding: RecipientDetailBinding(),
        ),
        GetPage(
          name: ShareholdersListScreen.routeName,
          page: () {
            final args = Get.arguments is ShareholdersListArgs
                ? Get.arguments as ShareholdersListArgs
                : const ShareholdersListArgs(received: false);
            return ShareholdersListScreen(
              embedded: args.embedded,
              titleOverride: args.title,
            );
          },
          binding: ShareholdersListBinding(),
        ),
        GetPage(
          name: ShareholderDetailScreen.routeName,
          page: () => const ShareholderDetailScreen(),
          binding: ShareholderDetailBinding(),
        ),
        GetPage(
          name: ReceivedSupportScreen.routeName,
          page: () => const ReceivedSupportScreen(),
          binding: DashboardDrilldownBinding(),
        ),
        GetPage(
          name: WarningRecipientsScreen.routeName,
          page: () => const WarningRecipientsScreen(),
          binding: DashboardDrilldownBinding(),
        ),
      ];
}
