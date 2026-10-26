import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/diagnostic_report.dart';
import '../models/diagnostico_state.dart';
import '../models/provider_config.dart';
import '../providers/providers.dart';
import '../services/diagnostic_report_service.dart';
import '../services/diagnostic_verdict.dart';
import '../services/incident_service.dart';

/// Ponto ÚNICO de entrega do relatório de diagnóstico.
///
/// As seis telas de diagnóstico (uma por layout) chamam esta função, em vez de
/// cada uma reimplementar a geração/envio. Assim qualquer melhoria no fluxo vale
/// para todos os layouts de uma vez.
Future<void> showDiagnosticReportSheet(
  BuildContext context,
  WidgetRef ref,
  DiagnosticoState state, {
  DiagnosticReportService? service,
}) async {
  final config = ref.read(configurationProvider).providerConfig;
  final user = ref.read(authNotifierProvider).value;

  if (config == null || user == null) {
    _snack(context, 'Não foi possível montar o relatório: sessão indisponível.');
    return;
  }

  final report = DiagnosticReport.fromState(
    state,
    customer: ReportCustomer.fromPlan(
      name: user.nome,
      cpfCnpj: user.cpfCnpj,
      planName: user.plano,
      contractId: user.contratoId,
    ),
    provider: ReportProvider(
      id: config.id,
      name: config.name,
      logoUrl: config.config.logoUrl.isEmpty ? null : config.config.logoUrl,
    ),
  );
  final verdict = DiagnosticVerdictEngine().evaluate(report);

  // Se o problema parece ser do provedor, checa se já existe um aviso de
  // instabilidade ativo — para avisar o cliente em vez de gerar mais um chamado
  // do mesmo problema (§ estudo 4.3). Best-effort: null não atrapalha o fluxo.
  ProviderIncident? incident;
  if (verdict.needsProviderSupport) {
    incident = await IncidentService().activeIncident(config.id);
  }

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _ReportSheet(
      report: report,
      verdict: verdict,
      config: config,
      userEmail: user.email,
      incident: incident,
      service: service ?? DiagnosticReportService(),
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  final DiagnosticReport report;
  final DiagnosticVerdict verdict;
  final ProviderConfig config;
  final String? userEmail;
  final ProviderIncident? incident;
  final DiagnosticReportService service;

  const _ReportSheet({
    required this.report,
    required this.verdict,
    required this.config,
    required this.service,
    this.userEmail,
    this.incident,
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  bool _busy = false;
  String? _cachedUrl;
  Uint8List? _logo;
  bool _logoFetched = false;
  String? _resultId;

  @override
  void initState() {
    super.initState();
    // Grava o histórico assim que o resultado é mostrado — conta o diagnóstico
    // mesmo que o cliente resolva sozinho e não acione o suporte.
    widget.service
        .persistResult(report: widget.report, verdict: widget.verdict)
        .then((id) => _resultId = id);
  }

  /// Busca o logo uma única vez por sessão da folha (best-effort).
  Future<Uint8List?> _logoBytes() async {
    if (_logoFetched) return _logo;
    _logoFetched = true;
    _logo = await fetchProviderLogo(widget.report.provider.logoUrl);
    return _logo;
  }

  bool get _hasWhatsapp =>
      DiagnosticReportService.whatsappNumber(widget.config) != null;

  /// Publica o PDF uma única vez por sessão da folha (reaproveitado entre
  /// WhatsApp/chamado) e anexa a URL ao registro já persistido.
  Future<String> _ensurePublished() async {
    final cached = _cachedUrl;
    if (cached != null) return cached;
    final url = await widget.service.publishReport(
      report: widget.report,
      verdict: widget.verdict,
      providerLogo: await _logoBytes(),
    );
    _cachedUrl = url;
    final id = _resultId;
    if (id != null) {
      await widget.service.attachReportUrl(
        providerId: widget.report.provider.id,
        resultId: id,
        reportUrl: url,
      );
    }
    return url;
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && success != null) _snack(context, success);
    } on ReportDeliveryException catch (e) {
      if (mounted) _snack(context, e.message, error: true);
    } catch (e) {
      if (mounted) {
        _snack(context, 'Não foi possível concluir a ação. Tente novamente.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() => _run(() async {
        // Histórico já foi gravado no initState; aqui apenas compartilha o PDF.
        await widget.service.sharePdf(widget.report, widget.verdict,
            providerLogo: await _logoBytes());
      });

  Future<void> _sendWhatsapp() => _run(() async {
        final url = await _ensurePublished();
        await widget.service.openWhatsappWithReport(
          config: widget.config,
          report: widget.report,
          verdict: widget.verdict,
          reportUrl: url,
        );
        if (mounted) Navigator.of(context).maybePop();
      });

  Future<void> _openTicket() => _run(
        () async {
          final url = await _ensurePublished();
          await widget.service.openSupportTicket(
            report: widget.report,
            verdict: widget.verdict,
            reportUrl: url,
            userEmail: widget.userEmail,
          );
          if (mounted) Navigator.of(context).maybePop();
        },
        success: 'Chamado aberto com o relatório anexado.',
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = widget.verdict;
    final color = _severityColor(v.severity, theme);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(_severityIcon(v.severity), color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(v.headline,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(v.summary, style: theme.textTheme.bodySmall),
            if (widget.incident != null) ...[
              const SizedBox(height: 12),
              _incidentBanner(theme, widget.incident!),
            ],
            if (v.findings.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: v.findings
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(top: 6, right: 8),
                                    decoration: BoxDecoration(
                                      color: _severityColor(f.severity, theme),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(f.title,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600)),
                                        Text(f.recommendation,
                                            style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_busy) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            ..._buildActions(theme, v),
          ],
        ),
      ),
    );
  }

  Widget _incidentBanner(ThemeData theme, ProviderIncident incident) {
    final color = Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_outlined, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Já sabemos: ${incident.title}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(
                  incident.area != null
                      ? '${incident.message}\nRegião: ${incident.area}'
                      : incident.message,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Deflexão-first (§ estudo 4.2): a ordem e o destaque das ações mudam com o
  /// veredito.
  /// - Instabilidade conhecida do provedor → não gerar mais um chamado; o cliente
  ///   já foi avisado que a equipe está atuando.
  /// - Tudo OK → sem acionar suporte; só compartilhar se quiser.
  /// - Problema do cliente (Wi-Fi/roteador) → a auto-resolução é a ação
  ///   principal; contatar o suporte fica secundário. Evita chamado à toa.
  /// - Problema do provedor (fibra/rede) → enviar ao suporte é a ação principal.
  List<Widget> _buildActions(ThemeData theme, DiagnosticVerdict v) {
    // Instabilidade já conhecida: evita enxurrada de chamados do mesmo problema.
    if (widget.incident != null && v.needsProviderSupport) {
      return [
        FilledButton.icon(
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.check),
          label: const Text('Entendi, vou aguardar'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.ios_share),
          label: const Text('Compartilhar PDF'),
        ),
      ];
    }

    if (v.severity == VerdictSeverity.ok) {
      return [
        OutlinedButton.icon(
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.ios_share),
          label: const Text('Compartilhar resultado'),
        ),
      ];
    }

    final contactButtons = <Widget>[
      _hasWhatsapp
          ? FilledButton.icon(
              onPressed: _busy ? null : _sendWhatsapp,
              icon: const Icon(Icons.support_agent),
              label: const Text('Enviar ao suporte pelo WhatsApp'),
            )
          : FilledButton.icon(
              onPressed: _busy ? null : _openTicket,
              icon: const Icon(Icons.confirmation_number_outlined),
              label: const Text('Abrir chamado com o relatório'),
            ),
    ];

    if (v.needsProviderSupport) {
      // Problema provavelmente do provedor: acionar suporte é a ação primária.
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Isto normalmente exige o provedor. Enviar o relatório agiliza o atendimento — o técnico já recebe o diagnóstico pronto.',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
        ...contactButtons,
        const SizedBox(height: 8),
        if (_hasWhatsapp)
          OutlinedButton.icon(
            onPressed: _busy ? null : _openTicket,
            icon: const Icon(Icons.confirmation_number_outlined),
            label: const Text('Abrir chamado, em vez disso'),
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.ios_share),
          label: const Text('Compartilhar PDF'),
        ),
      ];
    }

    // Problema provavelmente do cliente: priorizar a auto-resolução. As
    // recomendações já aparecem na lista acima; aqui reforçamos e deixamos o
    // suporte como saída secundária.
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.tips_and_updates_outlined,
                color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tente as sugestões acima primeiro — a maioria dos casos assim se resolve sem precisar de visita técnica.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _busy ? null : (_hasWhatsapp ? _sendWhatsapp : _openTicket),
        icon: const Icon(Icons.support_agent),
        label: const Text('Ainda assim, falar com o suporte'),
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: _busy ? null : _share,
        icon: const Icon(Icons.ios_share),
        label: const Text('Compartilhar PDF'),
      ),
    ];
  }

  Color _severityColor(VerdictSeverity s, ThemeData theme) {
    switch (s) {
      case VerdictSeverity.ok:
        return Colors.green.shade600;
      case VerdictSeverity.attention:
        return Colors.orange.shade700;
      case VerdictSeverity.critical:
        return theme.colorScheme.error;
    }
  }

  IconData _severityIcon(VerdictSeverity s) {
    switch (s) {
      case VerdictSeverity.ok:
        return Icons.check_circle_outline;
      case VerdictSeverity.attention:
        return Icons.warning_amber_rounded;
      case VerdictSeverity.critical:
        return Icons.error_outline;
    }
  }
}

void _snack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
  ));
}

/// Busca o logo do provedor para estampar o PDF. Best-effort: qualquer falha
/// (offline, URL inválida, timeout) apenas devolve null e o relatório sai com o
/// nome do provedor no lugar da imagem.
Future<Uint8List?> fetchProviderLogo(String? logoUrl) async {
  if (logoUrl == null || logoUrl.isEmpty) return null;
  final uri = Uri.tryParse(logoUrl);
  if (uri == null || !uri.isScheme('https')) return null;
  try {
    final response =
        await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;
    if (response.bodyBytes.length > 2 * 1024 * 1024) return null;
    return response.bodyBytes;
  } catch (_) {
    return null;
  }
}
