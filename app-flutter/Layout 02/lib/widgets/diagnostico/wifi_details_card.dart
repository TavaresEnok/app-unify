import 'package:app_provedor/diagnostico_state.dart';
import 'package:app_provedor/diagnostico_test_status.dart';
import 'package:flutter/material.dart';

import 'diagnostico_card_utils.dart';

class WifiDetailsCard extends StatelessWidget {
  final DiagnosticoState state;
  final Color cardBackgroundColor;
  final Color lightTextColor;
  final Color primaryColor;

  const WifiDetailsCard({
    super.key,
    required this.state,
    required this.cardBackgroundColor,
    required this.lightTextColor,
    required this.primaryColor,
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
    final wifiInfo = _safeCastMap(state.testResultsDisplay['wifiInfo']);
    final status = getStatus(wifiInfo);
    final resultText = getResult(wifiInfo);

    final bssid = parseResultLine(resultText, "BSSID:");
    final ipLocal = parseResultLine(resultText, "IP Dispositivo:");
    final dnsServers = parseResultBlock(resultText, "Servidores DNS:");

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
              label: "Detalhes da Rede Wi-Fi",
              status: status,
              primaryColor: primaryColor,
            ),
            if (status == TestStatus.pending || status == TestStatus.running)
              buildCardStatusText(
                status: status,
                result: resultText,
                primaryColor: primaryColor,
              )
            else ...[
              const Divider(height: 24, color: Colors.white24),
              _buildInfoRow("BSSID:", bssid),
              _buildInfoRow("IP Local:", ipLocal),
              _buildInfoRow(
                  "Servidores DNS:", dnsServers.isEmpty ? "---" : "\n$dnsServers"),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: TextStyle(color: lightTextColor, fontSize: 14, height: 1.5),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
