import 'package:layout01/diagnostico_state.dart';
import 'package:layout01/diagnostico_test_status.dart';
import 'package:layout01/widgets/diagnostico/diagnostico_card_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SpeedTestCard extends StatelessWidget {
  final DiagnosticoState state;
  final Color primaryColor;
  final Color cardBackgroundColor;
  final Color lightTextColor;
  final Color borderColor;

  const SpeedTestCard({
    super.key,
    required this.state,
    required this.primaryColor,
    required this.cardBackgroundColor,
    required this.lightTextColor,
    required this.borderColor,
  });

  // Função auxiliar para converter com segurança
  Map<String, dynamic>? _safeCastMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final speedTest = _safeCastMap(state.testResultsDisplay['speedTestCustom']);
    final speedStatus = getStatus(speedTest);
    final speedResult = getResult(speedTest);

    final download = parseResultLine(speedResult, "Download:");
    final upload = parseResultLine(speedResult, "Upload:");
    final ping = state.speedTestPingLatency != null
        ? "${state.speedTestPingLatency!.toStringAsFixed(1)} ms"
        : "---";

    return Card(
      elevation: 0,
      color: cardBackgroundColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCardHeader(
              label: "Teste de Velocidade",
              status: speedStatus,
              primaryColor: primaryColor,
            ),
            if (speedStatus == TestStatus.running)
              buildCardStatusText(
                status: speedStatus,
                result: null,
                primaryColor: primaryColor,
                customRunningText: "Executando teste, isso pode levar um minuto...",
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpeedMetric("Ping", ping, Icons.timer_outlined, primaryColor),
                _buildSpeedMetric("Download", download, Icons.arrow_downward_rounded, primaryColor),
                _buildSpeedMetric("Upload", upload, Icons.arrow_upward_rounded, primaryColor),
              ],
            ),
            if (state.downloadHistory.length > 1 || state.uploadHistory.length > 1) ...[
              const SizedBox(height: 20),
              Text(
                "Histórico de Velocidade (Mbps)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: lightTextColor),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: LineChart(
                  _buildSpeedChartData(),
                  duration: const Duration(milliseconds: 250),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
      ],
    );
  }

  LineChartData _buildSpeedChartData() {
    final downloadSpots = state.downloadHistory;
    final uploadSpots = state.uploadHistory;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 25,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: borderColor,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: borderColor,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 50,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              return Text('${value.toInt()}',
                  style: TextStyle(color: lightTextColor, fontSize: 10));
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: borderColor),
      ),
      minX: 0,
      maxX: (state.downloadHistory.length - 1).toDouble(),
      minY: 0,
      lineBarsData: [
        LineChartBarData(
          spots: downloadSpots,
          isCurved: true,
          color: primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: primaryColor.withOpacity(0.2),
          ),
        ),
        LineChartBarData(
          spots: uploadSpots,
          isCurved: true,
          color: Colors.cyanAccent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.cyanAccent.withOpacity(0.2),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              String speed = barSpot.y.toStringAsFixed(1);
              String label = barSpot.barIndex == 0 ? 'Download' : 'Upload';

              return LineTooltipItem(
                '$label\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: '$speed Mbps',
                    style: TextStyle(
                      color: barSpot.bar.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
