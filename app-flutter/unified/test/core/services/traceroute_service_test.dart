import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_provedor_unified/core/services/traceroute_service.dart';

void main() {
  test('shared traceroute preserves API prefix, auth and partial results', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/diagnostic/traceroute');
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(jsonDecode(request.body)['target'], 'example.com');
      return http.Response(jsonEncode({'data': {'hops': [{'hop': 1, 'ip': '*', 'time': '*'}], 'reached': false, 'timedOut': true}}), 200);
    });
    final result = await TracerouteService(client, tokenProvider: () async => 'test-token').run('https://example.test/api/get-invoices', 'example.com');
    expect(result.reached, isFalse);
    expect(result.timedOut, isTrue);
    expect(result.hops.single['ip'], '*');
    client.close();
  });
  test('missing session never sends an unauthenticated request', () async {
    final client = MockClient((_) async => throw StateError('must not request'));
    await expectLater(TracerouteService(client, tokenProvider: () async => null).run('https://example.test/api', '8.8.8.8'), throwsException);
    client.close();
  });
}
