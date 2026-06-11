import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/ip_input_utils.dart';

void main() {
  group('isValidIpv4', () {
    test('validates complete IPv4', () {
      expect(isValidIpv4('10.10.22.21'), isTrue);
      expect(isValidIpv4('192.168.1.10'), isTrue);
      expect(isValidIpv4('10.10.22'), isFalse);
      expect(isValidIpv4('10.10.22.256'), isFalse);
      expect(isValidIpv4(''), isFalse);
    });
  });
}
