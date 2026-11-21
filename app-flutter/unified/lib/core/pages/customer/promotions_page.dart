import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/provider_config.dart';
import '../../providers/providers.dart';
import '../../services/customer_contact_launcher.dart';
import '../../vibe/vibe_icon.dart';
import '../../vibe/vibe_page_parts.dart';
import '../../vibe/vibe_text.dart';
import '../../vibe/vibe_tokens.dart';

class PromotionsPage extends ConsumerWidget {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotions = ref
            .watch(configurationProvider)
            .providerConfig
            ?.config
            .promotions
            .activePromotions ??
        const <Promotion>[];
    return VibePageScaffold(
      title: 'Ofertas',
      subtitle: 'Do seu provedor',
      onBack: Navigator.of(context).canPop()
          ? () => Navigator.of(context).maybePop()
          : null,
      children: [
        if (promotions.isEmpty)
          const VibeCard(
              child: VibeEmpty(
                  icon: 'gift',
                  title: 'Nenhuma oferta disponível',
                  text: 'As ofertas do provedor aparecem aqui.'))
        else
          VibeCard(
              child: VibeRows(children: [
            for (final promotion in promotions)
              VibeRow(
                  icon: 'gift',
                  title: promotion.title,
                  subtitle: promotion.description.isEmpty
                      ? null
                      : promotion.description,
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              PromotionDetailsPage(promotion: promotion)))),
          ])),
      ],
    );
  }
}

class PromotionDetailsPage extends ConsumerWidget {
  final Promotion promotion;
  const PromotionDetailsPage({super.key, required this.promotion});

  Future<void> _openOffer(BuildContext context, Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível abrir a oferta. Tente novamente.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider).providerConfig;
    final link = Uri.tryParse(promotion.link);
    final hasLink = link != null &&
        (link.scheme == 'https' || link.scheme == 'http') &&
        link.host.isNotEmpty;
    final contacts =
        config?.config.supportContacts ?? const <SupportContactItem>[];
    final contact =
        contacts.where((item) => customerContactUri(item) != null).firstOrNull;
    final t = VibeTokens.of(context);
    return VibePageScaffold(
      title: promotion.title,
      subtitle: config?.name.isNotEmpty == true
          ? 'Oferta de ${config!.name}'
          : 'Oferta do provedor',
      onBack: () => Navigator.of(context).maybePop(),
      children: [
        VibeCard(
            main: true,
            center: true,
            child: Column(children: [
              if (promotion.imageUrl.isNotEmpty)
                ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(promotion.imageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _offerIcon(t)))
              else
                _offerIcon(t),
              const SizedBox(height: 14),
              if (promotion.badge.isNotEmpty) ...[
                Center(
                    child: VibePageChip(
                        label: promotion.badge, tone: VibeTone.neutral)),
                const SizedBox(height: 8),
              ],
              Text(promotion.title,
                  textAlign: TextAlign.center,
                  style: vibeText(t, 19, 800, letterSpacingEm: -.01)),
              if (promotion.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(promotion.description,
                    textAlign: TextAlign.center,
                    style: vibeText(t, 14, 500, color: t.mut, height: 1.45)),
              ],
              if (promotion.endDate != null) ...[
                const SizedBox(height: 12),
                Text(
                    'Disponível até ${promotion.endDate!.day.toString().padLeft(2, '0')}/${promotion.endDate!.month.toString().padLeft(2, '0')}/${promotion.endDate!.year}',
                    style: vibeText(t, 12, 500, color: t.mut)),
              ],
            ])),
        if (hasLink)
          VibePageButton(
              label: 'Tenho interesse',
              onPressed: () => _openOffer(context, link))
        else if (contact != null)
          VibePageButton(
              label: 'Falar com o provedor',
              onPressed: () => openCustomerContact(context, contact,
                  message:
                      'Olá! Tenho interesse na oferta ${promotion.title}.'))
        else
          const VibeNote('Fale com o seu provedor para saber mais.',
              center: true),
      ],
    );
  }

  Widget _offerIcon(VibeTokens t) => Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration:
          BoxDecoration(color: t.hero, borderRadius: BorderRadius.circular(24)),
      child: VibeIcon('gift', color: t.hx, size: 38));
}
