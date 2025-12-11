import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/configuration_provider.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigurationProvider>(context);
    final faqList = configProvider.providerConfig?.config.faq ?? [];
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perguntas Frequentes'),
      ),
      body: configProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : configProvider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text(configProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge),
                      ],
                    ),
                  ),
                )
              : faqList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.help_outline,
                              size: 64, color: textTheme.bodySmall?.color),
                          const SizedBox(height: 16),
                          Text(
                            "Nenhuma pergunta frequente cadastrada.",
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: faqList.length,
                      itemBuilder: (context, index) {
                        final faqItem = faqList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                faqItem.question,
                                style: textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(faqItem.answer,
                                    style: textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
