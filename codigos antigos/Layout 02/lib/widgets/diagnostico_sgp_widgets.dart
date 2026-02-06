import 'package:flutter/material.dart';
import 'package:diagnostic_core/diagnostic_core.dart';
import 'package:app_provedor/diagnostico_state.dart';
import 'package:app_provedor/shared/widgets/dashboard_card.dart';

/// Card com dados da ONU (Sinal Óptico, Temperatura, etc)
Widget buildONUSignalCard(BuildContext context, DiagnosticoState state) {
  if (state.diagnosticResult == null) return const SizedBox.shrink();

  final sgp = state.diagnosticResult!.sgpData;

  // Determina cor do sinal
  Color signalColor = Colors.green;
  if (sgp.signalRx < -28) {
    signalColor = Colors.red;
  } else if (sgp.signalRx < -25) {
    signalColor = Colors.orange;
  }

  return DashboardCard(
    title: '📡 Dados da ONU (Fibra Óptica)',
    child: Column(
      children: [
        // Sinal Óptico
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: signalColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.fiber_manual_record, color: signalColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sinal Óptico',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RX: ${sgp.signalRx} dBm (${sgp.signalQuality})',
                    style: TextStyle(
                      color: signalColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'TX: ${sgp.signalTx} dBm',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),

        const Divider(height: 24),

        // Informações adicionais
        _buildInfoRow(context, Icons.thermostat, 'Temperatura',
            sgp.temperature != null ? '${sgp.temperature}°C' : 'N/A'),
        const SizedBox(height: 8),
        _buildInfoRow(context, Icons.bolt, 'Voltagem',
            sgp.voltage != null ? '${sgp.voltage}V' : 'N/A'),
        const SizedBox(height: 8),
        _buildInfoRow(context, Icons.router, 'Modelo', sgp.model ?? 'N/A'),
        const SizedBox(height: 8),
        _buildInfoRow(context, Icons.business, 'Localização',
            'OLT ${sgp.oltId} | Slot ${sgp.slot} | PON ${sgp.pon} | ONU ${sgp.onuId}'),

        // Status de conexão
        if (sgp.blocked || sgp.maintenance) ...[
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sgp.blocked
                        ? '🚨 BLOQUEADO POR INADIMPLÊNCIA'
                        : '⚠️ MANUTENÇÃO PROGRAMADA',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildInfoRow(
    BuildContext context, IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 20, color: Colors.grey[600]),
      const SizedBox(width: 8),
      Text(
        '$label: ',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      Expanded(
        child: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}

/// Card com análise inteligente do diagnóstico
Widget buildAnalysisCard(
    BuildContext context, DiagnosticoState state, VoidCallback onOpenTicket) {
  if (state.diagnosticResult == null) return const SizedBox.shrink();

  final result = state.diagnosticResult!;
  final primaryColor = Theme.of(context).primaryColor;

  // Determina cor baseada na confiança
  Color confidenceColor = Colors.green;
  if (result.confidence < 0.6) {
    confidenceColor = Colors.orange;
  } else if (result.confidence < 0.3) {
    confidenceColor = Colors.red;
  }

  return DashboardCard(
    title: '🤖 Análise Inteligente',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Problema detectado
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.report_problem, color: confidenceColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Problema Detectado',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.problem,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const Divider(height: 24),

        // Solução sugerida
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solução Sugerida',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.solution,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),

        const Divider(height: 24),

        // Informações adicionais
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAnalysisInfo(
                context, Icons.timer, 'Tempo', result.estimatedTime),
            _buildAnalysisInfo(context, Icons.assessment, 'Confiança',
                '${(result.confidence * 100).toInt()}%',
                color: confidenceColor),
            _buildAnalysisInfo(
                context,
                Icons.priority_high,
                'Prioridade',
                result.priority == 3
                    ? 'Alta'
                    : result.priority == 2
                        ? 'Média'
                        : 'Baixa'),
          ],
        ),

        // Botão para abrir chamado
        if (result.priority >= 2) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenTicket,
              icon: const Icon(Icons.support_agent),
              label: const Text('Abrir Chamado Técnico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildAnalysisInfo(
    BuildContext context, IconData icon, String label, String value,
    {Color? color}) {
  return Column(
    children: [
      Icon(icon, color: color ?? Colors.grey[600], size: 20),
      const SizedBox(height: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
      ),
    ],
  );
}
