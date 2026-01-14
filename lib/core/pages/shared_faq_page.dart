import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';

class FaqPage extends ConsumerWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configProvider = ref.watch(configurationProvider);
    final faqList = configProvider.providerConfig?.config.faq ?? [];
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    final layoutType = configProvider.providerConfig?.layoutType ?? 'layout_06';

    // Determinar se é layout escuro
    final isDarkLayout = layoutType == 'layout_04' ||
        layoutType == 'layout_05' ||
        layoutType == 'layout_06';

    // Cores de fundo por layout
    Color backgroundColor;
    switch (layoutType) {
      case 'layout_02':
        backgroundColor = const Color(0xFFF7FAFC); // Light gray
        break;
      case 'layout_03':
        backgroundColor = const Color(0xFFE8EEF5); // Neumorphic light
        break;
      case 'layout_04':
        backgroundColor = const Color(0xFF0A0A0A); // Obsidian dark
        break;
      case 'layout_05':
        backgroundColor = const Color(0xFF050810); // Cyber neon dark
        break;
      case 'layout_06':
      default:
        backgroundColor = const Color(0xFF0A0E21); // Clean dark
        break;
    }

    // Retorna apenas o conteúdo - PainelPage já fornece Scaffold e AppBar
    return Container(
      color: backgroundColor,
      child: configProvider.isLoading
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
                        // Layout 03 - Neumorphic style
                        final isLayout03 = layoutType == 'layout_03';
                        if (isLayout03) {
                          const neumorphicBg = Color(0xFFE8EEF5);
                          const neumorphicPrimary = Color(0xFF00D4FF);
                          const neumorphicTextDark = Color(0xFF2D3748);
                          const neumorphicTextGrey = Color(0xFF718096);
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              color: neumorphicBg,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  offset: const Offset(-6, -6),
                                  blurRadius: 12,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  offset: const Offset(6, 6),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              collapsedIconColor: neumorphicTextGrey,
                              iconColor: neumorphicPrimary,
                              leading: CircleAvatar(
                                backgroundColor:
                                    neumorphicPrimary.withValues(alpha: 0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: neumorphicPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                faqItem.question,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: neumorphicTextDark,
                                ),
                              ),
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(faqItem.answer,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: neumorphicTextGrey,
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
