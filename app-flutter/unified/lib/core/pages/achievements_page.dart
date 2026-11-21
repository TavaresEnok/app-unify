import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/financeiro_provider.dart';
import '../providers/providers.dart';
import '../services/subscriber_achievements.dart';
import '../vibe/vibe_icon.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  String? _identity;
  Future<Map<String, DateTime>>? _events;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider).providerConfig;
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final identity = '${config?.id}:${user?.cpfCnpj}';
    if (_identity != identity && config != null && user != null) {
      _identity = identity;
      _events = SubscriberAchievements.load(config.id, user.cpfCnpj);
    }
    final finance = ref.watch(financeiroViewModelProvider);
    final onTime = finance.invoices.where((invoice) {
          final paid = invoice.dataPagamento;
          if (!invoice.isPago || paid == null) return false;
          return !DateTime(paid.year, paid.month, paid.day).isAfter(DateTime(
              invoice.vencimento.year,
              invoice.vencimento.month,
              invoice.vencimento.day));
        }).length >=
        3;
    return FutureBuilder<Map<String, DateTime>>(
      future: _events,
      builder: (context, snapshot) {
        final events = snapshot.data ?? {};
        final first = events[AchievementEvent.firstAccess.name];
        final veteran = first != null &&
            !DateTime.now()
                .isBefore(DateTime(first.year + 1, first.month, first.day));
        final badges = <(String, String, String, bool)>[
          ('g-star', 'Primeiro acesso', 'Entrou no app', user != null),
          (
            'pulse',
            'Detetive da rede',
            'Fez uma verificação',
            events.containsKey(AchievementEvent.diagnostic.name)
          ),
          (
            'gauge',
            'Velocista',
            'Fez um teste de velocidade',
            events.containsKey(AchievementEvent.speed.name)
          ),
          ('check', 'Em dia', 'Pagou 3 faturas no prazo', onTime),
          (
            'wifi',
            'Wi-Fi sob controle',
            'Alterou a rede',
            events.containsKey(AchievementEvent.wifi.name)
          ),
          (
            'g-route',
            'Explorador',
            'Usou a rota da rede',
            events.containsKey(AchievementEvent.trace.name)
          ),
          (
            'bell',
            'Bem informado',
            'Leu todos os avisos',
            events.containsKey(AchievementEvent.noticesRead.name)
          ),
          ('g-trophy', 'Veterano', 'Um ano de assinatura no app', veteran),
        ];
        final count = badges.where((item) => item.$4).length;
        final t = VibeTokens.of(context);
        return VibePageScaffold(
          title: 'Conquistas',
          subtitle: '$count de ${badges.length}',
          onBack: Navigator.of(context).canPop()
              ? () => Navigator.of(context).maybePop()
              : null,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else ...[
              VibeCard(
                  main: true,
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                          child: Text('Seu progresso',
                              style: vibeText(t, 14, 700))),
                      Text('${(count / badges.length * 100).round()}%',
                          style: vibeText(t, 14, 700))
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: count / badges.length,
                            minHeight: 8,
                            backgroundColor: t.line,
                            valueColor: AlwaysStoppedAnimation(t.ac))),
                  ])),
              LayoutBuilder(builder: (context, constraints) {
                final single = constraints.maxWidth < 250 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.4;
                final width = single
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2;
                return Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final badge in badges)
                    SizedBox(width: width, child: _Badge(item: badge)),
                ]);
              }),
            ],
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.item});
  final (String, String, String, bool) item;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return VibeCard(
        main: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: item.$4
                      ? t.ac.withValues(alpha: .15)
                      : t.ink.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(14)),
              child:
                  VibeIcon(item.$1, color: item.$4 ? t.at : t.mut, size: 22)),
          const SizedBox(height: 10),
          Text(item.$2,
              style: vibeText(t, 14, 750, color: item.$4 ? t.ink : t.mut)),
          const SizedBox(height: 4),
          Text(item.$4 ? item.$3 : 'Ainda não registrada',
              style: vibeText(t, 12, 500, color: t.mut)),
        ]));
  }
}
