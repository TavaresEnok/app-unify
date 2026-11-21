import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/customer_contact_launcher.dart';

import '../../models/provider_config.dart';
import '../../providers/providers.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Promoções')),
      body: promotions.isEmpty
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nenhuma promoção disponível no momento.',
                      textAlign: TextAlign.center)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: promotions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final promotion = promotions[index];
                return Card(
                    child: ListTile(
                  title: Text(promotion.title),
                  subtitle: promotion.description.isEmpty
                      ? null
                      : Text(promotion.description,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              PromotionDetailsPage(promotion: promotion))),
                ));
              },
            ),
    );
  }
}

class PromotionDetailsPage extends ConsumerWidget {
  final Promotion promotion;
  const PromotionDetailsPage({super.key, required this.promotion});

  Future<void> _openOffer(BuildContext context, Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Report launch failures in the same way as an unavailable handler.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível abrir a oferta. Tente novamente.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = Uri.tryParse(promotion.link);
    final hasLink = link != null &&
        (link.scheme == 'https' || link.scheme == 'http') &&
        link.host.isNotEmpty;
    final contacts = ref
            .watch(configurationProvider)
            .providerConfig
            ?.config
            .supportContacts ??
        const <SupportContactItem>[];
    final contact =
        contacts.where((item) => customerContactUri(item) != null).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Promoção')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (promotion.imageUrl.isNotEmpty) ...[
          ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(promotion.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          const SizedBox(height: 20),
        ],
        if (promotion.badge.isNotEmpty)
          Text(promotion.badge,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(promotion.title, style: Theme.of(context).textTheme.headlineSmall),
        if (promotion.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(promotion.description),
        ],
        if (promotion.endDate != null) ...[
          const SizedBox(height: 16),
          Text(
              'Disponível até ${promotion.endDate!.day.toString().padLeft(2, '0')}/${promotion.endDate!.month.toString().padLeft(2, '0')}/${promotion.endDate!.year}'),
        ],
        const SizedBox(height: 24),
        if (hasLink)
          FilledButton(
              onPressed: () => _openOffer(context, link),
              child: const Text('Tenho interesse'))
        else if (contact != null)
          FilledButton(
              onPressed: () => openCustomerContact(context, contact,
                  message:
                      'Olá! Tenho interesse na oferta ${promotion.title}.'),
              child: const Text('Falar com o provedor'))
        else
          const Text('Entre em contato com seu provedor para saber mais.'),
      ]),
    );
  }
}
