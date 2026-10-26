import '../models/diagnostic_report.dart';

enum VerdictSeverity { ok, attention, critical }

/// Onde o problema provavelmente está — orienta tanto o texto ao cliente
/// quanto o encaminhamento do atendimento.
enum VerdictArea { fiber, wifi, router, providerNetwork, speed, device, none }

class VerdictFinding {
  final VerdictSeverity severity;
  final VerdictArea area;
  final String title;
  final String detail;
  final String recommendation;

  const VerdictFinding({
    required this.severity,
    required this.area,
    required this.title,
    required this.detail,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'area': area.name,
        'title': title,
        'detail': detail,
        'recommendation': recommendation,
      };
}

class DiagnosticVerdict {
  final VerdictSeverity severity;
  final String headline;
  final String summary;
  final List<VerdictFinding> findings;

  /// Verdadeiro quando o problema provavelmente exige ação do provedor
  /// (fibra/rede externa), e não algo que o cliente resolve sozinho.
  final bool needsProviderSupport;

  const DiagnosticVerdict({
    required this.severity,
    required this.headline,
    required this.summary,
    required this.findings,
    required this.needsProviderSupport,
  });

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'headline': headline,
        'summary': summary,
        'needsProviderSupport': needsProviderSupport,
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}

/// Motor de laudo LOCAL e determinístico.
///
/// Substitui o antigo `/diagnostic/analyze`, que devolvia sempre o mesmo texto
/// fixo ("Sinal óptico abaixo do ideal (-25dBm)") independentemente da medição.
/// Aqui cada conclusão sai de um número realmente medido, com limiar explícito
/// e documentado — o que torna o laudo auditável e defensável no atendimento.
class DiagnosticVerdictEngine {
  // Limiares de potência óptica (dBm) — faixas usuais de GPON.
  static const double _rxExcellent = -20; // >= -20 dBm: sinal ótimo
  static const double _rxAcceptable = -25; // -20..-25: aceitável
  static const double _rxTooHigh = -8; // > -8 dBm: sinal alto demais (satura)

  // Latência ao gateway (rede local).
  static const double _gatewayLatencyWarn = 15;
  static const double _gatewayLatencyBad = 40;

  // Latência/jitter externos.
  static const double _externalLatencyWarn = 80;
  static const double _externalLatencyBad = 150;
  static const double _jitterWarn = 30;
  static const double _lossWarn = 2; // %
  static const double _lossBad = 5; // %

  // Wi-Fi (dBm).
  static const double _wifiWeak = -70;
  static const double _wifiVeryWeak = -80;

  // Percentual da velocidade contratada considerado aceitável no teste.
  static const double _speedWarnRatio = 0.6;
  static const double _speedBadRatio = 0.3;

  DiagnosticVerdict evaluate(DiagnosticReport report) {
    final findings = <VerdictFinding>[];

    _checkOnu(report, findings);
    _checkGateway(report, findings);
    _checkExternal(report, findings);
    _checkWifi(report, findings);
    _checkSpeed(report, findings);

    findings.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    final severity = findings.isEmpty
        ? VerdictSeverity.ok
        : findings.first.severity;

    final needsProvider = findings.any((f) =>
        f.severity != VerdictSeverity.ok &&
        (f.area == VerdictArea.fiber || f.area == VerdictArea.providerNetwork));

    return DiagnosticVerdict(
      severity: severity,
      headline: _headline(severity, findings),
      summary: _summary(report, severity, findings),
      findings: findings,
      needsProviderSupport: needsProvider,
    );
  }

  // ── Fibra / ONU ───────────────────────────────────────────────────────────
  void _checkOnu(DiagnosticReport r, List<VerdictFinding> out) {
    final onu = r.onu;
    if (onu == null) return;

    if (!onu.isOnline && onu.status != '---') {
      out.add(const VerdictFinding(
        severity: VerdictSeverity.critical,
        area: VerdictArea.fiber,
        title: 'Equipamento de fibra sem conexão',
        detail:
            'A ONU (equipamento da fibra) está reportando estado offline na central do provedor.',
        recommendation:
            'Verifique se o equipamento está ligado e se o cabo de fibra não está dobrado ou rompido. Se estiver tudo conectado, acione o suporte: pode ser rompimento na rede.',
      ));
      return;
    }

    final rx = onu.rxPower;
    if (rx != null) {
      if (rx < _rxAcceptable) {
        out.add(VerdictFinding(
          severity: VerdictSeverity.critical,
          area: VerdictArea.fiber,
          title: 'Sinal de fibra muito baixo',
          detail:
              'A potência óptica recebida está em ${rx.toStringAsFixed(1)} dBm, abaixo do mínimo aceitável de ${_rxAcceptable.toStringAsFixed(0)} dBm. Isso costuma causar quedas e lentidão.',
          recommendation:
              'Normalmente indica cabo dobrado, conector sujo ou perda na rede externa. É necessário atendimento técnico do provedor.',
        ));
      } else if (rx < _rxExcellent) {
        out.add(VerdictFinding(
          severity: VerdictSeverity.attention,
          area: VerdictArea.fiber,
          title: 'Sinal de fibra no limite',
          detail:
              'A potência óptica está em ${rx.toStringAsFixed(1)} dBm — funcional, mas fora da faixa ideal (acima de ${_rxExcellent.toStringAsFixed(0)} dBm).',
          recommendation:
              'Evite dobrar o cabo de fibra. Se houver instabilidade, informe o provedor para avaliar a rede externa.',
        ));
      } else if (rx > _rxTooHigh) {
        out.add(VerdictFinding(
          severity: VerdictSeverity.attention,
          area: VerdictArea.fiber,
          title: 'Sinal de fibra alto demais',
          detail:
              'A potência óptica está em ${rx.toStringAsFixed(1)} dBm, acima do recomendado. Sinal em excesso também degrada a conexão.',
          recommendation:
              'O provedor pode precisar ajustar a atenuação no equipamento.',
        ));
      }
    }
  }

  // ── Rede local (roteador) ─────────────────────────────────────────────────
  void _checkGateway(DiagnosticReport r, List<VerdictFinding> out) {
    final gw = r.gatewayPing;
    if (gw == null) return;

    if (!gw.reachable) {
      out.add(const VerdictFinding(
        severity: VerdictSeverity.critical,
        area: VerdictArea.router,
        title: 'Roteador não respondeu',
        detail:
            'O aparelho não conseguiu falar com o roteador da sua casa. Sem isso, nenhum acesso à internet funciona.',
        recommendation:
            'Reinicie o roteador e confirme que você está conectado à rede correta. Se persistir, o equipamento pode estar com defeito.',
      ));
      return;
    }

    final latency = gw.latencyMs;
    if (latency != null && latency > _gatewayLatencyBad) {
      out.add(VerdictFinding(
        severity: VerdictSeverity.attention,
        area: VerdictArea.wifi,
        title: 'Resposta lenta do roteador',
        detail:
            'A latência até o roteador é de ${latency.toStringAsFixed(0)} ms. Dentro de casa, o normal é abaixo de ${_gatewayLatencyWarn.toStringAsFixed(0)} ms — indica problema no Wi-Fi, não na internet.',
        recommendation:
            'Aproxime-se do roteador, prefira a rede 5 GHz ou use cabo. Muitos aparelhos conectados também deixam o Wi-Fi mais lento.',
      ));
    }

    if (gw.lossPercent >= _lossWarn) {
      out.add(VerdictFinding(
        severity: VerdictSeverity.attention,
        area: VerdictArea.wifi,
        title: 'Perda de pacotes na rede local',
        detail:
            '${gw.lossPercent.toStringAsFixed(0)}% dos pacotes enviados ao roteador se perderam. Isso trava chamadas e vídeos.',
        recommendation:
            'Costuma ser interferência de Wi-Fi. Teste mais perto do roteador ou com cabo para confirmar.',
      ));
    }
  }

  // ── Internet (fora de casa) ───────────────────────────────────────────────
  void _checkExternal(DiagnosticReport r, List<VerdictFinding> out) {
    final ping = r.externalPing;
    if (ping == null) return;

    final gatewayOk = r.gatewayPing?.reachable ?? false;

    if (!ping.reachable) {
      out.add(VerdictFinding(
        severity: VerdictSeverity.critical,
        area: gatewayOk ? VerdictArea.providerNetwork : VerdictArea.router,
        title: 'Sem acesso à internet',
        detail: gatewayOk
            ? 'O roteador responde normalmente, mas não há resposta de servidores na internet (${ping.host}). O problema está fora da sua casa.'
            : 'Não houve resposta nem do roteador nem da internet.',
        recommendation: gatewayOk
            ? 'Indica falha na rede do provedor. Envie este relatório ao suporte.'
            : 'Reinicie o roteador. Se não voltar, acione o suporte.',
      ));
      return;
    }

    if (ping.lossPercent >= _lossBad) {
      out.add(VerdictFinding(
        severity: VerdictSeverity.critical,
        area: VerdictArea.providerNetwork,
        title: 'Conexão instável (perda de pacotes)',
        detail:
            '${ping.lossPercent.toStringAsFixed(0)}% de perda até ${ping.host}. Acima de ${_lossBad.toStringAsFixed(0)}% já derruba chamadas e jogos.',
        recommendation:
            'Perda nesse nível normalmente é da rede do provedor. Envie este relatório ao suporte.',
      ));
    } else if (ping.lossPercent >= _lossWarn) {
      out.add(VerdictFinding(
        severity: VerdictSeverity.attention,
        area: VerdictArea.providerNetwork,
        title: 'Pequena perda de pacotes',
        detail:
            '${ping.lossPercent.toStringAsFixed(0)}% de perda até ${ping.host}.',
        recommendation:
            'Monitore. Se acontecer com frequência, informe o provedor.',
      ));
    }

    final latency = ping.latencyMs;
    if (latency != null && latency > _externalLatencyBad) {
      out.add(VerdictFinding(
        severity: VerdictSeverity.attention,
        area: VerdictArea.providerNetwork,
        title: 'Latência alta',
        detail:
            'O tempo de resposta até ${ping.host} é de ${latency.toStringAsFixed(0)} ms (o normal em fibra fica abaixo de ${_externalLatencyWarn.toStringAsFixed(0)} ms).',
        recommendation:
            'Latência alta atrapalha jogos e videochamadas. Vale reportar ao provedor.',
      ));
    }

    final jitter = ping.jitterMs;
    if (jitter != null && jitter > _jitterWarn) {
      out.add(VerdictFinding(
        severity: VerdictSeverity.attention,
        area: VerdictArea.providerNetwork,
        title: 'Conexão oscilando (jitter)',
        detail:
            'A variação de latência é de ${jitter.toStringAsFixed(0)} ms. Oscilação acima de ${_jitterWarn.toStringAsFixed(0)} ms causa travadas em chamadas de voz e vídeo.',
        recommendation:
            'Se você usa muito videochamada, reporte ao provedor com este relatório.',
      ));
    }
  }

  // ── Wi-Fi ─────────────────────────────────────────────────────────────────
  void _checkWifi(DiagnosticReport r, List<VerdictFinding> out) {
    final wifi = r.wifi;
    final dbm = wifi?.signalDbm;
    if (wifi == null || dbm == null) return;

    if (dbm <= _wifiVeryWeak) {
      out.add(VerdictFinding(
        severity: VerdictSeverity.critical,
        area: VerdictArea.wifi,
        title: 'Sinal de Wi-Fi muito fraco',
        detail:
            'O sinal onde você está é de ${dbm.toStringAsFixed(0)} dBm. Abaixo de ${_wifiVeryWeak.toStringAsFixed(0)} dBm a conexão fica instável mesmo com a internet funcionando bem.',
        recommendation:
            'Aproxime-se do roteador ou considere um repetidor. Esse resultado não indica problema na sua internet.',
      ));
    } else if (dbm <= _wifiWeak) {
      out.add(VerdictFinding(
        severity: VerdictSeverity.attention,
        area: VerdictArea.wifi,
        title: 'Sinal de Wi-Fi fraco',
        detail:
            'O sinal está em ${dbm.toStringAsFixed(0)} dBm — a velocidade medida pode ficar bem abaixo do contratado por causa disso.',
        recommendation:
            'Para medir a velocidade real do plano, teste perto do roteador ou por cabo.',
      ));
    }
  }

  // ── Velocidade vs plano contratado ────────────────────────────────────────
  void _checkSpeed(DiagnosticReport r, List<VerdictFinding> out) {
    final speed = r.speed;
    final contracted = r.customer.contractedDownloadMbps;
    if (speed == null || contracted == null || contracted <= 0) return;

    final ratio = speed.downloadMbps / contracted;
    if (ratio >= _speedWarnRatio) return;

    // Wi-Fi fraco explica velocidade baixa sem que haja problema no plano.
    final weakWifi = (r.wifi?.signalDbm ?? 0) <= _wifiWeak;
    final severity =
        ratio < _speedBadRatio && !weakWifi ? VerdictSeverity.critical : VerdictSeverity.attention;

    out.add(VerdictFinding(
      severity: severity,
      area: VerdictArea.speed,
      title: 'Velocidade abaixo do contratado',
      detail:
          'A medição registrou ${speed.downloadMbps.toStringAsFixed(1)} Mbps de download, contra ${contracted.toStringAsFixed(0)} Mbps do plano ${r.customer.planName} '
          '(${(ratio * 100).toStringAsFixed(0)}% do contratado).',
      recommendation: weakWifi
          ? 'O sinal de Wi-Fi estava fraco durante o teste, o que reduz bastante o resultado. Refaça o teste perto do roteador ou por cabo antes de acionar o suporte.'
          : 'Refaça o teste com o aparelho próximo ao roteador e sem downloads em andamento. Se o resultado se repetir, envie este relatório ao suporte.',
    ));
  }

  // ── Textos de topo ────────────────────────────────────────────────────────
  String _headline(VerdictSeverity severity, List<VerdictFinding> findings) {
    switch (severity) {
      case VerdictSeverity.ok:
        return 'Sua conexão está funcionando bem';
      case VerdictSeverity.attention:
        return 'Encontramos pontos de atenção';
      case VerdictSeverity.critical:
        return findings.isEmpty
            ? 'Problema detectado'
            : findings.first.title;
    }
  }

  String _summary(
      DiagnosticReport r, VerdictSeverity severity, List<VerdictFinding> findings) {
    if (severity == VerdictSeverity.ok) {
      final speed = r.speed;
      if (speed != null) {
        return 'Todos os testes passaram. A velocidade medida foi de '
            '${speed.downloadMbps.toStringAsFixed(1)} Mbps de download e '
            '${speed.uploadMbps.toStringAsFixed(1)} Mbps de upload.';
      }
      return 'Todos os testes realizados passaram sem problemas.';
    }

    final areas = findings
        .where((f) => f.severity != VerdictSeverity.ok)
        .map((f) => _areaLabel(f.area))
        .toSet()
        .toList();

    final list = areas.length == 1
        ? areas.first
        : '${areas.take(areas.length - 1).join(', ')} e ${areas.last}';

    return 'O diagnóstico apontou ${findings.length} ponto(s) relacionados a $list. '
        'Os detalhes e as recomendações estão listados abaixo.';
  }

  String _areaLabel(VerdictArea area) {
    switch (area) {
      case VerdictArea.fiber:
        return 'fibra óptica';
      case VerdictArea.wifi:
        return 'Wi-Fi';
      case VerdictArea.router:
        return 'roteador';
      case VerdictArea.providerNetwork:
        return 'rede do provedor';
      case VerdictArea.speed:
        return 'velocidade';
      case VerdictArea.device:
        return 'aparelho';
      case VerdictArea.none:
        return 'conexão';
    }
  }
}
