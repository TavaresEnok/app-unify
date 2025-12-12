import 'package:flutter/material.dart';
import '../../diagnostico_state.dart';
import '../../diagnostico_test_status.dart';
import 'diagnostico_card_utils.dart';

class DeviceInfoCard extends StatelessWidget {
  final DiagnosticoState state;
  final Color cardBackgroundColor;

  const DeviceInfoCard(
      {super.key, required this.state, required this.cardBackgroundColor});

  @override
  Widget build(BuildContext context) {
    final status =
        state.testResultsDisplay['deviceInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['deviceInfo']?['result'] as String?;

    return Card(
      elevation: 0,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildTileHeader(context,
              label: "Informações do Dispositivo", status: status),
          if (status == TestStatus.pending || status == TestStatus.running)
            _buildTileStatusText(context, status: status, result: resultText)
          else ...[
            const Divider(height: 24, color: Colors.white24),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _buildDeviceInfoRow(context,
                        icon: Icons.wifi,
                        title: "Conexão",
                        value: parseResultLine(resultText, "Conexão:")),
                    const SizedBox(height: 16),
                    _buildDeviceInfoRow(context,
                        icon: Icons.android_outlined,
                        title: "Sistema",
                        value: parseResultLine(resultText, "Versão OS:")),
                  ])),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _buildDeviceInfoRow(context,
                        icon: Icons.smartphone,
                        title: "Dispositivo",
                        value: parseResultLine(resultText, "Dispositivo:")),
                    const SizedBox(height: 16),
                    _buildDeviceInfoRow(context,
                        icon: Icons.info_outline,
                        title: "Versão do App",
                        value: parseResultLine(resultText, "Versão do App:")),
                  ])),
            ]),
          ]
        ]),
      ),
    );
  }
}

class BatteryInfoCard extends StatelessWidget {
  final DiagnosticoState state;
  final Color cardBackgroundColor;

  const BatteryInfoCard(
      {super.key, required this.state, required this.cardBackgroundColor});

  @override
  Widget build(BuildContext context) {
    final status =
        state.testResultsDisplay['batteryInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['batteryInfo']?['result'] as String?;

    return Card(
      elevation: 0,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildTileHeader(context, label: "Energia e Bateria", status: status),
          if (status == TestStatus.pending || status == TestStatus.running)
            _buildTileStatusText(context, status: status, result: resultText)
          else ...[
            const Divider(height: 24, color: Colors.white24),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _buildDeviceInfoRow(context,
                        icon: Icons.battery_std,
                        title: "Nível",
                        value: parseResultLine(resultText, "Nível:")),
                  ])),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _buildDeviceInfoRow(context,
                        icon: Icons.power,
                        title: "Estado",
                        value: parseResultLine(resultText, "Estado:")),
                  ])),
            ]),
            if (resultText != null && resultText.contains("⚠️"))
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.amberAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resultText.split('\n').lastWhere(
                            (l) => l.contains("⚠️"),
                            orElse: () => "Aviso de energia"),
                        style: const TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
          ]
        ]),
      ),
    );
  }
}

class LanScanCard extends StatelessWidget {
  final DiagnosticoState state;
  final Color cardBackgroundColor;

  const LanScanCard(
      {super.key, required this.state, required this.cardBackgroundColor});

  @override
  Widget build(BuildContext context) {
    final status =
        state.testResultsDisplay['lanScan']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['lanScan']?['result'] as String?;

    return Card(
      elevation: 0,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildTileHeader(context,
              label: "Dispositivos na Rede (LAN)", status: status),
          if (status == TestStatus.pending || status == TestStatus.running)
            _buildTileStatusText(context, status: status, result: resultText)
          else ...[
            const Divider(height: 24, color: Colors.white24),
            Row(children: [
              Icon(Icons.devices_other,
                  size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text("Total Encontrado",
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    Text(
                        parseResultLine(
                            resultText, "Dispositivos encontrados:"),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    if (resultText != null && resultText.contains("sub-rede"))
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          resultText
                              .split('\n')
                              .lastWhere((l) => l.contains("sub-rede"),
                                  orElse: () => "")
                              .replaceAll("(", "")
                              .replaceAll(")", ""),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ),
                  ]))
            ])
          ]
        ]),
      ),
    );
  }
}

// Helpers locais (adaptados)
Widget _buildTileHeader(BuildContext context,
    {required String label, required TestStatus status}) {
  Widget statusIconWidget;
  final color = getStatusColor(status);

  switch (status) {
    case TestStatus.running:
      statusIconWidget = SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3, color: color));
      break;
    case TestStatus.success:
      statusIconWidget = Icon(Icons.check_circle, color: color, size: 28);
      break;
    case TestStatus.error:
      statusIconWidget = Icon(Icons.error, color: color, size: 28);
      break;
    case TestStatus.pending:
      statusIconWidget = Icon(Icons.hourglass_empty, color: color, size: 24);
      break;
  }
  return Row(
    children: [
      statusIconWidget,
      const SizedBox(width: 12),
      Expanded(
        child: Text(label,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    ],
  );
}

Widget _buildTileStatusText(BuildContext context,
    {required TestStatus status, String? result}) {
  String text;
  Color color = getStatusColor(status);

  switch (status) {
    case TestStatus.running:
      text =
          result != null && result.isNotEmpty && !result.contains("Iniciando")
              ? result.split('\n').last.trim()
              : "Executando...";
      break;
    case TestStatus.error:
      text = result ?? "Ocorreu um erro desconhecido.";
      break;
    case TestStatus.pending:
      text = "Pendente";
      break;
    default:
      return const SizedBox.shrink();
  }
  return Padding(
    padding: const EdgeInsets.only(top: 16.0),
    child: Center(
      child: Text(
        text.replaceAll("Exception: ", ""),
        style: TextStyle(color: color, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Widget _buildDeviceInfoRow(BuildContext context,
    {required IconData icon, required String title, required String value}) {
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Icon(icon, size: 18, color: Colors.white54)),
    const SizedBox(width: 12),
    Flexible(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            softWrap: true),
      ]),
    ),
  ]);
}
