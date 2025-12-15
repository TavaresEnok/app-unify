import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../providers/providers.dart';
import '../models/app_user.dart';

class AuthState {
  final AppUser? user;
  final bool isSuperAdmin;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isSuperAdmin = false,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isSuperAdmin,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthRepository _repository;

  @override
  FutureOr<AuthState> build() async {
    _repository = ref.read(authRepositoryProvider);

    // Listen to stream for real-time updates
    final stream = _repository.authStateChanges;
    stream.listen((user) async {
      await _updateState(user);
    });

    // Check current user
    final initialUser = _repository.currentUser;
    if (initialUser != null) {
      final isAdmin = await _repository.isSuperAdmin(initialUser);
      return AuthState(user: initialUser, isSuperAdmin: isAdmin);
    }

    return const AuthState();
  }

  Future<void> _updateState(AppUser? user) async {
    if (user != null) {
      // Don't set loading here to avoid flicker on stream updates
      try {
        final isAdmin = await _repository.isSuperAdmin(user);
        state = AsyncValue.data(AuthState(user: user, isSuperAdmin: isAdmin));
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    } else {
      state = const AsyncValue.data(AuthState());
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signIn(email, password);
      // Listener will update state
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: 'Erro: $e'),
      );
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }
}
