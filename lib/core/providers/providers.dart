import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../services/review_service.dart';
import '../services/deep_link_service.dart';
import '../services/speed_test_history_service.dart';

import '../repositories/auth_repository.dart';
import '../notifiers/auth_notifier.dart';
import '../models/usuario.dart';
import 'configuration_provider.dart';
import 'theme_provider.dart';
import '../models/theme_config.dart';

// --- Services & Config ---

/// Gerencia a configuração remota do provedor (Firestore/Cache)
final configurationProvider =
    ChangeNotifierProvider<ConfigurationProvider>((ref) {
  return ConfigurationProvider();
});

// --- REPOSITORIES ---
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// --- NOTIFIERS (Async) ---
// Substitui AuthService e authProvider
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, Usuario?>(
  () => AuthNotifier(),
);

// --- PROVIDERS (Legacy/Adapters) ---

// Manteve-se o nome authProvider se necessário para compatibilidade,
// ou idealmente, removeremos o antigo.
// Por enquanto, comentamos o antigo AuthService.

/// Gerencia notificações in-app
final notificationProvider = ChangeNotifierProvider<NotificationService>((ref) {
  return NotificationService();
});

// --- UI & Theme ---

/// Gerencia o tema dinâmico e o modo escuro
/// Observa o configurationProvider para atualizar as cores automaticamente
final themeProvider = ChangeNotifierProvider<DynamicThemeProvider>((ref) {
  final themeNotifer = DynamicThemeProvider();

  // Escuta mudanças na configuração para atualizar o tema em tempo real
  ref.listen<ConfigurationProvider>(configurationProvider, (previous, next) {
    final providerConfig = next.providerConfig;
    if (providerConfig == null) return;

    try {
      ThemeConfig config;

      // Se temos um tema definido no formato completo, usamos ele
      // Se temos um tema definido no formato completo, usamos ele,
      // MAS precisamos garantir que as novas configs (background/icon) tenham prioridade ou sejam mescladas
      // se elas não existirem no themeMap (ou se quisermos forçar a config nova).

      final themeMap = providerConfig.theme;
      final configColors = providerConfig.config;

      if (themeMap != null && themeMap.isNotEmpty) {
        debugPrint('🎨 [DEBUG] Usando themeMap completo (com overrides)');

        // Vamos injetar os valores novos se eles não estiverem explicitamente no themeMap
        // (Ou forçar se a estratégia for "Config manda")
        // Como o Admin Novo salva na Config, vamos garantir que a Config seja respeitada para esses campos novos.

        var effectiveThemeMap = Map<String, dynamic>.from(themeMap);

        // Garante estrutura colors
        if (!effectiveThemeMap.containsKey('colors')) {
          effectiveThemeMap['colors'] = <String, dynamic>{};
        }
        var colorsMap = Map<String, dynamic>.from(effectiveThemeMap['colors']);

        // Garante estrutura effects
        if (!effectiveThemeMap.containsKey('effects')) {
          effectiveThemeMap['effects'] = <String, dynamic>{};
        }
        var effectsMap =
            Map<String, dynamic>.from(effectiveThemeMap['effects']);

        // Overrides
        // Primary and Secondary colors from Admin config
        colorsMap['primary'] = configColors.themeColor;
              if (configColors.secondaryColor != null) {
          colorsMap['secondary'] = configColors.secondaryColor;
        }
        if (configColors.backgroundColor != null) {
          colorsMap['background'] = configColors.backgroundColor;
        }
        if (configColors.iconColor != null) {
          effectsMap['iconColor'] = configColors.iconColor;
        }
        if (configColors.cardColor != null) {
          colorsMap['surface'] = configColors.cardColor;
        }
        if (configColors.textColor != null) {
          colorsMap['textPrimary'] = configColors.textColor;
        }
        if (configColors.textSecondaryColor != null) {
          colorsMap['textSecondary'] =
              configColors.textSecondaryColor; // [NEW] Secondary Text
        }
        if (configColors.quickActionsCardColor != null) {
          colorsMap['quickActionsCardColor'] =
              configColors.quickActionsCardColor; // [NEW] Quick Actions
        }
        if (configColors.otherCardsColor != null) {
          colorsMap['otherCardsColor'] =
              configColors.otherCardsColor; // [NEW] Other Cards
        }
        if (configColors.quickActionsTextColor != null) {
          colorsMap['quickActionsTextColor'] =
              configColors.quickActionsTextColor; // [NEW] Quick Actions Text
        }
        if (configColors.otherCardsTextColor != null) {
          colorsMap['otherCardsTextColor'] =
              configColors.otherCardsTextColor; // [NEW] Other Cards Text
        }

        effectiveThemeMap['colors'] = colorsMap;
        effectiveThemeMap['effects'] = effectsMap;

        config = ThemeConfig.fromJson(effectiveThemeMap);
      } else {
        // Caso contrário, criamos um ThemeConfig usando as cores simples
        // do ConfigSection (themeColor, secondaryColor)
        final themeColor = configColors.themeColor;
        final secondaryColor = configColors.secondaryColor ?? themeColor;
        // [NEW] Use configurable colors
        final cardColor = configColors.cardColor;
        final textColor = configColors.textColor;
        final textSecondaryColor = configColors.textSecondaryColor; // [NEW]
        final backgroundColor =
            configColors.backgroundColor; // Load background color
        final iconColor = configColors.iconColor; // [NEW]
        final quickActionsCardColor =
            configColors.quickActionsCardColor; // [NEW]
        final quickActionsTextColor =
            configColors.quickActionsTextColor; // [NEW]
        final otherCardsColor = configColors.otherCardsColor; // [NEW]
        final otherCardsTextColor = configColors.otherCardsTextColor; // [NEW]

        debugPrint(
            '🎨 [DEBUG] Criando tema com themeColor=$themeColor, secondaryColor=$secondaryColor');

        config = ThemeConfig.fromJson({
          'colors': {
            'primary': themeColor,
            'secondary': secondaryColor,
            if (cardColor != null) 'surface': cardColor,
            if (textColor != null) 'textPrimary': textColor,
            if (textSecondaryColor != null)
              'textSecondary': textSecondaryColor, // [NEW]
            if (quickActionsCardColor != null)
              'quickActionsCardColor': quickActionsCardColor, // [NEW]
            if (otherCardsColor != null)
              'otherCardsColor': otherCardsColor, // [NEW]
            if (quickActionsTextColor != null)
              'quickActionsTextColor': quickActionsTextColor, // [NEW]
            if (otherCardsTextColor != null)
              'otherCardsTextColor': otherCardsTextColor, // [NEW]
            // Default mappings for other colors using primary/secondary if not specified
            'error': '#EF4444',
            'success': '#10B981',
            'warning': '#F59E0B',
            'info': '#3B82F6',
            'background': backgroundColor ??
                (configColors.other?.useBackgroundImage == true
                    ? '#00000000' // If using bg image, transparent
                    : '#0F172A'),
          },
          // [NEW] Map icon color if present, otherwise default to primary
          if (iconColor != null)
            'effects': {
              'iconColor': iconColor,
            }
        });
      }

      // Evita updates desnecessários se a config for idêntica
      if (themeNotifer.config != config) {
        final layoutType = providerConfig.layoutType;
        debugPrint(
            '🎨 [DEBUG] Atualizando tema! primary=${config.colors.primary}, layout=$layoutType');
        themeNotifer.updateFromConfig(config, layoutType: layoutType);
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao atualizar tema via Provider: $e');
    }
  });

  return themeNotifer;
});

// ANALYTICS & ENGAGEMENT
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});

final speedTestHistoryServiceProvider =
    ChangeNotifierProvider<SpeedTestHistoryService>((ref) {
  return SpeedTestHistoryService();
});
