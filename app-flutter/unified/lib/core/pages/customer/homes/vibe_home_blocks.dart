import 'package:flutter/material.dart';

import '../../../vibe/vibe_home_parts.dart';
import '../../../vibe/vibe_icon.dart';
import '../../../vibe/vibe_invoice.dart';
import '../../../vibe/vibe_skeleton.dart';
import '../../../vibe/vibe_text.dart';
import '../../../vibe/vibe_tokens.dart';
import '../../invoice_detail_page.dart';
import 'vibe_home_data.dart';

/// Blocos comuns aos cinco Inícios do layout aprovado.

/// O cartão da fatura do Início em qualquer situação da consulta.
///
/// Os cinco layouts desenham o mesmo cartão em três situações, sempre com a
/// mesma geometria:
/// - **carregando** (primeira consulta, nada guardado): o cartão real com
///   uma fatura de exemplo; rótulos, ícones, moldura do selo e botões
///   aparecem, e só os valores ficam cobertos ([redacted]). Botões a 45%,
///   sem toque.
/// - **erro sem dados**: mesmo cartão; a mensagem entra no lugar do valor e
///   "Tentar novamente" no lugar dos botões de pagamento.
/// - **dados** (da consulta ou guardados no aparelho): o cartão normal.
///   Atualizando, aparece só uma barra fina no topo; se a atualização
///   falhar, uma linha discreta avisa e os botões seguem funcionando.
class VibeInvoiceSlot {
  VibeInvoiceSlot(this.billing, {this.onBrand = false, this.color});

  final VibeBilling billing;
  final bool onBrand;

  /// Cor base das barras em superfícies próprias (cartão escuro da Dock).
  final Color? color;

  static const failedMessage = 'Não conseguimos consultar agora.';
  static const slowMessage = 'Ainda consultando… a conexão está lenta.';

  bool get redacted => billing.loading;
  bool get failed => billing.failed;

  /// Consulta concluída sem nenhuma fatura: "Sem fatura emitida".
  bool get empty => billing.ready && billing.main == null;

  /// A fatura do cartão, ou a de exemplo enquanto carrega ou no erro.
  VibeInvoiceView? get view =>
      billing.main ?? (redacted || failed ? billing.placeholder : null);

  VoidCallback get retry => billing.finance.fetchHistory;

  /// Valor coberto enquanto carrega.
  Widget value(Widget child, {bool block = false}) => VibeRedact(
      redacted: redacted,
      onBrand: onBrand,
      color: color,
      block: block,
      child: child);

  /// "Fatura de novembro": o "Fatura de" fica visível e só o mês é coberto;
  /// no erro, "Fatura de —".
  Widget title(String prefix, String value, TextStyle style,
      {TextAlign textAlign = TextAlign.start}) {
    if (!redacted && !failed) {
      return Text('$prefix$value', style: style, textAlign: textAlign);
    }
    // O mês entra como um bloco na mesma linha do texto, com a medida da
    // palavra de exemplo: quebra de linha igual à do título real. No erro,
    // "—" ocupa o mesmo lugar.
    final word = Text(value, style: style, textScaler: TextScaler.noScaling);
    final Widget slotChild = failed
        ? Stack(alignment: AlignmentDirectional.centerStart, children: [
            _invisible(word),
            Text('—', style: style, textScaler: TextScaler.noScaling),
          ])
        : this.value(word);
    return Text.rich(
      TextSpan(text: prefix, children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: slotChild,
        ),
      ]),
      style: style,
      textAlign: textAlign,
      semanticsLabel: failed ? '$prefix—' : prefix.trim(),
    );
  }

  /// Texto do selo (o ícone e a moldura ficam).
  String chipLabel(VibeInvoiceView view) => failed ? 'Indisponível' : view.chip;

  /// Valor da fatura; no erro sem dados, a mensagem no mesmo espaço.
  /// [frame] posiciona o valor (alinhamento, FittedBox) sem entrar na barra.
  Widget amount(BuildContext context, Widget amount,
      {Widget Function(Widget)? frame,
      TextStyle? messageStyle,
      AlignmentGeometry alignment = Alignment.centerLeft,
      TextAlign textAlign = TextAlign.start}) {
    final place = frame ?? (Widget w) => w;
    if (!failed) return place(value(amount));
    final t = VibeTokens.of(context);
    return _overlay(
        place(amount),
        Align(
          alignment: alignment,
          child: Text(failedMessage,
              textAlign: textAlign,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: messageStyle ??
                  vibeText(t, 15, 700,
                      color: color ?? (onBrand ? t.on : t.ink), height: 1.25)),
        ));
  }

  /// Linha de vencimento: coberta enquanto carrega (e, se demorar, troca
  /// pelo aviso de conexão lenta); no erro, guarda o espaço vazio.
  Widget due(Widget line, {Widget? slow}) {
    if (failed) return _invisible(line);
    if (!redacted || slow == null) return line;
    return VibeSlowSwap(waiting: redacted, slow: slow, child: line);
  }

  /// Botões de pagamento: a 45% e sem toque enquanto carrega; no erro sem
  /// dados, [retryButton] no lugar.
  Widget actions(Widget child, {Widget? retryButton, bool keepSize = true}) {
    if (failed && retryButton != null) {
      if (!keepSize) return retryButton;
      // A área dos botões de pagamento continua com a mesma altura (inclusive
      // com fonte ampliada); "Tentar novamente" fica no meio dela.
      return Stack(children: [
        _invisible(child),
        Positioned.fill(
          child: Align(
              child: SizedBox(width: double.infinity, child: retryButton)),
        ),
      ]);
    }
    return VibeDimmed(dimmed: redacted, child: child);
  }

  /// Semântica do cartão inteiro: "Consultando suas faturas" para quem usa
  /// leitor de tela; o texto não aparece na tela.
  Widget semantics(Widget child) => Semantics(
        container: true,
        liveRegion: redacted || failed,
        label: redacted
            ? 'Consultando suas faturas'
            : failed
                ? failedMessage
                : null,
        child: child,
      );

  static Widget _invisible(Widget child) => ExcludeSemantics(
        child: IgnorePointer(
          child: Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: child),
        ),
      );

  /// Mantém o tamanho de [sizing] (largura total) e mostra [overlay] por
  /// cima, ocupando o mesmo espaço.
  static Widget _overlay(Widget sizing, Widget overlay) => Stack(children: [
        SizedBox(
            width: double.infinity,
            child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _invisible(sizing))),
        Positioned.fill(child: overlay),
      ]);

  /// Mesmo espaço de [sizing], com [overlay] por cima (para o erro sem
  /// dados em linhas com valor e botão lado a lado).
  static Widget overlay(Widget sizing, Widget overlay) =>
      _overlay(sizing, overlay);
}

/// "Sem fatura emitida" quando a consulta terminou sem nenhuma fatura.
Widget? vibeEmptyInvoice(BuildContext context, VibeHomeData data,
    {bool onBrand = false, bool center = false}) {
  final billing = data.billing;
  if (!(billing.ready && billing.main == null)) return null;
  final t = VibeTokens.of(context);
  final color = onBrand ? t.on : t.ink;
  final muted = onBrand ? t.on.withValues(alpha: .85) : t.mut;
  final align = center ? TextAlign.center : TextAlign.start;
  return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text('Sem fatura emitida',
            textAlign: align, style: vibeText(t, 18, 750, color: color)),
        const SizedBox(height: 4),
        Text(
            billing.finance.incompleteInvoices > 0
                ? 'Algumas faturas estão com dados incompletos. Consulte o provedor.'
                : 'A próxima mensalidade aparecerá aqui.',
            textAlign: align,
            style: vibeText(t, 14, 500, color: muted)),
      ]);
}

/// Linha discreta quando a atualização falhou ou o celular está sem
/// internet, com dados já na tela: "Não foi possível atualizar · dados de
/// 14:32" e "Tentar de novo". Os botões de pagamento seguem funcionando.
Widget? vibeStaleNote(BuildContext context, VibeHomeData data,
    {bool onBrand = false, Color? color, bool center = false}) {
  final billing = data.billing;
  final asOf = billing.asOf;
  final offline = data.network == VibeNetwork.offline;
  if (!billing.hasData || asOf == null) return null;
  if (!billing.refreshFailed && !(offline && !billing.refreshing)) {
    return null;
  }
  final t = VibeTokens.of(context);
  final fg = color ?? (onBrand ? t.on.withValues(alpha: .88) : t.mut);
  final text = Text.rich(
    TextSpan(children: [
      TextSpan(text: offline ? 'Sem conexão' : 'Desatualizado'),
      TextSpan(text: ' · dados de ${vibeAsOf(asOf)}'),
      if (!offline)
        TextSpan(
            text: ' · Tentar de novo',
            style: vibeText(t, 12, 750, color: fg).copyWith(
                decoration: TextDecoration.underline, decorationColor: fg)),
    ]),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textAlign: center ? TextAlign.center : TextAlign.start,
    style: vibeText(t, 12, 600, color: fg),
  );
  final row = Row(
      mainAxisSize: center ? MainAxisSize.min : MainAxisSize.max,
      children: [
        VibeIcon(offline ? 'wifi' : 'alert', size: 14, color: fg),
        const SizedBox(width: 6),
        Flexible(child: text),
      ]);
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Semantics(
      liveRegion: true,
      button: !offline,
      child: InkWell(
        onTap: offline ? null : billing.finance.fetchHistory,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Align(
              alignment: center ? Alignment.center : Alignment.centerLeft,
              child: row),
        ),
      ),
    ),
  );
}

/// Aviso de dados incompletos abaixo do cartão da fatura.
Widget? vibeIncompleteNote(BuildContext context, VibeHomeData data,
    {bool onBrand = false}) {
  if (data.billing.finance.incompleteInvoices == 0 ||
      data.billing.main == null) {
    return null;
  }
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: VibeNoteLine(
        text:
            'Algumas faturas estão com dados incompletos. Consulte o provedor.',
        tone: VibeTone.warning,
        onBrand: onBrand,
        icon: 'alert'),
  );
}

/// Botão principal de pagamento (`P(s)` do protótipo): Pix quando existe,
/// senão boleto ou linha digitável; "Ver fatura" quando já está paga.
Widget vibePayButton(
  BuildContext context,
  VibeInvoiceView view, {
  required VibeButtonKind kind,
  VibeButtonKind? paidKind,
  VibeButtonSize size = VibeButtonSize.regular,
  String pixLabel = 'Copiar código Pix',
  bool onBrand = false,
  bool dense = false,
}) {
  final invoice = view.invoice;
  if (view.paid) {
    return VibeButton(
      label: 'Ver fatura',
      icon: 'file',
      kind: paidKind ?? (onBrand ? VibeButtonKind.tinted : kind),
      size: size,
      onBrand: onBrand,
      dense: dense,
      onPressed: () => openSubscriberInvoice(context, invoice),
    );
  }
  if (view.hasPix) {
    return VibeButton(
      label: pixLabel,
      icon: 'pix',
      kind: kind,
      size: size,
      onBrand: onBrand,
      dense: dense,
      onPressed: () =>
          VibeInvoiceActions.copyPix(context, invoice, asOf: view.asOf),
    );
  }
  if (view.hasBoleto) {
    return VibeButton(
      label: 'Ver boleto',
      icon: 'bar',
      kind: kind,
      size: size,
      onBrand: onBrand,
      dense: dense,
      onPressed: () => VibeInvoiceActions.openBoleto(context, invoice),
    );
  }
  if (view.hasLine) {
    return VibeButton(
      label: 'Copiar código de barras',
      icon: 'copy',
      kind: kind,
      size: size,
      onBrand: onBrand,
      dense: dense,
      onPressed: () =>
          VibeInvoiceActions.copyLine(context, invoice, asOf: view.asOf),
    );
  }
  return VibeButton(
    label: 'Ver fatura',
    icon: 'file',
    kind: kind,
    size: size,
    onBrand: onBrand,
    dense: dense,
    onPressed: () => openSubscriberInvoice(context, invoice),
  );
}

/// Boleto ao lado do Pix (`B(s)`), só quando a fatura tem os dois.
Widget? vibeBoletoButton(BuildContext context, VibeInvoiceView view,
    {required VibeButtonKind kind,
    VibeButtonSize size = VibeButtonSize.regular,
    bool onBrand = false,
    bool dense = false,
    String label = 'Ver boleto'}) {
  if (view.paid || !view.hasPix || !view.hasBoleto) return null;
  return VibeButton(
    label: label,
    icon: 'bar',
    kind: kind,
    size: size,
    onBrand: onBrand,
    dense: dense,
    onPressed: () => VibeInvoiceActions.openBoleto(context, view.invoice),
  );
}

/// Segunda fatura em aberto (`.old`): valor, prazo e as duas formas de
/// pagar a própria fatura.
class VibeNextInvoiceCard extends StatelessWidget {
  const VibeNextInvoiceCard({super.key, required this.view});

  final VibeInvoiceView view;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final pay = vibePayButton(context, view,
        kind: VibeButtonKind.primary,
        size: VibeButtonSize.small,
        dense: true,
        pixLabel: 'Copiar Pix de ${view.month}');
    final boleto = vibeBoletoButton(context, view,
        kind: VibeButtonKind.outline,
        size: VibeButtonSize.small,
        dense: true,
        label: 'Boleto');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${view.monthTitle} também está em aberto',
                  style: vibeText(t, 14, 700)),
              const SizedBox(height: 2),
              Text(view.dueFull, style: vibeText(t, 12.5, 500, color: t.mut)),
              Text(view.overdue ? 'Vencida' : 'Ainda no prazo',
                  style: vibeText(t, 12.5, 500,
                      color: view.overdue ? t.bad : t.mut)),
            ]),
          ),
          const SizedBox(width: 10),
          VibeAmount(view.invoice.valor, size: 22, color: t.ink),
        ]),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          if (boleto == null) return pay;
          final scaler = MediaQuery.textScalerOf(context);
          double textWidth(String text) {
            final painter = TextPainter(
              text: TextSpan(
                  text: text, style: vibeText(t, 13, 700, height: 1.1)),
              textDirection: Directionality.of(context),
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            final width = painter.width;
            painter.dispose();
            return width;
          }

          final boletoWidth = textWidth('Boleto') + 20 + 6 + 24;
          final pixWidth =
              constraints.maxWidth - boletoWidth - 10 - 20 - 6 - 24;
          final pixText = TextPainter(
            text: TextSpan(
                text: 'Copiar Pix de ${view.month}',
                style: vibeText(t, 13, 700, height: 1.1)),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 2,
          )..layout(maxWidth: pixWidth.clamp(0, double.infinity));
          final mustStack = pixText.didExceedMaxLines;
          pixText.dispose();
          if (mustStack) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  pay,
                  const SizedBox(height: 8),
                  boleto,
                ]);
          }
          return Row(children: [
            Expanded(child: pay),
            const SizedBox(width: 10),
            boleto
          ]);
        }),
      ]),
    );
  }
}

/// Avisos abaixo do cartão (`AL(s)` e `TR(s)`): internet suspensa ou a
/// próxima fatura em aberto, a rede do celular e a liberação por confiança.
List<Widget> vibeHomeAlerts(BuildContext context, VibeHomeData data,
    {double gap = 10}) {
  final billing = data.billing;
  final main = billing.main;
  final next = billing.next;
  final out = <Widget>[];
  if (data.suspended) {
    out.add(VibeAlertBox(
      title: 'Internet suspensa',
      text: main != null && main.overdue
          ? 'A fatura de ${main.month} está vencida. Pague para liberar o acesso.'
          : 'Consulte suas faturas ou fale com o provedor.',
      onTap: data.can('invoices') ? () => data.onNavigate('invoices') : null,
    ));
  }
  if (next != null && data.can('invoices')) {
    if (out.isNotEmpty) out.add(SizedBox(height: gap));
    out.add(VibeNextInvoiceCard(view: next));
  }
  if (data.can('network_diagnostic')) {
    if (out.isNotEmpty) out.add(SizedBox(height: gap));
    out.add(VibeConnectionCard(
        network: data.network,
        plan: data.plan,
        serviceStatus: data.user?.status ?? '',
        onTap: data.openDiagnostic));
  }
  if (data.suspended && billing.overdue && data.can('invoices')) {
    out.add(SizedBox(height: gap));
    out.add(VibeActionCard(
      icon: 'unlock',
      title: 'Liberar por confiança',
      text: 'Libera a internet por 24 horas',
      onTap: () => data.onNavigate('trust_unlock'),
    ));
  }
  return out;
}

/// Ajuda quando há fatura vencida (`LATE(s)`).
Widget? vibeLateHelp(VibeHomeData data) {
  if (!data.billing.overdue) return null;
  return VibeLateHelp(
    suspended: data.suspended,
    onAction: data.can('support') ? () => data.onNavigate('support') : null,
  );
}

/// Lembrete da situação abaixo dos atalhos (`.rm` do layout Faixa e fatura).
Widget? vibeReminder(BuildContext context, VibeInvoiceView? view) {
  if (view == null) return null;
  final t = VibeTokens.of(context);
  final (String icon, String text)? content = view.paid
      ? ('check', 'Pagamento confirmado. Sua conta está em dia.')
      : view.dueToday
          ? ('bolt', 'Vence hoje. Pelo Pix, a confirmação sai em minutos.')
          : view.overdue
              ? ('alert', 'Pague agora para evitar a suspensão do acesso.')
              : null;
  if (content == null) return null;
  final ok = view.paid;
  final bg = ok
      ? t.okb
      : t.dark
          ? t.wab
          : const Color(0xFFFFF4E5);
  final fg = ok
      ? t.ok
      : t.dark
          ? t.wa
          : const Color(0xFF7A4300);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      VibeIcon(content.$1, size: 16, color: fg),
      const SizedBox(width: 10),
      Expanded(child: Text(content.$2, style: vibeText(t, 13, 600, color: fg))),
    ]),
  );
}
