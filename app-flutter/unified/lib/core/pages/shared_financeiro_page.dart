import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fatura.dart';
import '../providers/financeiro_provider.dart';
import '../providers/providers.dart';
import '../utils/app_formatters.dart';
import '../vibe/vibe_icon.dart';
import '../vibe/vibe_invoice.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';
import 'invoice_detail_page.dart';

/// Faturas (`PG.faturas` do layout aprovado): em aberto e pagas, com a
/// fatura principal, as formas de pagamento e a liberação por confiança.
class FinanceiroPage extends ConsumerStatefulWidget {
  const FinanceiroPage({super.key});

  @override
  ConsumerState<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends ConsumerState<FinanceiroPage> {
  bool _showPaid = false;
  bool _showAllOpen = false;

  @override
  Widget build(BuildContext context) {
    final finance = ref.watch(financeiroViewModelProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final billing = VibeBilling(finance);
    final open = billing.open;
    final paid = billing.paid;
    // Dados na tela (da consulta ou guardados) podem ser usados: copiar o
    // Pix não espera a atualização terminar.
    final ready = billing.ready;
    final loading = billing.loading;
    final subtitle = [
      if (user?.contratoId != null) 'Contrato ${user!.contratoId}',
      if (user?.plano.trim().isNotEmpty == true)
        AppFormatters.label(user!.plano),
    ].join(' · ');

    final List<Widget> body;
    if (billing.failed) {
      // Sem nada guardado e a consulta falhou: um único aviso.
      body = [
        VibeCard(
          child: VibeEmpty(
            icon: 'alert',
            title: 'Não foi possível consultar suas faturas',
            text: 'Verifique sua conexão e tente de novo.',
            action: VibePageButton(
                label: 'Tentar novamente',
                icon: 'g-refresh',
                small: true,
                expand: false,
                onPressed: finance.fetchHistory),
          ),
        ),
      ];
    } else if (_showPaid) {
      body = [
        if (loading)
          const _PaidRowsLoading()
        else if (paid.isEmpty)
          const VibeCard(
              child: VibeEmpty(
                  icon: 'file', title: 'Nenhuma fatura paga disponível'))
        else
          VibeCard(
              child: VibeRows(children: [
            for (final invoice in paid) _paidRow(context, invoice, ready),
          ])),
      ];
    } else if (loading) {
      body = [
        Semantics(
          label: 'Consultando suas faturas',
          liveRegion: true,
          child: _MainInvoice(
              view: billing.placeholder, ready: false, redacted: true),
        ),
      ];
    } else if (open.isEmpty) {
      body = [
        VibeCard(
          child: VibeEmpty(
            icon: finance.incompleteInvoices > 0 ? 'alert' : 'check',
            title: finance.incompleteInvoices > 0
                ? 'Não foi possível confirmar todas as faturas'
                : 'Nenhuma fatura em aberto',
            text: finance.incompleteInvoices > 0
                ? 'Consulte o suporte para confirmar suas cobranças.'
                : 'Sua conta está em dia.',
          ),
        ),
      ];
    } else {
      body = [
        _MainInvoice(view: billing.view(open.first), ready: ready),
        if (open.length > 1)
          VibeCard(
            child: VibeRows(children: [
              VibeRow(
                icon: 'file',
                plainIcon: true,
                title: 'Outras pendências (${open.length - 1})',
                trailing: _Chevron(up: _showAllOpen),
                onTap: () => setState(() => _showAllOpen = !_showAllOpen),
              ),
              if (_showAllOpen)
                for (final invoice in open.skip(1))
                  VibeRow(
                    icon: 'file',
                    title:
                        'Fatura de ${VibeInvoiceView(invoice).month} · ${AppFormatters.currency(invoice.valor)}',
                    subtitle: VibeInvoiceView(invoice).dueFull,
                    onTap: ready
                        ? () => openSubscriberInvoice(context, invoice)
                        : null,
                  ),
            ]),
          ),
        if (open.any((invoice) => VibeInvoiceView(invoice).overdue))
          VibeCard(
            child: VibeRow(
              icon: 'unlock',
              title: 'Liberar por confiança',
              subtitle: 'Peça a liberação enquanto o pagamento é confirmado',
              onTap: ready ? () => openSubscriberTrustUnlock(context) : null,
            ),
          ),
      ];
    }

    final asOf = billing.asOf;
    final children = <Widget>[
      // Atualização falhou com dados na tela: aviso curto, tudo segue usável.
      if (billing.refreshFailed && asOf != null)
        VibeOkBox(
            strip: true,
            warning: true,
            title:
                'Não foi possível atualizar. Mostrando dados de ${vibeAsOf(asOf)}.'),
      if (finance.incompleteInvoices > 0 && ready)
        const VibeOkBox(
            strip: true,
            warning: true,
            title:
                'Algumas faturas têm dados incompletos. Consulte o suporte para confirmar todas as cobranças.'),
      VibeSegmented<bool>(
        // A contagem só aparece quando há lista: "(0)" enquanto carrega
        // seria uma informação errada.
        options: [
          (false, ready ? 'Em aberto (${open.length})' : 'Em aberto'),
          (true, 'Pagas')
        ],
        selected: _showPaid,
        onChanged: (value) => setState(() => _showPaid = value),
      ),
      ...body,
      VibePageButton(
        label: 'Atualizar',
        icon: 'g-refresh',
        ghost: true,
        onPressed: finance.state == FinanceiroState.loading
            ? null
            : finance.fetchHistory,
      ),
    ];

    return VibePageScaffold(
      title: 'Faturas',
      subtitle: subtitle.isEmpty ? null : subtitle,
      onRefresh: finance.fetchHistory,
      children: children,
    );
  }

  Widget _paidRow(BuildContext context, Fatura invoice, bool ready) {
    final t = VibeTokens.of(context);
    final view = VibeInvoiceView(invoice);
    return VibeRow(
      icon: 'check',
      title: 'Fatura de ${view.month}',
      subtitle: view.dueFull,
      trailing: Text(AppFormatters.currency(invoice.valor),
          style: vibeText(t, 13.5, 700)),
      onTap: ready ? () => openSubscriberInvoice(context, invoice) : null,
    );
  }
}

/// Cartão da fatura principal (`.g-cd.g-main` de Faturas).
class _MainInvoice extends StatelessWidget {
  const _MainInvoice(
      {required this.view, required this.ready, this.redacted = false});

  final VibeInvoiceView view;
  final bool ready;

  /// Esqueleto: o próprio cartão com uma fatura de exemplo coberta.
  final bool redacted;

  @override
  Widget build(BuildContext context) {
    final invoice = view.invoice;
    VoidCallback? when(VoidCallback action) => ready ? action : null;
    final details = VibePageButton(
        label: 'Ver detalhes',
        ghost: true,
        onPressed: when(() => openSubscriberInvoice(context, invoice)));
    final Widget primary = view.hasPix
        ? VibePageButton(
            label: 'Copiar Pix',
            icon: 'pix',
            onPressed: when(() =>
                VibeInvoiceActions.copyPix(context, invoice, asOf: view.asOf)))
        : view.hasBoleto
            ? VibePageButton(
                label: 'Abrir boleto',
                icon: 'bar',
                onPressed:
                    when(() => VibeInvoiceActions.openBoleto(context, invoice)))
            : view.hasLine
                ? VibePageButton(
                    label: 'Copiar linha',
                    icon: 'copy',
                    onPressed: when(() => VibeInvoiceActions.copyLine(
                        context, invoice,
                        asOf: view.asOf)))
                : details;
    final links = <(String, String, VoidCallback?)>[
      if (view.hasLine && view.hasPix)
        (
          'copy',
          'Linha digitável',
          when(() =>
              VibeInvoiceActions.copyLine(context, invoice, asOf: view.asOf))
        ),
      if (view.hasBoleto && (view.hasPix || view.hasLine))
        (
          'bar',
          'Abrir boleto',
          when(() => VibeInvoiceActions.openBoleto(context, invoice))
        ),
    ];
    final buttons =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      identical(primary, details) ? details : VibeTwo(primary, details),
      if (links.isNotEmpty) ...[
        const SizedBox(height: 10),
        VibeLinkButtons(items: links),
      ],
    ]);
    return VibeCard(
      main: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: redacted
                  ? Row(children: [
                      const VibeLabel('Fatura de'),
                      const SizedBox(width: 4),
                      Flexible(
                          child: VibeRedact(
                              redacted: true, child: VibeLabel(view.month))),
                    ])
                  : VibeLabel('Fatura de ${view.month}')),
          VibeRedact(
              redacted: redacted,
              block: true,
              radius: 13,
              child: VibePageChip(tone: view.tone, label: view.chip)),
        ]),
        VibePageAmount(invoice.valor, redacted: redacted),
        VibeSubLine(
            icon: view.paid ? 'check' : 'cal',
            text: view.dueFull,
            redacted: redacted,
            tone: view.tone == VibeTone.neutral ? null : view.tone),
        if (view.note != null) VibeSubLine(icon: 'info', text: view.note!),
        if (!view.hasPaymentData) ...[
          const SizedBox(height: 10),
          const VibeOkBox(
              strip: true,
              warning: true,
              title:
                  'Boleto disponível na central do assinante ou com o suporte.'),
        ],
        const SizedBox(height: 9),
        VibeDimmed(dimmed: redacted, child: buttons),
      ]),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.up});
  final bool up;

  @override
  Widget build(BuildContext context) => RotatedBox(
        quarterTurns: up ? 2 : 0,
        child: VibeIcon('chevd', size: 16, color: VibeTokens.of(context).ink),
      );
}

/// Pagas ainda sem lista: três linhas no desenho real, valores cobertos.
class _PaidRowsLoading extends StatelessWidget {
  const _PaidRowsLoading();

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Semantics(
      label: 'Consultando suas faturas',
      liveRegion: true,
      child: VibeCard(
        child: VibeRows(children: [
          for (var i = 0; i < 3; i++)
            VibeRow(
              icon: 'check',
              title: 'Fatura de outubro',
              subtitle: 'Paga em 10/10/2026',
              redacted: true,
              trailing: VibeRedact(
                  redacted: true,
                  child: Text('R\$ 199,90', style: vibeText(t, 13.5, 700))),
            ),
        ]),
      ),
    );
  }
}
