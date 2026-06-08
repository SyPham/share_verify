import 'package:get/get.dart';
import 'package:share_verify/core/bindings/shell_binding.dart';
import 'package:share_verify/core/screens/capture/capture_evidence_screen.dart';
import 'package:share_verify/core/screens/shell/shell_screen.dart';
import 'package:share_verify/core/screens/success/success_screen.dart';

class AppRoutes {
  static List<GetPage> pages() => [
        GetPage(
          name: ShellScreen.routeName,
          page: () => const ShellScreen(),
          binding: ShellBinding(),
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
      ];
}
