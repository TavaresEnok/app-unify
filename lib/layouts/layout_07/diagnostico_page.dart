// Layout 02 - Diagnóstico Page (Versão Simplificada)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage> {
  bool _isRunning = false;
  final Map<String, TestResult> _results = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    _isRunning
                        ? Icons.sync
                        : (_results.isEmpty
                            ? Icons.network_check
                            : Icons.check_circle),
                    size: 64,
                    color: _isRunning
                        ? theme.colorScheme.primary
                        : (_hasErrors ? Colors.orange : Colors.green),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRunning
                        ? 'Executando diagnóstico...'
                        : (_results.isEmpty
                            ? 'Diagnóstico de Rede'
                            : (_hasErrors
                                ? 'Diagnóstico com alertas'
                                : 'Tudo funcionando!')),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _results.isEmpty
                        ? 'Execute o diagnóstico para verificar sua conexão'
                        : '${_results.length} testes realizados',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isRunning ? null : _runDiagnostics,
                      icon: _isRunning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(
                          _isRunning ? 'Executando...' : 'Iniciar Diagnóstico'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_results.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Resultados',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._results.entries
                .map((entry) => _buildResultCard(entry.key, entry.value)),
          ],
        ],
      ),
    );
  }

  bool get _hasErrors =>
      _results.values.any((r) => r.status == TestStatus.error);

  Widget _buildResultCard(String testName, TestResult result) {
    final theme = Theme.of(context);
    final IconData icon;
    final Color color;

    switch (result.status) {
      case TestStatus.success:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case TestStatus.warning:
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case TestStatus.error:
        icon = Icons.error;
        color = Colors.red;
        break;
      case TestStatus.running:
        icon = Icons.sync;
        color = theme.colorScheme.primary;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(testName),
        subtitle: Text(result.message),
      ),
    );
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _results.clear();
    });

    // Teste 1: Tipo de conexão
    await _testConnectionType();

    // Teste 2: IP Público
    await _testPublicIp();

    // Teste 3: DNS
    await _testDns();

    // Teste 4: WiFi (se aplicável)
    await _testWifi();

    // Teste 5: Latência (ping simulado via HTTP)
    await _testLatency();

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _testConnectionType() async {
    _updateResult('Tipo de Conexão', TestStatus.running, 'Verificando...');

    try {
      final result = await Connectivity().checkConnectivity();
      String type;
      TestStatus status;

      if (result == ConnectivityResult.wifi) {
        type = 'WiFi';
        status = TestStatus.success;
      } else if (result == ConnectivityResult.mobile) {
        type = 'Dados Móveis';
        status = TestStatus.success;
      } else if (result == ConnectivityResult.ethernet) {
        type = 'Ethernet';
        status = TestStatus.success;
      } else if (result == ConnectivityResult.none) {
        type = 'Sem conexão';
        status = TestStatus.error;
      } else {
        type = 'Desconhecido';
        status = TestStatus.warning;
      }

      _updateResult('Tipo de Conexão', status, type);
    } catch (e) {
      _updateResult('Tipo de Conexão', TestStatus.error, 'Erro: $e');
    }
  }

  Future<void> _testPublicIp() async {
    _updateResult('IP Público', TestStatus.running, 'Buscando...');

    try {
      final response = await http
          .get(Uri.parse('https://ipinfo.io/json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ip = data['ip'] ?? 'N/A';
        final org = data['org'] ?? 'N/A';
        _updateResult('IP Público', TestStatus.success, '$ip\n$org');
      } else {
        _updateResult(
            'IP Público', TestStatus.error, 'Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      _updateResult('IP Público', TestStatus.error, 'Falha ao obter IP');
    }
  }

  Future<void> _testDns() async {
    _updateResult('DNS', TestStatus.running, 'Testando...');

    try {
      final stopwatch = Stopwatch()..start();
      await InternetAddress.lookup('google.com');
      stopwatch.stop();

      final ms = stopwatch.elapsedMilliseconds;
      final status = ms < 100 ? TestStatus.success : TestStatus.warning;
      _updateResult('DNS', status, 'Resolução em ${ms}ms');
    } catch (e) {
      _updateResult('DNS', TestStatus.error, 'Falha na resolução DNS');
    }
  }

  Future<void> _testWifi() async {
    _updateResult('WiFi', TestStatus.running, 'Verificando...');

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.wifi) {
        _updateResult('WiFi', TestStatus.warning, 'Não conectado ao WiFi');
        return;
      }

      final networkInfo = NetworkInfo();
      final ssid =
          (await networkInfo.getWifiName())?.replaceAll('"', '') ?? 'N/A';
      final ip = await networkInfo.getWifiIP() ?? 'N/A';
      final gateway = await networkInfo.getWifiGatewayIP() ?? 'N/A';

      _updateResult('WiFi', TestStatus.success,
          'SSID: $ssid\nIP: $ip\nGateway: $gateway');
    } catch (e) {
      _updateResult('WiFi', TestStatus.error, 'Erro ao obter info WiFi');
    }
  }

  Future<void> _testLatency() async {
    _updateResult('Latência', TestStatus.running, 'Medindo...');

    try {
      final stopwatch = Stopwatch()..start();
      await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 10));
      stopwatch.stop();

      final ms = stopwatch.elapsedMilliseconds;
      TestStatus status;
      String message;

      if (ms < 100) {
        status = TestStatus.success;
        message = '${ms}ms - Excelente';
      } else if (ms < 300) {
        status = TestStatus.success;
        message = '${ms}ms - Bom';
      } else if (ms < 500) {
        status = TestStatus.warning;
        message = '${ms}ms - Razoável';
      } else {
        status = TestStatus.warning;
        message = '${ms}ms - Lento';
      }

      _updateResult('Latência', status, message);
    } catch (e) {
      _updateResult('Latência', TestStatus.error, 'Falha ao medir latência');
    }
  }

  void _updateResult(String test, TestStatus status, String message) {
    setState(() {
      _results[test] = TestResult(status: status, message: message);
    });
  }
}

enum TestStatus { running, success, warning, error }

class TestResult {
  final TestStatus status;
  final String message;

  TestResult({required this.status, required this.message});
}
