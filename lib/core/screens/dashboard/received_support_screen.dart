import 'package:flutter/material.dart';
import 'package:share_verify/core/bindings/dashboard_drilldown_binding.dart';
import 'package:share_verify/core/screens/recipients/recipients_list_screen.dart';
import 'package:share_verify/core/screens/shareholders/shareholders_list_screen.dart';

class ReceivedSupportScreen extends StatelessWidget {
  const ReceivedSupportScreen({super.key});

  static const routeName = '/dashboard/received';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đã nhận hỗ trợ'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Theo cổ đông'),
              Tab(text: 'Theo người nhận'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ShareholdersListScreen(
              embedded: true,
              controllerTag: DashboardDrilldownBinding.receivedShareholdersTag,
            ),
            RecipientsListScreen(
              embedded: true,
              title: 'Người nhận đã check-in',
              controllerTag: DashboardDrilldownBinding.receivedRecipientsTag,
            ),
          ],
        ),
      ),
    );
  }
}
