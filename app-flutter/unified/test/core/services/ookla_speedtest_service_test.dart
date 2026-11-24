import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_provedor_unified/core/services/ookla_speedtest_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('extractProviderKeyword ignora palavras genéricas de provedor', () {
    expect(OoklaSpeedtestService.extractProviderKeyword('Vibe Telecom', 'vibe'),
        'vibe');
    expect(OoklaSpeedtestService.extractProviderKeyword('Conect Fibra', 'x'),
        'conect');
    expect(
        OoklaSpeedtestService.extractProviderKeyword('Telecom Internet', 'abc'),
        'abc');
  });

  test('isExplicitNonOoklaUrl diferencia URLs legadas de Ookla IDs/hosts', () {
    expect(OoklaSpeedtestService.isExplicitNonOoklaUrl(null), isFalse);
    expect(OoklaSpeedtestService.isExplicitNonOoklaUrl(''), isFalse);
    expect(OoklaSpeedtestService.isExplicitNonOoklaUrl('ookla:43431'), isFalse);
    expect(OoklaSpeedtestService.isExplicitNonOoklaUrl('43431'), isFalse);
    expect(
        OoklaSpeedtestService.isExplicitNonOoklaUrl(
            'http://speedtestvibe.ajustconsulting.com.br:8080/speedtest/upload.php'),
        isFalse);
    expect(
        OoklaSpeedtestService.isExplicitNonOoklaUrl(
            'https://appisp.com.br/speedtest/'),
        isFalse);
    expect(
        OoklaSpeedtestService.isExplicitNonOoklaUrl(
            'https://arquivos.exemplo.com/teste10mb.bin'),
        isTrue);
  });

  test('discoverAndSelect prioriza servidor local do provedor sem desviar para SP ou EUA',
      () async {
    final nearestPayload = jsonEncode([
      {
        'id': '60652',
        'sponsor': 'Conect Fibra',
        'name': 'Abreu e Lima',
        'country': 'Brazil',
        'cc': 'BR',
        'distance': 1,
        'host': 'conectteste.ajustconsulting.com.br:8080',
        'url': 'http://conectteste.ajustconsulting.com.br:8080/speedtest/upload.php',
        'https_functional': 1,
      },
      {
        'id': '99999',
        'sponsor': 'SP Backbone',
        'name': 'São Paulo',
        'country': 'Brazil',
        'cc': 'BR',
        'distance': 2200,
        'host': 'sp.exemplo.net:8080',
        'url': 'http://sp.exemplo.net:8080/speedtest/upload.php',
        'https_functional': 1,
      },
    ]);
    final searchPayload = jsonEncode([
      {
        'id': '43431',
        'sponsor': 'VIBE',
        'name': 'Paulista',
        'country': 'Brazil',
        'cc': 'BR',
        'distance': 7,
        'host': 'speedtestvibe.ajustconsulting.com.br:8080',
        'url': 'http://speedtestvibe.ajustconsulting.com.br:8080/speedtest/upload.php',
        'https_functional': 0,
      },
      {
        'id': '77777',
        'sponsor': 'Vibe Telecom USA',
        'name': 'Miami',
        'country': 'United States',
        'cc': 'US',
        'distance': 6100,
        'host': 'miami.vibe.us:8080',
        'url': 'http://miami.vibe.us:8080/speedtest/upload.php',
        'https_functional': 1,
      },
    ]);

    final client = MockClient((req) async {
      if (req.url.queryParameters['search'] == 'vibe') {
        return http.Response(searchPayload, 200);
      }
      return http.Response(nearestPayload, 200);
    });

    final latencies = <String, double>{
      'conectteste.ajustconsulting.com.br:8080': 5.0,
      'speedtestvibe.ajustconsulting.com.br:8080': 6.0,
      'sp.exemplo.net:8080': 48.0,
      'miami.vibe.us:8080': 140.0,
    };

    final service = OoklaSpeedtestService(
      probeServer: (server, _) async => server.copyWith(
        resolvedBaseUrl: 'http://${server.host}',
        latencyMs: latencies[server.host] ?? 200.0,
        jitterMs: 1.0,
      ),
    );

    final plan = await service.discoverAndSelect(
      client: client,
      providerName: 'Vibe Telecom',
      providerId: 'vibe',
    );

    expect(plan, isNotNull);
    expect(plan!.primary.id, '43431');
    expect(plan.primary.displayName, 'VIBE · Paulista');
    expect(plan.reference, isNotNull);
    expect(plan.reference!.id, '60652');
    expect(plan.probed.any((s) => s.id == '77777'), isFalse);
  });

  test('discoverAndSelect evita homônimo distante mesmo com busca explícita de marca',
      () async {
    final nearestPayload = jsonEncode([
      {
        'id': '60652',
        'sponsor': 'Conect Fibra',
        'name': 'Abreu e Lima',
        'country': 'Brazil',
        'cc': 'BR',
        'distance': 2,
        'host': 'conectteste.ajustconsulting.com.br:8080',
        'url': 'http://conectteste.ajustconsulting.com.br:8080/speedtest/upload.php',
        'https_functional': 1,
      },
    ]);
    final searchPayload = jsonEncode([
      {
        'id': '1253',
        'sponsor': 'VibeNet SP',
        'name': 'Ribeirão Preto',
        'country': 'Brazil',
        'cc': 'BR',
        'distance': 1900,
        'host': 'ribeirao.sp.net:8080',
        'url': 'http://ribeirao.sp.net:8080/speedtest/upload.php',
        'https_functional': 1,
      },
    ]);

    final client = MockClient((req) async {
      if (req.url.queryParameters['search'] != null) {
        return http.Response(searchPayload, 200);
      }
      return http.Response(nearestPayload, 200);
    });

    final service = OoklaSpeedtestService(
      probeServer: (server, _) async => server.copyWith(
        resolvedBaseUrl: 'http://${server.host}',
        latencyMs: server.id == '60652' ? 5.0 : 52.0,
        jitterMs: 1.0,
      ),
    );

    final plan = await service.discoverAndSelect(
      client: client,
      providerName: 'Vibe Telecom',
      providerId: 'vibe',
    );

    expect(plan, isNotNull);
    expect(plan!.primary.id, '60652');
  });

  test('runSpeedTest mede download e upload reais contra servidor HTTP local compatível com Ookla',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final payload = Uint8List(512 * 1024);
    var latencyHits = 0;
    var downloadHits = 0;
    var uploadBytes = 0;

    final sub = server.listen((HttpRequest req) async {
      if (req.uri.path == '/speedtest/latency.txt') {
        latencyHits++;
        req.response.write('test=test');
        await req.response.close();
        return;
      }
      if (req.uri.path == '/download') {
        downloadHits++;
        req.response.statusCode = 200;
        req.response.add(payload);
        await req.response.close();
        return;
      }
      if (req.uri.path == '/speedtest/upload.php') {
        await for (final chunk in req) {
          uploadBytes += chunk.length;
        }
        req.response.write('size=$uploadBytes');
        await req.response.close();
        return;
      }
      req.response.statusCode = 404;
      await req.response.close();
    });

    addTearDown(() async {
      await sub.cancel();
      await server.close(force: true);
    });

    final client = MockClient((_) async => http.Response('[]', 200));
    final service = OoklaSpeedtestService();
    final url = 'http://127.0.0.1:${server.port}/speedtest/upload.php';

    final plan = await service.discoverAndSelect(
      client: client,
      providerName: 'Vibe Telecom',
      providerId: 'vibe',
      configuredUrl: url,
    );

    expect(plan, isNotNull);
    expect(latencyHits, 3);

    final progressEvents = <(double, double, bool)>[];
    final measurement = await service.runSpeedTest(
      server: plan!.primary,
      phaseDuration: const Duration(milliseconds: 800),
      streams: 2,
      onProgress: (percent, mbps, isUpload) {
        progressEvents.add((percent, mbps, isUpload));
      },
    );

    expect(downloadHits, greaterThan(0));
    expect(uploadBytes, greaterThan(0));
    expect(measurement.downloadMbps, greaterThan(0));
    expect(measurement.uploadMbps, greaterThan(0));
    expect(progressEvents.any((e) => !e.$3), isTrue);
    expect(progressEvents.any((e) => e.$3), isTrue);
  });
}
