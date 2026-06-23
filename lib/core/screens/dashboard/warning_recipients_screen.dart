import 'package:flutter/material.dart';
import 'package:share_verify/core/bindings/dashboard_drilldown_binding.dart';
import 'package:share_verify/core/screens/recipients/recipients_list_screen.dart';

class WarningRecipientsScreen extends StatelessWidget {
  const WarningRecipientsScreen({super.key});

  static const routeName = '/dashboard/warnings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Người nhận cảnh báo'),
        centerTitle: true,
      ),
      body: const RecipientsListScreen(
        embedded: true,
        title: 'Người nhận cảnh báo',
        controllerTag: DashboardDrilldownBinding.warningRecipientsTag,
      ),
    );
  }
}
