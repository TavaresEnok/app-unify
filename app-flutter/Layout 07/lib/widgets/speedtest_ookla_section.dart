// lib/widgets/speedtest_ookla_section.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speed_test_dart/speed_test_dart.dart';
import 'package:speed_test_dart/classes/classes.dart';

class SpeedtestOoklaSection extends StatefulWidget {
  const SpeedtestOoklaSection({super.key});

  @override
  State<SpeedtestOoklaSection> createState() => _SpeedtestOoklaSectionState();
}

class _SpeedtestOoklaSectionState extends State<SpeedtestOoklaSection> {
  final tester = SpeedTestDart();

  bool _busy = false;
  String _status = 'Pronto';
  Server? _server;
  int _pingMs = 0;
  double _downloadMbps = 0.0;
  double _uploadMbps = 0.0;

  Future<List<Server>> _loadBestServers() async {
    // timeouts para evitar "travar" indefinidamente
    final settings = await tester.getSettings().timeout(const Duration(seconds: 15));
    final servers = settings.servers;
    final best = await tester.getBestServers(servers: servers).timeout(const Duration(seconds: 15));
    return best;
  }

  Future<void> _runTest() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Buscando servidores do Speedtest.net...';
      _server = null;
      _pingMs = 0;
      _downloadMbps = 0.0;
      _uploadMbps = 0.0;
    });

    try {
      final best = await _loadBestServers();
      if (!mounted) return;
      if (best.isEmpty) {
        setState(() {
          _status = 'Nenhum servidor disponível. Tente novamente.';
          _busy = false;
        });
        return;
      }

      final chosen = best.first;
      setState(() {
        _server = chosen;
        _pingMs = chosen.latency.round(); // latência do melhor servidor
        _status = 'Testando download...';
      });

      // A API retorna MB/s. Convertemos para Mbps (×8).
      final downloadMBs = await tester
          .testDownloadSpeed(servers: best)
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      setState(() {
        _downloadMbps = downloadMBs * 8.0;
        _status = 'Testando upload...';
      });

      final uploadMBs = await tester
          .testUploadSpeed(servers: best)
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      setState(() {
        _uploadMbps = uploadMBs * 8.0;
        _status = 'Concluído';
        _busy = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _status = 'Tempo esgotado. Verifique sua internet e tente novamente.';
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Erro: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // título
            Row(
              children: [
                Text('Speedtest (Ookla)', style: t.titleLarge),
                const SizedBox(width: 8),
                if (_busy) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_status, style: t.bodySmall),
            ),
            const SizedBox(height: 12),

            _Metric(label: 'Ping (ms)', value: _pingMs > 0 ? '$_pingMs' : '—'),
            _Metric(label: 'Download', value: _downloadMbps > 0 ? '${_downloadMbps.toStringAsFixed(2)} Mbps' : '—'),
            _Metric(label: 'Upload', value: _uploadMbps > 0 ? '${_uploadMbps.toStringAsFixed(2)} Mbps' : '—'),

            if (_server != null) ...[
              const SizedBox(height: 8),
              Text(
                'Servidor: ${_server!.name} • ${_server!.country} • ${_server!.sponsor}',
                textAlign: TextAlign.center,
                style: t.bodySmall,
              ),
            ],
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _runTest,
                    child: const Text('Iniciar teste'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                      setState(() {
                        _status = 'Pronto';
                        _server = null;
                        _pingMs = 0;
                        _downloadMbps = 0.0;
                        _uploadMbps = 0.0;
                      });
                    },
                    child: const Text('Limpar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: t.titleMedium),
          Text(value, style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
