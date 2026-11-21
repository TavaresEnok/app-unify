import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/diagnostico_state.dart';

class SpeedMeasurementCard extends StatelessWidget {
  final DiagnosticoState state;
  const SpeedMeasurementCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final fast = state.testResultsDisplay['speedTestFast']?['status'] ==
        TestStatus.running;
    final download = fast ? state.fastDownloadHistory : state.downloadHistory;
    final upload = fast ? state.fastUploadHistory : state.uploadHistory;
    if (download.isEmpty && upload.isEmpty) return const SizedBox.shrink();
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  fast
                      ? 'Velocidade — referência externa'
                      : 'Velocidade — servidor do provedor',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                  'Download: ${(fast ? state.fastDownloadResultMbps : state.customDownloadResultMbps).toStringAsFixed(1)} Mbps'),
              Text(
                  'Upload: ${(fast ? state.fastUploadResultMbps : state.customUploadResultMbps).toStringAsFixed(1)} Mbps'),
              const SizedBox(height: 12),
              RepaintBoundary(
                  child: SizedBox(
                      height: 120,
                      child: LineChart(
                          LineChartData(
                            minY: 0,
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              if (download.isNotEmpty)
                                LineChartBarData(
                                    spots: download,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    dotData: const FlDotData(show: false)),
                              if (upload.isNotEmpty)
                                LineChartBarData(
                                    spots: upload,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    dotData: const FlDotData(show: false)),
                            ],
                          ),
                          duration: Duration.zero))),
            ])));
  }
}
