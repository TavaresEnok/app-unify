import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speed_test_dart/speed_test_dart.dart';
import 'package:speed_test_dart/classes/classes.dart';
import 'package:app_provedor/shared/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class SpeedtestOoklaSection extends StatefulWidget {
  const SpeedtestOoklaSection({super.key});

  @override
  State<SpeedtestOoklaSection> createState() => _SpeedtestOoklaSectionState();
}

class _SpeedtestOoklaSectionState extends State<SpeedtestOoklaSection> {
  final tester = SpeedTestDart();

  bool _busy = false;
  String _status = 'Pronto para testar';
  Server? _server;
  int _pingMs = 0;
  double _downloadMbps = 0.0;
  double _uploadMbps = 0.0;

  Future<List<Server>> _loadBestServers() async {
    final settings = await tester.getSettings().timeout(const Duration(seconds: 15));
    final servers = settings.servers;
    final best = await tester.getBestServers(servers: servers).timeout(const Duration(seconds: 15));
    return best;
  }

  Future<void> _runTest() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Buscando servidores...';
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
          _status = 'Nenhum servidor disponível.';
          _busy = false;
        });
        return;
      }

      final chosen = best.first;
      setState(() {
        _server = chosen;
        _pingMs = chosen.latency.round();
        _status = 'Testando download...';
      });

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
        _status = 'Teste Concluído';
        _busy = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _status = 'Tempo esgotado.';
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Erro ao testar.';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))
        ],
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Speedtest (Ookla)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              if (_busy) 
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_status, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _MetricCard(label: 'Ping', value: _pingMs > 0 ? '$_pingMs' : '--', unit: 'ms', icon: Icons.timer_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(label: 'Down', value: _downloadMbps > 0 ? _downloadMbps.toStringAsFixed(0) : '--', unit: 'Mbps', icon: Icons.arrow_downward_rounded, isHighlight: true)),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(label: 'Up', value: _uploadMbps > 0 ? _uploadMbps.toStringAsFixed(0) : '--', unit: 'Mbps', icon: Icons.arrow_upward_rounded)),
            ],
          ),

          if (_server != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Servidor: ${_server!.name} • ${_server!.country}',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _runTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_busy ? 'Testando...' : 'INICIAR TESTE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final bool isHighlight;

  const _MetricCard({required this.label, required this.value, required this.unit, required this.icon, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primaryBlue.withOpacity(0.05) : AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: isHighlight ? Border.all(color: AppColors.primaryBlue.withOpacity(0.3)) : null,
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: isHighlight ? AppColors.primaryBlue : AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          Text(unit, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
// End of SpeedtestOoklaSection
