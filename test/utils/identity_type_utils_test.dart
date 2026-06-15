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

  test('supportsRegistrationNoAutocomplete includes passport primary field',
      () {
    expect(supportsRegistrationNoAutocomplete('CMND'), isTrue);
    expect(supportsRegistrationNoAutocomplete('CCCD'), isTrue);
    expect(supportsRegistrationNoAutocomplete('PASSPORT'), isTrue);
    expect(
      supportsRegistrationNoAutocomplete('PASSPORT', legacy: true),
      isTrue,
    );
  });

  test('isCompleteIdentityNumber validates document lengths', () {
    expect(isCompleteIdentityNumber('CMND', '123456789'), isTrue);
    expect(isCompleteIdentityNumber('CMND', '12345678'), isFalse);
    expect(isCompleteIdentityNumber('CCCD', '079090001234'), isTrue);
    expect(isCompleteIdentityNumber('PASSPORT', 'C1234567'), isTrue);
    expect(isCompleteIdentityNumber('PASSPORT', '123456789'), isFalse);
  });

  test('registrationNoAutocompleteIdentityType maps legacy type by digit length',
      () {
    expect(registrationNoAutocompleteIdentityType('CCCD'), 'CCCD');
    expect(registrationNoAutocompleteIdentityType('PASSPORT'), 'PASSPORT');
    expect(
      registrationNoAutocompleteIdentityType('CCCD', legacy: true),
      'CMND',
    );
    expect(
      registrationNoAutocompleteIdentityType('PASSPORT', legacy: true),
      isNull,
    );
    expect(
      registrationNoAutocompleteIdentityType(
        'PASSPORT',
        legacy: true,
        legacyIdentityNo: '123456789',
      ),
      'CMND',
    );
    expect(
      registrationNoAutocompleteIdentityType(
        'PASSPORT',
        legacy: true,
        legacyIdentityNo: '001234567890',
      ),
      'CCCD',
    );
  });

  test('inferLegacyIdentityTypeOrNull validates digit lengths', () {
    expect(inferLegacyIdentityTypeOrNull('123456789'), 'CMND');
    expect(inferLegacyIdentityTypeOrNull('001234567890'), 'CCCD');
    expect(inferLegacyIdentityTypeOrNull('12345'), isNull);
    expect(inferLegacyIdentityTypeOrNull(null), isNull);
  });
}
