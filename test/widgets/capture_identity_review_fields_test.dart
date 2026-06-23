import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/data/dto/name_autocomplete_dtos.dart';
import 'package:share_verify/core/data/dto/registration_no_autocomplete_dtos.dart';
import 'package:share_verify/core/screens/capture/components/capture_identity_review_fields.dart';
import 'package:share_verify/core/widgets/name_autocomplete_field.dart';
import 'package:share_verify/core/widgets/registration_no_autocomplete_field.dart';

Future<NameAutocompletePageDto> _mockNameSearch(String query, int page) async {
  return const NameAutocompletePageDto(
    items: [
      NameAutocompleteItemDto(
        name: 'NGUYỄN VĂN A',
        type: 'full_name',
      ),
    ],
    total: 1,
    page: 1,
    pageSize: 20,
    totalPages: 1,
  );
}

Future<RegistrationNoAutocompletePageDto> _mockRegistrationSearch(
  String query,
  int page,
) async {
  return const RegistrationNoAutocompletePageDto(
    items: [
      RegistrationNoAutocompleteItemDto(
        registrationNo: '123456789',
        identityType: 'CMND',
        mcd: 'SH0001',
        fullName: 'NGUYỄN VĂN A',
      ),
    ],
    totalCount: 1,
    page: 1,
    pageSize: 20,
  );
}

void main() {
  testWidgets('CMND review shows autocomplete fields and allows manual edit',
      (tester) async {
    final nameController = TextEditingController(text: 'NGUYEN VAN A');
    final identityController = TextEditingController(text: '123456789');
    addTearDown(nameController.dispose);
    addTearDown(identityController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaptureIdentityReviewFields(
            nameController: nameController,
            identityNoController: identityController,
            identityType: 'CMND',
            onNameSearch: _mockNameSearch,
            onIdentityNoSearch: _mockRegistrationSearch,
          ),
        ),
      ),
    );

    expect(find.byType(NameAutocompleteField), findsOneWidget);
    expect(find.byType(RegistrationNoAutocompleteField), findsOneWidget);
    expect(find.text('Số CMND'), findsOneWidget);
    expect(find.textContaining('số CMND'), findsOneWidget);

    await tester.enterText(find.byType(NameAutocompleteField), 'TRẦN THỊ B');
    expect(nameController.text, 'TRẦN THỊ B');

    await tester.enterText(
      find.byType(RegistrationNoAutocompleteField),
      '987654321',
    );
    expect(identityController.text, '987654321');
  });

  testWidgets('CCCD review shows CCCD and legacy CMND autocomplete fields',
      (tester) async {
    final nameController = TextEditingController();
    final identityController = TextEditingController(text: '001234567890');
    final cmndController = TextEditingController();
    addTearDown(nameController.dispose);
    addTearDown(identityController.dispose);
    addTearDown(cmndController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaptureIdentityReviewFields(
            nameController: nameController,
            identityNoController: identityController,
            cmndNoController: cmndController,
            identityType: 'CCCD',
            onNameSearch: _mockNameSearch,
            onIdentityNoSearch: _mockRegistrationSearch,
            onLegacyIdentityNoSearch: _mockRegistrationSearch,
          ),
        ),
      ),
    );

    expect(find.byType(RegistrationNoAutocompleteField), findsNWidgets(2));
    expect(find.text('Số CCCD'), findsOneWidget);
    expect(find.text('Số CMND'), findsOneWidget);
    expect(find.textContaining('số CCCD'), findsOneWidget);

    await tester.enterText(
      find.byType(RegistrationNoAutocompleteField).first,
      '001122334455',
    );
    expect(identityController.text, '001122334455');

    await tester.enterText(
      find.byType(RegistrationNoAutocompleteField).last,
      '123456789',
    );
    expect(cmndController.text, '123456789');
  });

}
