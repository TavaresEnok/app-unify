import 'package:app_provedor/diagnostico_state.dart';
import 'package:app_provedor/diagnostico_test_status.dart';
import 'package:flutter/material.dart';

import 'diagnostico_card_utils.dart';

class DeviceInfoCard extends StatelessWidget {
  final DiagnosticoState state;
  final Color cardBackgroundColor;
  final Color lightTextColor;
  final Color primaryColor;

  const DeviceInfoCard({
    Key? key,
    required this.state,
    required this.cardBackgroundColor,
    required this.lightTextColor,
    required this.primaryColor,
  }) : super(key: key);

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
    final deviceInfo = _safeCastMap(state.testResultsDisplay['deviceInfo']);
    final status = getStatus(deviceInfo);
    final resultText = getResult(deviceInfo);

    final connection = parseResultLine(resultText, "Conexão:");
    final device = parseResultLine(resultText, "Dispositivo:");
    final os = parseResultLine(resultText, "Versão OS:");
    final app = parseResultLine(resultText, "Versão do App:");

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
              label: "Informações do Dispositivo",
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDeviceInfoRow(
                            icon: Icons.wifi, title: "Conexão", value: connection),
                        const SizedBox(height: 16),
                        _buildDeviceInfoRow(
                            icon: Icons.android, title: "Versão OS", value: os),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDeviceInfoRow(
                            icon: Icons.smartphone, title: "Dispositivo", value: device),
                        const SizedBox(height: 16),
                        _buildDeviceInfoRow(
                            icon: Icons.info_outline, title: "Versão do App", value: app),
                      ],
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoRow({required IconData icon, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 18, color: lightTextColor),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: lightTextColor)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
