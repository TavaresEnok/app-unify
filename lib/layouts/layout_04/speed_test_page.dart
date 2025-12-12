// LAYOUT 04 - AURORA - SPEED TEST PAGE

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'aurora_theme.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  bool _isRunning = false;
  bool _completed = false;
  double _progress = 0;
  double _downloadSpeed = 0;
  double _uploadSpeed = 0;
  int _ping = 0;

  void _startTest() async {
    setState(() {
      _isRunning = true;
      _completed = false;
      _progress = 0;
      _downloadSpeed = 0;
      _uploadSpeed = 0;
      _ping = 0;
    });

    // Simulate speed test
    final random = Random();

    // Ping
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _ping = 10 + random.nextInt(15);
      _progress = 0.2;
    });

    // Download
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _downloadSpeed = 80 + random.nextDouble() * 20;
        _progress = 0.2 + (i * 0.04);
      });
    }

    // Upload
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _uploadSpeed = 40 + random.nextDouble() * 15;
        _progress = 0.6 + (i * 0.04);
      });
    }

    setState(() {
      _isRunning = false;
      _completed = true;
      _progress = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          expandedHeight: 100,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Teste de Velocidade',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Main Speed Display
              AuroraCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Speed Indicator
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: _isRunning
                                  ? _progress
                                  : (_completed ? 1.0 : 0.0),
                              strokeWidth: 8,
                              backgroundColor: AuroraColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _completed
                                    ? AuroraColors.success
                                    : AuroraColors.primary,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _completed
                                    ? _downloadSpeed.toStringAsFixed(1)
                                    : (_isRunning ? '...' : '0'),
                                style: const TextStyle(
                                  color: AuroraColors.textPrimary,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Mbps',
                                style: TextStyle(
                                    color: AuroraColors.textSecondary,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Start Button
                    SizedBox(
                      width: double.infinity,
                      child: AuroraButton(
                        label: _isRunning ? 'Testando...' : 'Iniciar Teste',
                        icon: _isRunning
                            ? Icons.hourglass_top
                            : Icons.play_arrow_rounded,
                        onPressed: _isRunning ? () {} : _startTest,
                      ),
                    ),
                  ],
                ),
              ),

              if (_completed) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ResultCard(
                        label: 'Download',
                        value: '${_downloadSpeed.toStringAsFixed(1)} Mbps',
                        icon: Icons.download_rounded,
                        color: AuroraColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResultCard(
                        label: 'Upload',
                        value: '${_uploadSpeed.toStringAsFixed(1)} Mbps',
                        icon: Icons.upload_rounded,
                        color: AuroraColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResultCard(
                        label: 'Ping',
                        value: '$_ping ms',
                        icon: Icons.network_ping_rounded,
                        color: AuroraColors.success,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ResultCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AuroraCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                color: AuroraColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
