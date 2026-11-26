import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/fatura.dart';
import '../navigation/customer_shell_scope.dart';
import '../providers/financeiro_provider.dart';
import '../providers/providers.dart';
import '../utils/app_formatters.dart';
import '../vibe/vibe_invoice.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

/// Abre a fatura informada (`PG.fatura` do layout aprovado).
Future<void> openSubscriberInvoice(BuildContext context, Fatura invoice) =>
    pushCustomerPage<void>(context,
        route: 'invoice', page: InvoiceDetailPage(invoice: invoice));

/// Abre a liberação por confiança (`PG.liberar`).
Future<void> openSubscriberTrustUnlock(BuildContext context) =>
    pushCustomerPage<void>(context,
        route: 'trust_unlock', page: const TrustUnlockPage());

bool _sameInvoice(Fatura a, Fatura b) =>
    a.numero == b.numero &&
    a.vencimento == b.vencimento &&
    a.valor == b.valor &&
    a.status == b.status &&
    a.pixCopiaECola == b.pixCopiaECola &&
    a.linhaDigitavel == b.linhaDigitavel &&
    a.urlBoleto == b.urlBoleto;

/// Detalhe da fatura: valor, situação, dados e formas de pagamento. Se a
/// consulta mudar os dados, as ações ficam bloqueadas até reabrir.
class InvoiceDetailPage extends ConsumerWidget {
  const InvoiceDetailPage({super.key, required this.invoice});

  final Fatura invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VibeTokens.of(context);
    final finance = ref.watch(financeiroViewModelProvider);
    // Dados na tela (consultados ou guardados) continuam usáveis enquanto
    // a atualização anda; só bloqueia se a fatura mudou de fato.
    final current = finance.hasResult &&
        finance.invoices.any((item) => _sameInvoice(item, invoice));
    final asOf = finance.isStale ? finance.lastUpdated : null;
    final plan =
        AppFormatters.label(ref.watch(authNotifierProvider).valueOrNull?.plano);
    final view = VibeInvoiceView(invoice);
    final year = DateFormat('yyyy').format(invoice.vencimento);
    VoidCallback? when(VoidCallback action) => current ? action : null;
    final paymentDate = invoice.dataPagamento;

    return VibePageScaffold(
      title: 'Fatura de ${view.month}',
      subtitle: view.paid ? 'Paga' : 'Pagamento fora do app',
      onBack: () => Navigator.of(context).maybePop(),
      children: [
        VibeCard(
          main: true,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: VibeLabel('Fatura de ${view.month} de $year')),
              VibePageChip(tone: view.tone, label: view.chip),
            ]),
            VibePageAmount(invoice.valor),
            VibeSubLine(
                icon: view.paid ? 'check' : 'cal',
                text: view.dueFull,
                tone: view.tone == VibeTone.neutral ? null : view.tone),
          ]),
        ),
        VibeCard(
          child: VibeKvList([
            if (plan.isNotEmpty) VibeKv('Plano', plan),
            VibeKv('Referência', '${view.monthTitle} de $year'),
            VibeKv('Número', invoice.numero),
            VibeKv('Vencimento', AppFormatters.date(invoice.vencimento)),
            if (view.paid && paymentDate != null)
              VibeKv('Pagamento', AppFormatters.date(paymentDate)),
            VibeKv('Total', AppFormatters.currency(invoice.valor)),
          ]),
        ),
        if (!current)
          const VibeOkBox(
              strip: true,
              warning: true,
              title:
                  'Os dados desta fatura foram atualizados ou estão sendo consultados. Volte e abra a fatura novamente.'),
        if (!view.paid && view.hasPix)
          VibePageButton(
              label: 'Copiar código Pix',
              icon: 'pix',
              onPressed: when(() =>
                  VibeInvoiceActions.copyPix(context, invoice, asOf: asOf))),
        if (!view.paid && view.hasLine)
          VibeCard(
            main: true,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VibeLabel('Linha digitável'),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 10),
                    child: current
                        ? SelectableText(invoice.linhaDigitavel!,
                            style: vibeMono(t.ink))
                        : Text('Disponível após atualizar a fatura',
                            style: vibeText(t, 12.5, 500, color: t.mut)),
                  ),
                  VibeTwo(
                    VibePageButton(
                        label: 'Copiar linha',
                        icon: 'copy',
                        ghost: true,
                        small: true,
                        onPressed: when(() => VibeInvoiceActions.copyLine(
                            context, invoice,
                            asOf: asOf))),
                    view.hasBoleto
                        ? VibePageButton(
                            label: 'Abrir boleto',
                            icon: 'bar',
                            ghost: true,
                            small: true,
                            onPressed: when(() => VibeInvoiceActions.openBoleto(
                                context, invoice)))
                        : const SizedBox.shrink(),
                  ),
                ]),
          ),
        // Fatura paga: o ERP não devolve mais o boleto (o link abre uma
        // página vazia), então o caminho é pedir o comprovante.
        if (view.hasBoleto && !view.paid && !view.hasLine)
          VibePageButton(
              label: 'Abrir boleto',
              icon: 'bar',
              ghost: true,
              onPressed:
                  when(() => VibeInvoiceActions.openBoleto(context, invoice))),
        if (view.paid)
          const VibeNote(
              'O boleto de faturas pagas não fica disponível. Peça o comprovante ao provedor.'),
        if (!view.paid && !view.hasPaymentData)
          const VibeOkBox(
              strip: true,
              warning: true,
              title:
                  'Boleto disponível na central do assinante ou com o suporte.'),
        if (!view.paid)
          const VibeNote(
              'O pagamento é feito no app do seu banco. Pelo Pix, a confirmação sai em minutos.'),
        if (view.overdue)
          VibeCard(
            child: VibeRow(
              icon: 'unlock',
              title: 'Liberar por confiança',
              subtitle: 'Peça a liberação enquanto o pagamento é confirmado',
              onTap: when(() => openSubscriberTrustUnlock(context)),
            ),
          ),
      ],
    );
  }
}

/// Liberação por confiança: a fatura vencida, as condições e o pedido.
class TrustUnlockPage extends ConsumerStatefulWidget {
  const TrustUnlockPage({super.key});

  @override
  ConsumerState<TrustUnlockPage> createState() => _TrustUnlockPageState();
}

enum _UnlockState { idle, sending, done }

class _TrustUnlockPageState extends ConsumerState<TrustUnlockPage> {
  _UnlockState _state = _UnlockState.idle;
  String? _error;

  Future<void> _request(Fatura invoice) async {
    final finance = ref.read(financeiroViewModelProvider);
    if (finance.isStale || finance.state == FinanceiroState.loading) {
      // O pedido vale para a situação confirmada pelo provedor.
      unawaited(finance.fetchHistory());
      setState(() => _error =
          'Confirmando suas faturas com o provedor. Tente de novo em instantes.');
      return;
    }
    final stillOverdue = finance.state == FinanceiroState.success &&
        finance.invoices
            .any((item) => _sameInvoice(item, invoice) && item.isVencido);
    if (!stillOverdue) {
      setState(() => _error = 'A fatura mudou. Consulte os dados novamente.');
      return;
    }
    final service = ref.read(financeiroServiceProvider);
    if (service == null) {
      setState(() => _error = 'Sessão indisponível. Entre novamente.');
      return;
    }
    setState(() {
      _state = _UnlockState.sending;
      _error = null;
    });
    try {
      await service.solicitarDesbloqueioConfianca();
      if (!mounted) return;
      setState(() => _state = _UnlockState.done);
      ref.read(financeiroViewModelProvider).fetchHistory();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _UnlockState.idle;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = ref.watch(financeiroViewModelProvider);
    final overdue = finance.invoices.where((i) => i.isVencido).toList()
      ..sort((a, b) => a.vencimento.compareTo(b.vencimento));
    final late = overdue.isEmpty ? null : VibeInvoiceView(overdue.first);
    final children = <Widget>[];
    if (!finance.hasResult && finance.state != FinanceiroState.error) {
      // Primeira consulta: o cartão real com os valores cobertos.
      children.addAll([
        Semantics(
          label: 'Consultando suas faturas',
          liveRegion: true,
          child: const VibeCard(
            main: true,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VibeNote(
                      'O provedor pode liberar a sua internet enquanto o pagamento não é confirmado. A disponibilidade depende das regras da sua conta.',
                      paragraph: true),
                  SizedBox(height: 4),
                  VibeKvList([
                    VibeKv('Fatura vencida', 'Novembro · R\$ 199,90',
                        redacted: true),
                    VibeKv('Vencimento', '10/11/2026', redacted: true),
                  ]),
                ]),
          ),
        ),
        const VibeDimmed(
          dimmed: true,
          child: VibePageButton(label: 'Solicitar liberação', onPressed: null),
        ),
      ]);
    } else if (finance.state == FinanceiroState.error && !finance.hasResult) {
      children.add(const VibeCard(
          child: VibeEmpty(
              icon: 'alert',
              title: 'Não foi possível consultar suas faturas',
              text: 'Tente novamente em Faturas.')));
    } else if (late == null) {
      children.add(VibeCard(
          child: VibeEmpty(
              icon: 'unlock',
              title: 'Disponível só para fatura vencida',
              text: finance.incompleteInvoices > 0
                  ? 'Algumas faturas estão incompletas. Consulte o suporte para verificar sua conexão.'
                  : 'Quando uma fatura vencer, você pode pedir a liberação aqui.')));
    } else if (_state == _UnlockState.done) {
      children.addAll([
        const VibeCard(
          main: true,
          child: VibeOkBox(
            title: 'Pedido de liberação enviado',
            text:
                'O provedor libera o acesso conforme as regras da sua conta. Pague a fatura para evitar um novo bloqueio.',
          ),
        ),
        if (late.hasPix)
          VibePageButton(
              label: 'Copiar Pix de ${late.month}',
              icon: 'pix',
              onPressed: () => VibeInvoiceActions.copyPix(context, late.invoice,
                  asOf: finance.isStale ? finance.lastUpdated : null)),
      ]);
    } else {
      children.addAll([
        VibeCard(
          main: true,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const VibeNote(
                'O provedor pode liberar a sua internet enquanto o pagamento não é confirmado. A disponibilidade depende das regras da sua conta.',
                paragraph: true),
            const SizedBox(height: 4),
            VibeKvList([
              VibeKv('Fatura vencida',
                  '${late.monthTitle} · ${AppFormatters.currency(late.invoice.valor)}'),
              VibeKv('Vencimento', AppFormatters.date(late.invoice.vencimento)),
            ]),
          ]),
        ),
        if (_error != null) VibeErrorLine(_error!),
        VibePageButton(
          label: _state == _UnlockState.sending
              ? 'Enviando pedido…'
              : 'Solicitar liberação',
          onPressed: _state == _UnlockState.sending
              ? null
              : () => _request(late.invoice),
        ),
        VibePageButton(
            label: 'Agora não',
            ghost: true,
            onPressed: () => Navigator.of(context).maybePop()),
      ]);
    }
    return VibePageScaffold(
      title: 'Liberação por confiança',
      subtitle: 'Fatura vencida',
      onBack: () => Navigator.of(context).maybePop(),
      children: children,
    );
  }
}
