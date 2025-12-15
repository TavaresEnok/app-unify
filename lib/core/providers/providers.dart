import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
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
    // Se a configuração mudou e temos um tema definido
    final themeMap = next.providerConfig?.theme;
    if (themeMap != null) {
      try {
        final config = ThemeConfig.fromJson(themeMap);

        // Evita updates desnecessários se a config for idêntica
        if (themeNotifer.config != config) {
          themeNotifer.updateFromConfig(config);
        }
      } catch (e) {
        print('⚠️ Erro ao atualizar tema via Provider: $e');
      }
    }
  });

  return themeNotifer;
});
