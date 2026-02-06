import 'package:app_provedor/diagnostico_state.dart';
import 'package:app_provedor/diagnostico_test_status.dart';
import 'package:flutter/material.dart';

import 'diagnostico_card_utils.dart';

class ConnectionJourneyCard extends StatelessWidget {
  final DiagnosticoState state;
  final Color cardBackgroundColor;

  const ConnectionJourneyCard({
    super.key,
    required this.state,
    required this.cardBackgroundColor,
  });

  // Função auxiliar para converter com segurança
  Map<String, dynamic>? _safeCastMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    // Tenta fazer a conversão de qualquer tipo de Map para Map<String, dynamic>
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        // Se houver erro na conversão (ex: chaves não são strings), retorna map vazio ou null
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Aplica a conversão segura nos dados que vêm do state
    final wifiInfo = _safeCastMap(state.testResultsDisplay['wifiInfo']);
    final wifiStatus = getStatus(wifiInfo);
    final wifiResult = getResult(wifiInfo);

    final gatewayPing = _safeCastMap(state.testResultsDisplay['pingGateway']);
    final gatewayStatus = getStatus(gatewayPing);
    final gatewayResult = getResult(gatewayPing);

    final publicIp = _safeCastMap(state.testResultsDisplay['publicIp']);
    final ipStatus = getStatus(publicIp);

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
            const Text(
              "Diagnóstico da Conexão",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildJourneyStep(
              icon: Icons.wifi,
              title: "VOCÊ (Dispositivo)",
              status: wifiStatus,
              children: [
                _buildJourneyInfo(
                    "Sinal:", parseResultLine(wifiResult, "Força do Sinal:")),
                _buildJourneyInfo("SSID:", parseResultLine(wifiResult, "SSID:")),
                _buildJourneyInfo(
                    "Frequência:", parseResultLine(wifiResult, "Frequência:")),
              ],
            ),
            _buildJourneyStep(
              icon: Icons.router,
              title: "ROTEADOR (Gateway)",
              status: gatewayStatus,
              children: [
                _buildJourneyInfo("IP:",
                    parseResultLine(wifiResult, "Gateway (Roteador):")),
                _buildJourneyInfo(
                    "Latência:", parseResultLine(gatewayResult, "Latência Média:")),
                _buildJourneyInfo(
                    "Perda:", parseResultLine(gatewayResult, "Perda:")),
              ],
            ),
            _buildJourneyStep(
              icon: Icons.cloud_outlined,
              title: "INTERNET (Rede Externa)",
              status: ipStatus,
              children: [
                _buildJourneyInfo(
                    "IP Público:", parseResultLine(getResult(publicIp), "IP Público:")),
                _buildJourneyInfo("País:",
                    parseResultLine(getResult(publicIp), "País:")),
                _buildJourneyInfo("Cidade:",
                    parseResultLine(getResult(publicIp), "Cidade:")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyStep({
    required IconData icon,
    required String title,
    required TestStatus status,
    List<Widget> children = const [],
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ícone e linha
            Column(
              children: [
                Icon(icon, color: getStatusColor(status)),
                if (children.isNotEmpty)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (status == TestStatus.running)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text("Executando...",
                          style: TextStyle(
                              fontSize: 12, color: Colors.amber, fontStyle: FontStyle.italic)),
                    ),
                  const SizedBox(height: 8),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
