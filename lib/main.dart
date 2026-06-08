import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_theme.dart';
import 'package:share_verify/core/manager/init_application.dart';
import 'package:share_verify/core/route.dart';
import 'package:share_verify/core/screens/shell/shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await InitApplication().runInit();
  runApp(const ShareVerifyApp());
}

class ShareVerifyApp extends StatelessWidget {
  const ShareVerifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShareVerify',
      theme: SvAppTheme.light(),
      initialRoute: ShellScreen.routeName,
      getPages: AppRoutes.pages(),
    );
  }
}
