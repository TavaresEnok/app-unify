import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/provider_config.dart';
import '../repositories/auth_repository.dart';
import '../providers/providers.dart';

class AuthNotifier extends AsyncNotifier<Usuario?> {
  late final AuthRepository _repository;

  @override
  FutureOr<Usuario?> build() async {
    _repository = ref.read(authRepositoryProvider);
    return _loadUser();
  }

  Future<Usuario?> _loadUser() async {
    return await _repository.loadUserFromStorage();
  }

  Future<void> login(String cpf, ProviderConfig config) async {
    state = const AsyncValue.loading();
    try {
      // 1. Authenticate with API
      final user = await _repository.performLoginApi(cpf, config);

      // 2. Save locally
      await _repository.saveUserLocally(user);

      // 3. Update state
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    final currentUser = state.value;
    state = const AsyncValue.loading();
    try {
      await _repository.logout(currentUser);
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
      final updatedUser =
          await _repository.performLoginApi(currentUser.cpfCnpj, config);

      // Preserve some local-only fields if any (auth tokens are handled inside repository)

      await _repository.saveUserLocally(updatedUser);
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
