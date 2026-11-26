import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/provider_config.dart';
import '../repositories/auth_repository.dart';
import '../services/account_data_cache.dart';
import '../services/api_response.dart';
import '../services/session_token_store.dart';
import '../providers/providers.dart';

class AuthNotifier extends AsyncNotifier<Usuario?> {
  late final AuthRepository _repository;

  @override
  FutureOr<Usuario?> build() async {
    _repository = ref.read(authRepositoryProvider);
    // 401 numa rota autenticada: sessão revogada no servidor. Volta ao login
    // em vez de deixar cada tela repetir o erro.
    // 401 numa rota autenticada (token vencido ou revogado): o login é só
    // pelo CPF, então o app renova a sessão sozinho. Só sai da conta quando
    // o assinante toca em Sair ou o provedor recusa o CPF.
    ApiSession.onUnauthorized = () {
      if (state.value != null && !state.isLoading) unawaited(renewSession());
    };
    final user = await _loadUser();
    if (user != null && await SessionTokenStore.instance.getToken() == null) {
      // Token vencido/ilegível: renova depois que a tela abrir.
      Future(renewSession);
    }
    return user;
  }

  Future<void>? _renewing;

  /// Novo token com o CPF guardado. Sem internet a conta continua aberta
  /// (com os dados em cache); se o provedor recusar o CPF, volta ao login.
  Future<void> renewSession() =>
      _renewing ??= _renew().whenComplete(() => _renewing = null);

  Future<void> _renew() async {
    final current = state.value;
    final config = ref.read(configurationProvider).providerConfig;
    if (current == null || config == null) return;
    try {
      final fresh = await _repository.performLoginApi(current.cpfCnpj, config);
      if (state.value == null) return;
      await _repository.saveUserLocally(fresh, config.id,
          apiUrl: config.apiUrl);
      state = AsyncValue.data(fresh);
    } on LoginRejectedException {
      if (state.value != null) await logout();
    } catch (e) {
      debugPrint('Sessão não renovada agora (tenta de novo depois): $e');
    }
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
      await _repository.rememberCpf(user.cpfCnpj);

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

  /// CPF do último login neste aparelho (entrar com a digital).
  Future<String?> rememberedCpf() =>
      ref.read(authRepositoryProvider).rememberedCpf();

  Future<void> forgetRememberedCpf() =>
      ref.read(authRepositoryProvider).forgetCpf();

  bool get isAuthenticated => state.value != null;
}
