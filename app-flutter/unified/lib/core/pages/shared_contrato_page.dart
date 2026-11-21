import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_formatters.dart';
import '../vibe/vibe_page_parts.dart';

/// Meu contrato (`PG.contrato` do layout aprovado): dados somente para
/// consulta e o caminho para falar com o provedor.
class ContratoPage extends ConsumerWidget {
  final ValueChanged<String>? onNavigate;
  const ContratoPage({super.key, this.onNavigate});

  String _maskedDocument(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11) {
      return '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';
    }
    if (digits.length == 14) {
      return '**.${digits.substring(2, 5)}.${digits.substring(5, 8)}/****-**';
    }
    return 'Não informado';
  }

  /// O contrato vence todo mês no mesmo dia: "20/11/2026" → "Todo dia 20".
  /// O contrato vence todo mês no mesmo dia: "20/11/2026", "Vence em
  /// 6/11/2026" ou "2026-11-06" viram "Todo dia 20" / "Todo dia 6".
  static String dueDay(String value) {
    final match = RegExp(r'(?<!\d)(\d{1,2})/\d{1,2}(?:/\d{2,4})?(?!\d)')
            .firstMatch(value) ??
        RegExp(r'\d{4}-\d{2}-(\d{2})').firstMatch(value);
    final day = int.tryParse(match?.group(1) ?? '');
    return day == null || day < 1 || day > 31 ? value.trim() : 'Todo dia $day';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider).providerConfig;
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final navigator = Navigator.of(context);
    final back = navigator.canPop() ? () => navigator.maybePop() : null;
    final name = config?.name.trim() ?? '';
    if (user == null) {
      return VibePageScaffold(
        title: 'Meu contrato',
        subtitle: 'Somente consulta',
        onBack: back,
        children: const [
          VibeCard(
            child: VibeEmpty(
                icon: 'user',
                title: 'Dados do contrato indisponíveis',
                text: 'Entre novamente para consultar seu contrato.'),
          ),
        ],
      );
    }
    String shown(String value) =>
        value.trim().isEmpty ? 'Não informado' : value;
    final hasAmount = user.valorFatura.trim().isNotEmpty &&
        user.valorFatura
            .replaceAll(RegExp(r'[^0-9]'), '')
            .contains(RegExp(r'[1-9]'));
    final cnpj = user.cpfCnpj.replaceAll(RegExp(r'[^0-9]'), '').length == 14;
    return VibePageScaffold(
      title: 'Meu contrato',
      subtitle: 'Somente consulta',
      onBack: back,
      children: [
        VibeCard(
          child: VibeKvList([
            VibeKv('Titular', shown(AppFormatters.personName(user.nome))),
            VibeKv(cnpj ? 'CNPJ' : 'CPF', _maskedDocument(user.cpfCnpj)),
            VibeKv('Plano', shown(AppFormatters.label(user.plano))),
            VibeKv('Situação', shown(user.contractStatus ?? '')),
            if (user.contratoId != null)
              VibeKv('Contrato', '${user.contratoId}'),
            if (hasAmount)
              VibeKv('Valor mensal', AppFormatters.currency(user.valorFatura)),
            if (user.vencimentoFatura.trim().isNotEmpty)
              VibeKv('Vencimento', dueDay(user.vencimentoFatura)),
            if (name.isNotEmpty) VibeKv('Provedor', name),
          ]),
        ),
        if (onNavigate != null) ...[
          VibeNote(name.isEmpty
              ? 'Para alterar dados de cadastro ou trocar de plano, fale com o seu provedor.'
              : 'Para alterar dados de cadastro ou trocar de plano, fale com a $name.'),
          VibePageButton(
              label:
                  name.isEmpty ? 'Falar com o provedor' : 'Falar com a $name',
              ghost: true,
              onPressed: () => onNavigate!('support')),
        ],
      ],
    );
  }
}
