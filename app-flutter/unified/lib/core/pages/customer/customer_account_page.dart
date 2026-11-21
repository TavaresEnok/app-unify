import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../providers/history_count_provider.dart';
import '../../navigation/customer_routes.dart';
import '../../vibe/vibe_icon.dart';
import '../../vibe/vibe_page_parts.dart';
import '../../vibe/vibe_text.dart';
import '../../vibe/vibe_tokens.dart';
import '../../utils/app_formatters.dart';

/// Minha conta (`PG.conta` do layout aprovado): assinante, contrato,
/// avisos, histórico, serviços do provedor e saída da conta.
class CustomerAccountPage extends ConsumerStatefulWidget {
  final ValueChanged<String> onNavigate;
  const CustomerAccountPage({super.key, required this.onNavigate});

  @override
  ConsumerState<CustomerAccountPage> createState() =>
      _CustomerAccountPageState();
}

class _CustomerAccountPageState extends ConsumerState<CustomerAccountPage> {
  bool _confirmExit = false;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final config = ref.watch(configurationProvider).providerConfig;
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final unread = ref.watch(notificationProvider).unreadCount;
    bool can(String route) =>
        config == null || CustomerRoutes.enabled(config, route);
    final go = widget.onNavigate;
    final custom = config?.menuConfig.items.entries
            .where((e) => e.value.enabled && e.value.type != 'internal') ??
        [];
    final names = (user?.nome ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((n) => n.isNotEmpty)
        .toList();
    final initials = names.isEmpty
        ? '?'
        : (names.first.characters.first +
                (names.length > 1 ? names.last.characters.first : ''))
            .toUpperCase();
    final plan = AppFormatters.label(user?.plano);
    final contract = user?.contratoId;
    final suspended = user?.isSuspended == true;
    final status = user?.contractStatus?.trim();

    final rows = <Widget>[
      if (can('contract'))
        VibeRow(
            icon: 'doc',
            title: 'Meu contrato',
            subtitle: 'Plano, valor e vencimento',
            onTap: () => go('contract')),
      if (can('notifications'))
        VibeRow(
          icon: 'bell',
          title: 'Notificações',
          subtitle: unread == 0
              ? 'Tudo lido'
              : '$unread não lida${unread > 1 ? 's' : ''}',
          trailing: unread == 0
              ? null
              : Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color(0xFFD92D20),
                      borderRadius: BorderRadius.circular(11)),
                  child: Text('$unread',
                      style:
                          vibeText(t, 12, 800, color: Colors.white, height: 1)),
                ),
          onTap: () => go('notifications'),
        ),
      if (can('history'))
        VibeRow(
            icon: 'clock',
            title: 'Histórico de verificações',
            subtitle: diagnosticHistoryLabel(
                ref.watch(diagnosticHistoryCountProvider).valueOrNull),
            onTap: () => go('history')),
      if (can('achievements'))
        VibeRow(
            icon: 'g-trophy',
            title: 'Conquistas',
            subtitle: 'Seu progresso no aplicativo',
            onTap: () => go('achievements')),
    ];

    return VibePageScaffold(
      title: 'Minha conta',
      onBack: Navigator.of(context).canPop()
          ? () => Navigator.of(context).maybePop()
          : null,
      children: [
        VibeCard(
          main: true,
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: t.ac, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(initials,
                  style: vibeText(t, 15, 800, color: t.on, height: 1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        user == null
                            ? 'Minha conta'
                            : AppFormatters.personName(user.nome),
                        style: vibeText(t, 16, 700)),
                    if (plan.isNotEmpty || contract != null)
                      Text(
                          [
                            if (plan.isNotEmpty) plan,
                            if (contract != null) 'contrato $contract'
                          ].join(' · '),
                          style: vibeText(t, 12.5, 500, color: t.mut)),
                  ]),
            ),
            if (status?.isNotEmpty == true || suspended) ...[
              const SizedBox(width: 8),
              VibePageChip(
                  tone: suspended ? VibeTone.bad : VibeTone.ok,
                  label: suspended ? 'Suspenso' : status!),
            ],
          ]),
        ),
        if (rows.isNotEmpty) VibeCard(child: VibeRows(children: rows)),
        if (custom.isNotEmpty)
          VibeCard(
            child: VibeRows(children: [
              for (final entry in custom)
                VibeRow(
                  icon: 'gift',
                  title: entry.value.name,
                  subtitle: 'Serviço do provedor, abre fora do app',
                  trailing: VibeIcon('arr', size: 16, color: t.mut),
                  onTap: () => _openExternal(context, entry.value.url),
                ),
            ]),
          ),
        if (_confirmExit)
          VibeCard(
            main: true,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Sair da conta?', style: vibeText(t, 14, 700)),
                  const SizedBox(height: 4),
                  const VibeNote(
                      'Você vai precisar do CPF e da senha para entrar de novo.',
                      paragraph: true),
                  const SizedBox(height: 12),
                  VibeTwo(
                    VibePageButton(
                        label: 'Cancelar',
                        ghost: true,
                        onPressed: () => setState(() => _confirmExit = false)),
                    VibePageButton(
                        label: 'Sair',
                        danger: true,
                        onPressed: () => _logout(context)),
                  ),
                ]),
          )
        else
          VibePageButton(
              label: 'Sair da conta',
              icon: 'g-out',
              ghost: true,
              onPressed: () => setState(() => _confirmExit = true)),
      ],
    );
  }

  Future<void> _openExternal(BuildContext context, String? url) async {
    final uri = Uri.tryParse(url ?? '');
    try {
      if (uri != null &&
          ['https', 'http'].contains(uri.scheme) &&
          uri.host.isNotEmpty &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Mostra o aviso abaixo.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível abrir este serviço.')));
    }
  }

  Future<void> _logout(BuildContext context) async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
