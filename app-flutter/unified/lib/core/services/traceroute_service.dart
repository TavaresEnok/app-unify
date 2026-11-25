import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_endpoint.dart';
import 'api_response.dart';
import 'session_token_store.dart';

class TraceResult {
  final List<Map<String, dynamic>> hops;
  final bool reached;
  final bool timedOut;
  final String resolvedTarget;
  TraceResult(Map<String, dynamic> data)
      : hops = (data['hops'] as List? ?? [])
            .map((h) => Map<String, dynamic>.from(h as Map))
            .toList(),
        reached = data['reached'] == true,
        timedOut = data['timedOut'] == true,
        resolvedTarget = data['resolvedTarget']?.toString() ?? '';
}

/// Shared by the full diagnostic and the standalone route screen.
class TracerouteService {
  final http.Client client;
  final Future<String?> Function() tokenProvider;
  TracerouteService(this.client, {Future<String?> Function()? tokenProvider})
      : tokenProvider =
            tokenProvider ?? (() => SessionTokenStore.instance.getToken());

  Future<TraceResult> run(String apiUrl, String target) async {
    final token = await tokenProvider();
    if (token == null) {
      throw Exception('Entre novamente para executar o rastreamento.');
    }
    final response = await client
        .post(
          apiEndpoint(apiUrl, 'diagnostic/traceroute'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode({'target': target, 'maxHops': 15}),
        )
        .timeout(const Duration(seconds: 35));
    final body = decodeApiResponse(response,
        fallback: 'Não foi possível rastrear a rota.');
    return TraceResult(Map<String, dynamic>.from(body['data'] as Map));
  }
}
