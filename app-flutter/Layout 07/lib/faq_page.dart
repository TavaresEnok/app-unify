import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'configuration_provider.dart';
import 'shared/widgets/app_page.dart';
import 'shared/theme/app_colors.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigurationProvider>(context);
    final faqList = configProvider.providerConfig?.config.faq ?? [];
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return AppPage(
      title: "Perguntas Frequentes",
      isLoading: configProvider.isLoading,
      error: configProvider.errorMessage,
      onRetry: () => configProvider.loadConfig(providerId),
      body: faqList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.help_outline, size: 60, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    configProvider.isLoading ? 'Carregando...' : "Nenhuma pergunta frequente cadastrada.",
                    style: textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: faqList.length,
              itemBuilder: (context, index) {
                final faqItem = faqList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ExpansionTile(
                        collapsedBackgroundColor: AppColors.surface,
                        backgroundColor: AppColors.surface,
                        iconColor: primaryColor,
                        collapsedIconColor: AppColors.textSecondary,
                        title: Text(
                          faqItem.question, 
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary
                          )
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        children: [
                          Text(
                            faqItem.answer, 
                            style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary)
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
