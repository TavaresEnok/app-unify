import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servidor Ookla Speedtest descoberto pela API pública ou configurado pelo
/// provedor no painel administrativo.
@immutable
class OoklaServer {
  final String id;
  final String sponsor;
  final String name;
  final String country;
  final String cc;
  final double distanceKm;
  final String host;
  final String url;
  final bool httpsFunctional;
  final String? resolvedBaseUrl;
  final double latencyMs;
  final double jitterMs;
  final bool isProviderMatch;

  const OoklaServer({
    required this.id,
    required this.sponsor,
    required this.name,
    required this.country,
    required this.cc,
    required this.distanceKm,
    required this.host,
    required this.url,
    required this.httpsFunctional,
    this.resolvedBaseUrl,
    this.latencyMs = double.infinity,
    this.jitterMs = 0,
    this.isProviderMatch = false,
  });

  String get displayName {
    final s = sponsor.trim();
    final n = name.trim();
    if (s.isNotEmpty && n.isNotEmpty && s.toLowerCase() != n.toLowerCase()) {
      return '$s · $n';
    }
    return s.isNotEmpty ? s : (n.isNotEmpty ? n : host);
  }

  OoklaServer copyWith({
    String? resolvedBaseUrl,
    double? latencyMs,
    double? jitterMs,
    bool? isProviderMatch,
  }) =>
      OoklaServer(
        id: id,
        sponsor: sponsor,
        name: name,
        country: country,
        cc: cc,
        distanceKm: distanceKm,
        host: host,
        url: url,
        httpsFunctional: httpsFunctional,
        resolvedBaseUrl: resolvedBaseUrl ?? this.resolvedBaseUrl,
        latencyMs: latencyMs ?? this.latencyMs,
        jitterMs: jitterMs ?? this.jitterMs,
        isProviderMatch: isProviderMatch ?? this.isProviderMatch,
      );
}

class OoklaServerPlan {
  final OoklaServer primary;
  final OoklaServer? reference;
  final List<OoklaServer> probed;

  const OoklaServerPlan({
    required this.primary,
    this.reference,
    this.probed = const [],
  });
}

class OoklaSpeedMeasurement {
  final double downloadMbps;
  final double uploadMbps;
  final double latencyMs;
  final double jitterMs;
  final OoklaServer server;

  const OoklaSpeedMeasurement({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.latencyMs,
    required this.jitterMs,
    required this.server,
  });
}

class OoklaCancelToken {
  bool _cancelled = false;
  final List<void Function()> _disposers = [];

  bool get isCancelled => _cancelled;

  void addDisposer(void Function() disposer) {
    if (_cancelled) {
      disposer();
      return;
    }
    _disposers.add(disposer);
  }

  void removeDisposer(void Function() disposer) {
    _disposers.remove(disposer);
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final copy = List<void Function()>.from(_disposers);
    _disposers.clear();
    for (final fn in copy) {
      try {
        fn();
      } catch (_) {}
    }
  }
}

typedef OoklaProbeCallback = Future<OoklaServer?> Function(
  OoklaServer server,
  OoklaCancelToken? cancelToken,
);

/// Motor Speedtest baseado na rede Ookla: prioriza o servidor Ookla do próprio
/// provedor (quando local e com boa latência) ou seleciona o servidor regional
/// de menor latência real, evitando desvios para SP ou exterior.
class OoklaSpeedtestService {
  OoklaSpeedtestService({
    OoklaProbeCallback? probeServer,
    HttpClient Function()? httpClientFactory,
  })  : _customProbe = probeServer,
        _httpClientFactory = httpClientFactory ?? _defaultHttpClient;

  final OoklaProbeCallback? _customProbe;
  final HttpClient Function() _httpClientFactory;

  static HttpClient _defaultHttpClient() {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    client.idleTimeout = const Duration(seconds: 5);
    return client;
  }

  static const _genericWords = {
    'telecom',
    'telecomunicacoes',
    'internet',
    'fibra',
    'fiber',
    'net',
    'network',
    'provedor',
    'provedores',
    'servicos',
    'tecnologia',
    'conectividade',
    'comunicacao',
    'digital',
    'banda',
    'larga',
    'ltda',
    'eireli',
    'mei',
    'epp',
    'sa',
    'de',
    'da',
    'do',
    'das',
    'dos',
    'e',
  };

  static String _normalize(String input) {
    const map = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };
    final lower = input.toLowerCase();
    final out = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      out.write(map[ch] ?? ch);
    }
    return out.toString();
  }

  /// Extrai a palavra-chave distintiva do provedor (ex.: "Vibe Telecom" -> "vibe")
  /// para localizar seu servidor Ookla sem depender de URL hardcoded.
  static String? extractProviderKeyword(
      String providerName, String? providerId) {
    final tokens = _normalize(providerName)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length >= 3 && !_genericWords.contains(w))
        .toList();
    if (tokens.isNotEmpty) {
      tokens.sort((a, b) => b.length.compareTo(a.length));
      return tokens.first;
    }
    final idToken =
        _normalize(providerId ?? '').replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (idToken.length >= 3 && !_genericWords.contains(idToken)) {
      return idToken;
    }
    return null;
  }

  /// Retorna `true` apenas quando há uma URL explícita configurada pelo provedor
  /// que NÃO aponta para um servidor Ookla (ex.: servidor legado customizado).
  static bool isExplicitNonOoklaUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('ookla:') || RegExp(r'^\d+$').hasMatch(lower)) {
      return false;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty) {
      return false;
    }
    if (uri.port == 8080 ||
        lower.contains('/speedtest') ||
        uri.host.toLowerCase().contains('ooklaserver')) {
      return false;
    }
    return true;
  }

  static String? _explicitOoklaId(String? rawUrl) {
    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase().startsWith('ookla:')) {
      final id = trimmed.substring(6).trim();
      return RegExp(r'^\d+$').hasMatch(id) ? id : null;
    }
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return trimmed;
    return null;
  }

  static OoklaServer? _explicitOoklaServer(
      String? rawUrl, String providerName) {
    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty || _explicitOoklaId(trimmed) != null) return null;
    if (isExplicitNonOoklaUrl(trimmed)) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return null;
    final port = uri.hasPort ? uri.port : (uri.isScheme('https') ? 443 : 8080);
    final hostPort = (uri.hasPort && port != 80 && port != 443)
        ? '${uri.host}:$port'
        : (uri.hasPort ? '${uri.host}:${uri.port}' : '${uri.host}:8080');
    final base = '${uri.scheme}://$hostPort';
    return OoklaServer(
      id: 'custom',
      sponsor: providerName.trim().isEmpty ? uri.host : providerName.trim(),
      name: '',
      country: '',
      cc: '',
      distanceKm: 0,
      host: hostPort,
      url: '$base/speedtest/upload.php',
      httpsFunctional: uri.isScheme('https'),
      isProviderMatch: true,
    );
  }

  static List<OoklaServer> parseServersPayload(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List) return const [];
      final out = <OoklaServer>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final rawHost = '${item['host'] ?? ''}'.trim();
        final rawUrl = '${item['url'] ?? ''}'.trim();
        final parsedUrl = Uri.tryParse(rawUrl);
        final host = rawHost.isNotEmpty
            ? rawHost
            : (parsedUrl != null && parsedUrl.host.isNotEmpty
                ? (parsedUrl.hasPort
                    ? '${parsedUrl.host}:${parsedUrl.port}'
                    : parsedUrl.host)
                : '');
        if (host.isEmpty) continue;
        final dist = item['distance'] is num
            ? (item['distance'] as num).toDouble()
            : double.tryParse('${item['distance'] ?? ''}') ?? 9999.0;
        final httpsFlag = item['https_functional'];
        final httpsFunctional = httpsFlag == 1 || httpsFlag == true;
        out.add(OoklaServer(
          id: '${item['id'] ?? host}',
          sponsor: '${item['sponsor'] ?? ''}'.trim(),
          name: '${item['name'] ?? ''}'.trim(),
          country: '${item['country'] ?? ''}'.trim(),
          cc: '${item['cc'] ?? ''}'.trim().toUpperCase(),
          distanceKm: dist,
          host: host,
          url: rawUrl,
          httpsFunctional: httpsFunctional,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Descobre os servidores Ookla próximos ao assinante e do próprio provedor,
  /// testa a latência HTTP real e escolhe o melhor servidor principal e uma
  /// referência local independente.
  Future<OoklaServerPlan?> discoverAndSelect({
    required http.Client client,
    required String providerName,
    String? providerId,
    String? configuredUrl,
    OoklaCancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled == true) return null;

    final explicitId = _explicitOoklaId(configuredUrl);
    final explicitServer = _explicitOoklaServer(configuredUrl, providerName);
    final keyword = extractProviderKeyword(providerName, providerId);

    Future<List<OoklaServer>> fetchList(Uri uri) async {
      try {
        final res = await client.get(uri, headers: {
          'Accept': 'application/json',
        }).timeout(const Duration(seconds: 5));
        if (res.statusCode != 200) return const [];
        return parseServersPayload(res.body);
      } catch (_) {
        return const [];
      }
    }

    final nearestFuture = fetchList(Uri.parse(
        'https://www.speedtest.net/api/js/servers?engine=js&limit=12'));
    final searchQuery = explicitId ?? keyword;
    final searchFuture = searchQuery == null
        ? Future<List<OoklaServer>>.value(const [])
        : fetchList(Uri.https('www.speedtest.net', '/api/js/servers', {
            'engine': 'js',
            'search': searchQuery,
            'limit': '8',
          }));

    final results = await Future.wait([nearestFuture, searchFuture]);
    if (cancelToken?.isCancelled == true) return null;

    final nearest = results[0];
    final searched = results[1];
    if (nearest.isEmpty && searched.isEmpty && explicitServer == null) {
      return null;
    }

    String? referenceCc;
    for (final s in nearest) {
      if (s.cc.isNotEmpty) {
        referenceCc = s.cc;
        break;
      }
    }

    final byHost = <String, OoklaServer>{};

    void mergeCandidate(OoklaServer server, {required bool fromSearch}) {
      final key = server.host.toLowerCase();
      var match = server.isProviderMatch;
      if (!match) {
        if (explicitId != null && server.id == explicitId) {
          match = true;
        } else if (explicitServer != null &&
            key == explicitServer.host.toLowerCase()) {
          match = true;
        } else if (keyword != null) {
          final textMatch = _normalize(server.sponsor).contains(keyword) ||
              _normalize(server.host).contains(keyword);
          // Proteção contra homônimos em outros estados/países (ex.: SP / EUA):
          // só considera servidor do provedor se for regional ou se veio de
          // explicitId.
          final isLocal = server.distanceKm <= 250 ||
              (referenceCc != null &&
                  server.cc == referenceCc &&
                  server.distanceKm <= 400);
          if (textMatch &&
              (isLocal || (!fromSearch && server.distanceKm <= 300))) {
            match = true;
          }
        }
      }
      // Servidores da busca por marca que não passaram no filtro local/marca
      // não devem poluir a lista regional (evita testar Miami/SP distantes).
      if (fromSearch && !match) return;
      final existing = byHost[key];
      if (existing == null) {
        byHost[key] = server.copyWith(isProviderMatch: match);
      } else if (match && !existing.isProviderMatch) {
        byHost[key] = existing.copyWith(isProviderMatch: true);
      }
    }

    if (explicitServer != null) mergeCandidate(explicitServer, fromSearch: true);
    for (final s in nearest) {
      mergeCandidate(s, fromSearch: false);
    }
    for (final s in searched) {
      mergeCandidate(s, fromSearch: true);
    }

    final allCandidates = byHost.values.toList();
    final providerCandidates = allCandidates
        .where((s) => s.isProviderMatch)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final nearbyCandidates = allCandidates
        .where((s) => !s.isProviderMatch)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final probeQueue = <OoklaServer>[
      ...providerCandidates.take(3),
      ...nearbyCandidates.take(7 - providerCandidates.take(3).length),
    ];
    if (probeQueue.isEmpty) return null;

    final probedList = await Future.wait(
      probeQueue.map((s) => _probe(s, cancelToken)),
    );
    if (cancelToken?.isCancelled == true) return null;

    final reachable = probedList
        .whereType<OoklaServer>()
        .where((s) => s.latencyMs.isFinite)
        .toList()
      ..sort((a, b) {
        final cmp = a.latencyMs.compareTo(b.latencyMs);
        return cmp != 0 ? cmp : a.distanceKm.compareTo(b.distanceKm);
      });

    if (reachable.isEmpty) return null;

    final bestLocalLatency = reachable.first.latencyMs;
    OoklaServer primary = reachable.first;
    for (final s in reachable) {
      if (s.isProviderMatch &&
          s.latencyMs <= 120 &&
          s.latencyMs <= bestLocalLatency + 40) {
        primary = s;
        break;
      }
    }

    OoklaServer? reference;
    for (final s in reachable) {
      if (s.host.toLowerCase() != primary.host.toLowerCase() &&
          s.sponsor.toLowerCase() != primary.sponsor.toLowerCase()) {
        reference = s;
        break;
      }
    }

    return OoklaServerPlan(
      primary: primary,
      reference: reference,
      probed: reachable,
    );
  }

  Future<OoklaServer?> _probe(
      OoklaServer server, OoklaCancelToken? cancelToken) {
    final custom = _customProbe;
    if (custom != null) return custom(server, cancelToken);
    return _defaultProbe(server, cancelToken);
  }

  Future<OoklaServer?> _defaultProbe(
      OoklaServer server, OoklaCancelToken? cancelToken) async {
    if (cancelToken?.isCancelled == true) return null;
    final candidates = <String>[
      if (server.resolvedBaseUrl != null)
        server.resolvedBaseUrl!
      else if (server.url.startsWith('https://')) ...[
        'https://${server.host}',
        'http://${server.host}',
      ] else if (server.httpsFunctional) ...[
        'https://${server.host}',
        'http://${server.host}',
      ] else ...[
        'http://${server.host}',
        'https://${server.host}',
      ]
    ];

    final ioClient = _httpClientFactory();
    void closeClient() => ioClient.close(force: true);
    cancelToken?.addDisposer(closeClient);

    try {
      for (final base in candidates) {
        if (cancelToken?.isCancelled == true) return null;
        final samples = <double>[];
        var failed = false;
        for (var i = 0; i < 3; i++) {
          if (cancelToken?.isCancelled == true) return null;
          final uri = Uri.parse(
              '$base/speedtest/latency.txt?r=${DateTime.now().microsecondsSinceEpoch}_$i');
          final sw = Stopwatch()..start();
          try {
            final req =
                await ioClient.getUrl(uri).timeout(const Duration(seconds: 2));
            final resp = await req.close().timeout(const Duration(seconds: 2));
            await resp.drain<void>();
            sw.stop();
            if (resp.statusCode != 200) {
              failed = true;
              break;
            }
            samples.add(sw.elapsedMicroseconds / 1000.0);
          } catch (_) {
            failed = true;
            break;
          }
        }
        if (!failed && samples.isNotEmpty) {
          final steady = samples.length > 1 ? samples.sublist(1) : samples;
          final latency = steady.reduce(min);
          double jitter = 0;
          if (samples.length > 1) {
            double diffSum = 0;
            for (var i = 1; i < samples.length; i++) {
              diffSum += (samples[i] - samples[i - 1]).abs();
            }
            jitter = diffSum / (samples.length - 1);
          }
          return server.copyWith(
            resolvedBaseUrl: base,
            latencyMs: latency,
            jitterMs: jitter,
          );
        }
      }
      return null;
    } finally {
      cancelToken?.removeDisposer(closeClient);
      closeClient();
    }
  }

  /// Executa download e upload multi-stream diretamente no servidor Ookla
  /// escolhido, com descarte do ramp-up inicial de TCP e suporte a cancelamento
  /// imediato.
  Future<OoklaSpeedMeasurement> runSpeedTest({
    required OoklaServer server,
    void Function(double percent, double mbps, bool isUpload)? onProgress,
    OoklaCancelToken? cancelToken,
    Duration phaseDuration = const Duration(seconds: 7),
    int streams = 4,
  }) async {
    final base = (server.resolvedBaseUrl ?? 'http://${server.host}')
        .replaceAll(RegExp(r'/+$'), '');
    final ioClient = _httpClientFactory();
    ioClient.maxConnectionsPerHost = streams + 2;
    void closeClient() => ioClient.close(force: true);
    cancelToken?.addDisposer(closeClient);

    try {
      final downloadMbps = await _measureDownload(
        ioClient: ioClient,
        base: base,
        duration: phaseDuration,
        streams: streams,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      if (cancelToken?.isCancelled == true) {
        throw StateError('Teste interrompido.');
      }
      final uploadMbps = await _measureUpload(
        ioClient: ioClient,
        base: base,
        duration: phaseDuration,
        streams: streams,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      return OoklaSpeedMeasurement(
        downloadMbps: downloadMbps,
        uploadMbps: uploadMbps,
        latencyMs: server.latencyMs.isFinite ? server.latencyMs : 0,
        jitterMs: server.jitterMs,
        server: server,
      );
    } finally {
      cancelToken?.removeDisposer(closeClient);
      closeClient();
    }
  }

  Future<double> _measureDownload({
    required HttpClient ioClient,
    required String base,
    required Duration duration,
    required int streams,
    void Function(double percent, double mbps, bool isUpload)? onProgress,
    OoklaCancelToken? cancelToken,
  }) async {
    final sw = Stopwatch()..start();
    final totalMs = duration.inMilliseconds;
    final warmupMs = min(1000, totalMs ~/ 4);
    var totalBytes = 0;
    var steadyBytes = 0;
    var warmupEnded = false;
    var useLegacyPath = false;
    var active = true;

    Timer? sampler;
    double currentMbps() {
      final elapsedMs = sw.elapsedMilliseconds;
      if (elapsedMs <= 0) return 0;
      if (warmupEnded && elapsedMs > warmupMs) {
        final steadySec = (elapsedMs - warmupMs) / 1000.0;
        if (steadySec > 0 && steadyBytes > 0) {
          return (steadyBytes * 8.0) / steadySec / 1000000.0;
        }
      }
      return (totalBytes * 8.0) / (elapsedMs / 1000.0) / 1000000.0;
    }

    sampler = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!active || cancelToken?.isCancelled == true) return;
      final elapsedMs = sw.elapsedMilliseconds;
      if (!warmupEnded && elapsedMs >= warmupMs) {
        warmupEnded = true;
        steadyBytes = 0;
      }
      final percent = ((elapsedMs / totalMs) * 100).clamp(0.0, 99.0);
      onProgress?.call(percent, currentMbps(), false);
    });

    Future<void> worker(int workerId) async {
      var seq = 0;
      while (active &&
          sw.elapsedMilliseconds < totalMs &&
          cancelToken?.isCancelled != true) {
        final nonce =
            '${DateTime.now().microsecondsSinceEpoch}_${workerId}_${seq++}';
        final uri = useLegacyPath
            ? Uri.parse('$base/speedtest/random3500x3500.jpg?r=$nonce')
            : Uri.parse('$base/download?size=15000000&nocache=$nonce');
        try {
          final req =
              await ioClient.getUrl(uri).timeout(const Duration(seconds: 5));
          final resp = await req.close().timeout(const Duration(seconds: 5));
          if (resp.statusCode == 404 && !useLegacyPath) {
            useLegacyPath = true;
            await resp.drain<void>();
            continue;
          }
          if (resp.statusCode != 200) {
            await resp.drain<void>();
            break;
          }
          await for (final chunk in resp) {
            if (!active ||
                sw.elapsedMilliseconds >= totalMs ||
                cancelToken?.isCancelled == true) {
              break;
            }
            totalBytes += chunk.length;
            if (!warmupEnded && sw.elapsedMilliseconds >= warmupMs) {
              warmupEnded = true;
              steadyBytes = 0;
            } else if (warmupEnded) {
              steadyBytes += chunk.length;
            }
          }
        } catch (_) {
          if (!active || cancelToken?.isCancelled == true) break;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    }

    try {
      await Future.wait([
        for (var i = 0; i < streams; i++) worker(i),
      ]);
    } finally {
      active = false;
      sampler.cancel();
      sw.stop();
    }

    final finalMbps = currentMbps();
    if (cancelToken?.isCancelled != true) {
      onProgress?.call(100.0, finalMbps, false);
    }
    return finalMbps;
  }

  Future<double> _measureUpload({
    required HttpClient ioClient,
    required String base,
    required Duration duration,
    required int streams,
    void Function(double percent, double mbps, bool isUpload)? onProgress,
    OoklaCancelToken? cancelToken,
  }) async {
    final sw = Stopwatch()..start();
    final totalMs = duration.inMilliseconds;
    final warmupMs = min(1000, totalMs ~/ 4);
    var totalBytes = 0;
    var steadyBytes = 0;
    var warmupEnded = false;
    var active = true;

    // Bloco reutilizável de 256 KB não-compressível (dados aleatórios).
    const chunkSize = 256 * 1024;
    final rng = Random();
    final prefix = utf8.encode('content1=');
    final payload = Uint8List(chunkSize);
    payload.setRange(0, prefix.length, prefix);
    for (var i = prefix.length; i < chunkSize; i++) {
      payload[i] = 65 + rng.nextInt(26);
    }

    Timer? sampler;
    double currentMbps() {
      final elapsedMs = sw.elapsedMilliseconds;
      if (elapsedMs <= 0) return 0;
      if (warmupEnded && elapsedMs > warmupMs) {
        final steadySec = (elapsedMs - warmupMs) / 1000.0;
        if (steadySec > 0 && steadyBytes > 0) {
          return (steadyBytes * 8.0) / steadySec / 1000000.0;
        }
      }
      return (totalBytes * 8.0) / (elapsedMs / 1000.0) / 1000000.0;
    }

    sampler = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!active || cancelToken?.isCancelled == true) return;
      final elapsedMs = sw.elapsedMilliseconds;
      if (!warmupEnded && elapsedMs >= warmupMs) {
        warmupEnded = true;
        steadyBytes = 0;
      }
      final percent = ((elapsedMs / totalMs) * 100).clamp(0.0, 99.0);
      onProgress?.call(percent, currentMbps(), true);
    });

    Future<void> worker(int workerId) async {
      var seq = 0;
      const chunksPerPost = 8; // 2 MB por requisição POST
      while (active &&
          sw.elapsedMilliseconds < totalMs &&
          cancelToken?.isCancelled != true) {
        final uri = Uri.parse(
            '$base/speedtest/upload.php?r=${DateTime.now().microsecondsSinceEpoch}_${workerId}_${seq++}');
        try {
          final req =
              await ioClient.postUrl(uri).timeout(const Duration(seconds: 5));
          req.headers.set(HttpHeaders.contentTypeHeader,
              'application/x-www-form-urlencoded');
          req.contentLength = chunkSize * chunksPerPost;
          for (var c = 0; c < chunksPerPost; c++) {
            if (!active ||
                sw.elapsedMilliseconds >= totalMs ||
                cancelToken?.isCancelled == true) {
              req.abort();
              return;
            }
            req.add(payload);
            await req.flush();
            totalBytes += chunkSize;
            if (!warmupEnded && sw.elapsedMilliseconds >= warmupMs) {
              warmupEnded = true;
              steadyBytes = 0;
            } else if (warmupEnded) {
              steadyBytes += chunkSize;
            }
          }
          final resp = await req.close().timeout(const Duration(seconds: 5));
          await resp.drain<void>();
        } catch (_) {
          if (!active || cancelToken?.isCancelled == true) break;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    }

    try {
      await Future.wait([
        for (var i = 0; i < streams; i++) worker(i),
      ]);
    } finally {
      active = false;
      sampler.cancel();
      sw.stop();
    }

    final finalMbps = currentMbps();
    if (cancelToken?.isCancelled != true) {
      onProgress?.call(100.0, finalMbps, true);
    }
    return finalMbps;
  }
}
