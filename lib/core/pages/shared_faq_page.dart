import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../layouts/layout_03/theme.dart';

class FaqPage extends ConsumerWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configProvider = ref.watch(configurationProvider);
    final faqList = configProvider.providerConfig?.config.faq ?? [];
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    final layoutType = configProvider.providerConfig?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06';

    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
      appBarColor = theme.primaryColor;
      appBarTextColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Perguntas Frequentes',
            style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarTextColor),
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
                        if (isDarkLayout) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF3A3A3C)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              collapsedIconColor: const Color(0xFF8E8E93),
                              iconColor: primaryColor,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF3A3A3C),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                faqItem.question,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              children: [
                                const Divider(color: Color(0xFF3A3A3C)),
                                const SizedBox(height: 8),
                                Text(faqItem.answer,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF8E8E93),
                                    )),
                              ],
                            ),
                          );
                        }
                        if (isLayout05) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: Layout03Theme.neumorphicDecoration,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              collapsedIconColor: Layout03Theme.textGrey,
                              iconColor: Layout03Theme.primary,
                              leading: CircleAvatar(
                                backgroundColor: Layout03Theme.primary
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Layout03Theme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                faqItem.question,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Layout03Theme.textDark,
                                ),
                              ),
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(faqItem.answer,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Layout03Theme.textGrey,
                                    )),
                              ],
                            ),
                          );
                        }
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
                                backgroundColor:
                                    primaryColor.withValues(alpha: 0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: primaryColor,
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
