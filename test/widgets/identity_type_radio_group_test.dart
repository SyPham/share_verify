import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/widgets/identity_type_radio_group.dart';

void main() {
  testWidgets('IdentityTypeRadioGroup changes selection', (tester) async {
    var selected = 'CCCD';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return IdentityTypeRadioGroup(
                value: selected,
                onChanged: (v) => setState(() => selected = v),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Loại giấy tờ'), findsOneWidget);
    expect(find.byType(Radio<String>), findsNWidgets(3));

    await tester.tap(find.text('CMND'));
    await tester.pumpAndSettle();

    expect(selected, 'CMND');
  });

  testWidgets('IdentityTypeRadioGroup fits narrow width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: IdentityTypeRadioGroup(
                value: 'CCCD',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Radio<String>), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
