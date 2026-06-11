import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/identity_type_utils.dart';

void main() {
  test('inferLegacyIdentityType detects CCCD from 12 digits', () {
    expect(inferLegacyIdentityType('079090001234'), 'CCCD');
    expect(inferLegacyIdentityType('079-090-001-234'), 'CCCD');
  });

  test('inferLegacyIdentityType defaults to CMND for 9 digits', () {
    expect(inferLegacyIdentityType('012977636'), 'CMND');
    expect(inferLegacyIdentityType('123456789'), 'CMND');
  });

  test('supportsRegistrationNoAutocomplete includes CMND and CCCD primary fields',
      () {
    expect(supportsRegistrationNoAutocomplete('CMND'), isTrue);
    expect(supportsRegistrationNoAutocomplete('CCCD'), isTrue);
    expect(supportsRegistrationNoAutocomplete('PASSPORT'), isFalse);
    expect(
      supportsRegistrationNoAutocomplete('PASSPORT', legacy: true),
      isTrue,
    );
  });

  test('registrationNoAutocompleteIdentityType maps legacy CMND for CCCD', () {
    expect(registrationNoAutocompleteIdentityType('CCCD'), 'CCCD');
    expect(
      registrationNoAutocompleteIdentityType('CCCD', legacy: true),
      'CMND',
    );
    expect(
      registrationNoAutocompleteIdentityType('PASSPORT', legacy: true),
      isNull,
    );
  });
}
