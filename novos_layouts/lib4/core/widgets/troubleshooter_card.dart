import 'package:flutter/material.dart';
import '../models/diagnostico_state.dart';
import 'dashboard_card.dart';

class TroubleshootingRecommendation {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? action;
  final String? actionLabel;

  TroubleshootingRecommendation({
    required this.title,
    required this.description,
    required this.icon,
    this.color = Colors.orangeAccent,
    this.action,
    this.actionLabel,
  });
}

class TroubleshooterCard extends StatelessWidget {
  final DiagnosticoState state;
  final VoidCallback? onRetry;
  final bool isDarkLayout;

  const TroubleshooterCard({
    super.key,
    required this.state,
    this.onRetry,
    this.isDarkLayout = false,
  });

  List<TroubleshootingRecommendation> _analyzeProblems(BuildContext context) {
    final List<TroubleshootingRecommendation> problems = [];

    String? wifiResult =
        state.testResultsDisplay['wifiInfo']?['result'] as String?;
    String? pingResult =
        state.testResultsDisplay['pingGateway']?['result'] as String?;
    String? batteryResult =
        state.testResultsDisplay['batteryInfo']?['result'] as String?;
    String? lanResult =
        state.testResultsDisplay['lanScan']?['result'] as String?;

    // 1. Análise de Sinal Wi-Fi
    if (wifiResult != null) {
      if (wifiResult.contains("Muito Fraca") || wifiResult.contains("Fraca")) {
        problems.add(TroubleshootingRecommendation(
          title: "Sinal Wi-Fi Fraco",
          description:
              "Você está longe do roteador ou há obstáculos (paredes/espelhos). Aproxime-se para melhorar a velocidade.",
          icon: Icons.wifi_off,
          color: Colors.redAccent,
        ));
      }
      if (wifiResult.contains("2.4 GHz")) {
        problems.add(TroubleshootingRecommendation(
          title: "Rede 2.4GHz Detectada",
          description:
              "Esta frequência é mais lenta e sofre interferência. Se possível, conecte-se à rede 5GHz do seu roteador.",
          icon: Icons.network_check,
          color: Colors.orangeAccent,
        ));
      }
    }

    // 2. Análise de Bateria
    if (batteryResult != null &&
        (batteryResult.contains("⚠️") ||
            batteryResult.contains("Nível: 1") ||
            batteryResult.contains("Nível: 0"))) {
      problems.add(TroubleshootingRecommendation(
        title: "Economia de Energia",
        description:
            "Bateria baixa reduz a potência da antena Wi-Fi do celular. Conecte ao carregador.",
        icon: Icons.battery_alert,
        color: Colors.orange,
      ));
    }

    // 3. Análise de Jitter/Latência
    if (pingResult != null) {
      try {
        final jitterLine = pingResult
            .split('\n')
            .firstWhere((l) => l.contains('Jitter'), orElse: () => '');
        if (jitterLine.isNotEmpty) {
          final jitterVal =
              double.tryParse(jitterLine.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                  0;
          if (jitterVal > 30) {
            problems.add(TroubleshootingRecommendation(
              title: "Instabilidade (Jitter)",
              description:
                  "Sua conexão está oscilando. Reinicie o roteador (tire da tomada por 10s).",
              icon: Icons.waves,
              color: Colors.redAccent,
            ));
          }
        }
      } catch (_) {}
    }

    // 4. Análise de DNS Lento
    if (wifiResult != null && wifiResult.contains("Tempo DNS")) {
      try {
        final dnsLine = wifiResult
            .split('\n')
            .firstWhere((l) => l.contains('Tempo DNS'), orElse: () => '');
        final dnsVal =
            int.tryParse(dnsLine.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (dnsVal > 150) {
          problems.add(TroubleshootingRecommendation(
            title: "Navegação Lenta (DNS)",
            description:
                "Demora para encontrar sites. Reinicie o roteador para limpar o cache.",
            icon: Icons.dns,
            color: Colors.orangeAccent,
          ));
        }
      } catch (_) {}
    }

    // 5. Dispositivos na Rede
    if (lanResult != null) {
      try {
        final devLine = lanResult
            .split('\n')
            .firstWhere((l) => l.contains('Dispositivos'), orElse: () => '');
        final devCount =
            int.tryParse(devLine.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (devCount > 12) {
          problems.add(TroubleshootingRecommendation(
            title: "Rede Congestionada?",
            description:
                "Detectamos $devCount dispositivos. Muitos aparelhos simultâneos podem dividir a velocidade.",
            icon: Icons.devices,
            color: Colors.blueGrey,
          ));
        }
      } catch (_) {}
    }

    return problems;
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinished = !state.isTesting &&
        (state.testResultsDisplay.values.any((r) =>
            r['status'] == TestStatus.success ||
            r['status'] == TestStatus.error));

    if (!isFinished) return const SizedBox.shrink();

    final recommendations = _analyzeProblems(context);

    final cardColor = isDarkLayout ? const Color(0xFF1C1C1E) : Colors.white;
    final descriptionColor = isDarkLayout ? const Color(0xFF8E8E93) : null;

    if (recommendations.isEmpty) {
      return DashboardCard(
        color: cardColor,
        child: Row(
          children: [
            const Icon(Icons.thumb_up_alt, color: Colors.greenAccent, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sua conexão está ótima!",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.greenAccent)),
                  const SizedBox(height: 4),
                  Text("Nenhum problema detectado nos testes.",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: descriptionColor)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return DashboardCard(
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_circle, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Text("Sugestões de Melhoria",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.amber)),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations
              .map((rec) => _buildRecommendationItem(context, rec)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (onRetry != null) onRetry!();
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: isDarkLayout
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  side: isDarkLayout
                      ? const BorderSide(color: Colors.white54)
                      : null),
              child: const Text("Refazer Testes"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
      BuildContext context, TroubleshootingRecommendation rec) {
    final textColor = isDarkLayout ? Colors.white : null;
    final descriptionColor = isDarkLayout ? const Color(0xFF8E8E93) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: rec.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(rec.icon, color: rec.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor)),
                const SizedBox(height: 4),
                Text(rec.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: descriptionColor)),
                if (rec.action != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: InkWell(
                      onTap: rec.action,
                      child: Text(
                        rec.actionLabel ?? "Resolver",
                        style: TextStyle(
                            color: rec.color,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
