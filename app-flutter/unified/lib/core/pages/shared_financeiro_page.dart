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
    final ready = finance.state == FinanceiroState.success;
    final subtitle = [
      if (user?.contratoId != null) 'Contrato ${user!.contratoId}',
      if (user?.plano.trim().isNotEmpty == true)
        AppFormatters.label(user!.plano),
    ].join(' · ');

    final children = <Widget>[
      if (finance.state == FinanceiroState.error)
        VibeCard(
          main: true,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const VibeErrorLine('Não foi possível atualizar suas faturas.'),
            const SizedBox(height: 10),
            VibePageButton(
                label: 'Tentar novamente',
                icon: 'g-refresh',
                small: true,
                onPressed: finance.fetchHistory),
          ]),
        ),
      if (finance.incompleteInvoices > 0)
        const VibeOkBox(
            strip: true,
            warning: true,
            title:
                'Algumas faturas têm dados incompletos. Consulte o suporte para confirmar todas as cobranças.'),
      VibeSegmented<bool>(
        options: [(false, 'Em aberto (${open.length})'), (true, 'Pagas')],
        selected: _showPaid,
        onChanged: (value) => setState(() => _showPaid = value),
      ),
      if (finance.state == FinanceiroState.loading && finance.invoices.isEmpty)
        const _Loading()
      else if (_showPaid)
        paid.isEmpty
            ? const VibeCard(
                child: VibeEmpty(
                    icon: 'file', title: 'Nenhuma fatura paga disponível'))
            : VibeCard(
                child: VibeRows(children: [
                for (final invoice in paid) _paidRow(context, invoice, ready),
              ]))
      else if (open.isEmpty)
        VibeCard(
          child: VibeEmpty(
            icon: 'check',
            title: finance.incompleteInvoices > 0 ||
                    finance.state == FinanceiroState.error
                ? 'Não foi possível confirmar todas as faturas'
                : 'Nenhuma fatura em aberto',
            text: finance.incompleteInvoices > 0 ||
                    finance.state == FinanceiroState.error
                ? 'Consulte o suporte para confirmar suas cobranças.'
                : 'Sua conta está em dia.',
          ),
        )
      else ...[
        _MainInvoice(view: VibeInvoiceView(open.first), ready: ready),
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
      ],
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
  const _MainInvoice({required this.view, required this.ready});

  final VibeInvoiceView view;
  final bool ready;

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
            onPressed: when(() => VibeInvoiceActions.copyPix(context, invoice)))
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
                    onPressed: when(
                        () => VibeInvoiceActions.copyLine(context, invoice)))
                : details;
    final links = <(String, String, VoidCallback?)>[
      if (view.hasLine && view.hasPix)
        (
          'copy',
          'Linha digitável',
          when(() => VibeInvoiceActions.copyLine(context, invoice))
        ),
      if (view.hasBoleto && (view.hasPix || view.hasLine))
        (
          'bar',
          'Abrir boleto',
          when(() => VibeInvoiceActions.openBoleto(context, invoice))
        ),
    ];
    return VibeCard(
      main: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: VibeLabel('Fatura de ${view.month}')),
          VibePageChip(tone: view.tone, label: view.chip),
        ]),
        VibePageAmount(invoice.valor),
        VibeSubLine(
            icon: view.paid ? 'check' : 'cal',
            text: view.dueFull,
            tone: view.tone == VibeTone.neutral ? null : view.tone),
        if (view.note != null) VibeSubLine(icon: 'info', text: view.note!),
        if (!view.hasPaymentData) ...[
          const SizedBox(height: 10),
          const VibeOkBox(
              strip: true,
              warning: true,
              title: 'Dados de pagamento indisponíveis. Consulte o suporte.'),
        ],
        const SizedBox(height: 9),
        identical(primary, details) ? details : VibeTwo(primary, details),
        if (links.isNotEmpty) ...[
          const SizedBox(height: 10),
          VibeLinkButtons(items: links),
        ],
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

/// Carregamento em blocos (`.g-load`).
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Semantics(
      label: 'Consultando suas faturas',
      child: Column(children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: t.ink.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ]),
    );
  }
}
