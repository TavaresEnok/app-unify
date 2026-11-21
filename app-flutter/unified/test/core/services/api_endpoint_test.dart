import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/services/api_endpoint.dart';
void main() {
  test('preserves proxy prefix for wifi, ONU and traceroute', () {
    for (final route in ['cpe/wifi/list','cpe/wifi/update','diagnostic/onu-signal','diagnostic/traceroute']) {
      for (final base in ['https://example.test/api','https://example.test/api/','https://example.test/api/get-invoices']) {
        expect(apiEndpoint(base,route).toString(), 'https://example.test/api/$route');
      }
      expect(apiEndpoint('http://localhost:9136',route).toString(), 'http://localhost:9136/$route');
    }
  });
  test('does not forward query parameters or embedded credentials', () {
    expect(apiEndpoint('https://example.test/api?old=1#x','diagnostic/traceroute').toString(), 'https://example.test/api/diagnostic/traceroute');
    expect(() => apiEndpoint('https://user:pass@example.test/api','x'), throwsFormatException);
  });
}
