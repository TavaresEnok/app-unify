import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'configuration_provider.dart';
import 'shared/widgets/app_page.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigurationProvider>(context);
    final faqList = configProvider.providerConfig?.config.faq ?? [];
    final textTheme = Theme.of(context).textTheme;

    return AppPage(
      title: "Perguntas Frequentes",
      isLoading: configProvider.isLoading,
      error: configProvider.errorMessage,
      onRetry: () => configProvider.loadConfig(providerId),
      body: faqList.isEmpty
          ? Center(
              child: Text(
                configProvider.isLoading ? 'Carregando...' : "Nenhuma pergunta frequente cadastrada.",
                style: textTheme.bodyMedium,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: faqList.length,
              itemBuilder: (context, index) {
                final faqItem = faqList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ExpansionTile(
                      collapsedBackgroundColor: Theme.of(context).colorScheme.surface,
                      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                      title: Text(faqItem.question, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Text(faqItem.answer, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
