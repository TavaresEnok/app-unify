import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/provider_config.dart';
import '../repositories/auth_repository.dart';
import '../services/account_data_cache.dart';
import '../services/api_response.dart';
import '../providers/providers.dart';

class AuthNotifier extends AsyncNotifier<Usuario?> {
  late final AuthRepository _repository;

  @override
  FutureOr<Usuario?> build() async {
    _repository = ref.read(authRepositoryProvider);
    // 401 numa rota autenticada: sessão revogada no servidor. Volta ao login
    // em vez de deixar cada tela repetir o erro.
    ApiSession.onUnauthorized = () {
      if (state.value != null && !state.isLoading) unawaited(logout());
    };
    return _loadUser();
  }

  Future<Usuario?> _loadUser() async {
    final user = await _repository.loadUserFromStorage();
    final config = ref.read(configurationProvider).providerConfig;
    if (user != null && config != null) {
      await ref.read(notificationProvider).setAccount(config.id, user.cpfCnpj);
    } else {
      ref.read(notificationProvider).clearAccount();
    }
    return user;
  }

  Future<void> login(String cpf, ProviderConfig config) async {
    // DO NOT set state = const AsyncValue.loading() here!
    // It causes AuthGate to unmount the LoginPage, destroying local state and hiding errors.
    try {
      // 1. Authenticate with API
      final user = await _repository.performLoginApi(cpf, config);

      // 2. Save locally
      await _repository.saveUserLocally(user, config.id, apiUrl: config.apiUrl);

      await ref.read(notificationProvider).setAccount(config.id, user.cpfCnpj);

      // 3. Update state
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    final currentUser = state.value;
    final apiUrl = ref.read(configurationProvider).providerConfig?.apiUrl;
    state = const AsyncValue.loading();
    ref.read(notificationProvider).clearAccount();
    // Faturas e consumo guardados no aparelho são da conta que saiu.
    unawaited(AccountDataCache.instance.clear());
    try {
      await _repository.logout(currentUser, apiUrl: apiUrl);
      state = const AsyncValue.data(null);
    } catch (e) {
      // Even if API logout fails, we clear state to ensure user can "exit"
      state = const AsyncValue.data(null);
    }
  }

  /// Refreshes user data from API silently
  Future<void> refreshUserData(ProviderConfig config) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    try {
      // Re-authenticate to get fresh data (balance, status, etc)
      // Note: We use the stored CPF. Ideally we should have a 'refresh' endpoint,
      // but 'performLoginApi' works as a fetch-latest-data call.

      // We don't set state to loading to avoid flickering UI,
      // just update when data arrives.
      final updatedUser = await _repository.refreshUser(currentUser, config);

      // Preserve some local-only fields if any (auth tokens are handled inside repository)

      await _repository.saveUserLocally(updatedUser, config.id,
          apiUrl: config.apiUrl);
      state = AsyncValue.data(updatedUser);
    } catch (e) {
      debugPrint('Erro ao atualizar dados do usuário em background: $e');
      // Do not change state to error, keep showing cached data
    }
  }

  // Biometry helpers exposed via repository but manageable here if needed
  Future<Map<String, String>?> getBiometrics() =>
      _repository.getCredentialsForBiometry();

  Future<void> clearBiometrics() => _repository.clearBiometryCredentials();

  bool get isAuthenticated => state.value != null;
}
