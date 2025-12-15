import 'dart:async';
import '../services/api_service.dart';
import '../models/app_user.dart';

class AuthRepository {
  final ApiService _apiService;
  final _authStateController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  AuthRepository(this._apiService);

  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  AppUser? get currentUser => _currentUser;

  Future<void> signIn(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      // O backend retorna { token: ..., user: { uid, email } }
      // Assumindo que o Admin App só é acessível por SuperAdmins por enquanto,
      // ou que o backend validará isso.
      // O endpoint de login atual retorna: token, user: { uid, email }

      // TODO: Obter isSuperAdmin do backend ou assumir true para quem logou no admin
      // Por enquanto, vamos assumir true se logou com sucesso,
      // mas idealmente o backend deveria retornar "role".
      final userMap = response['user'] as Map<String, dynamic>;

      _currentUser = AppUser(
        uid: userMap['uid'],
        email: userMap['email'],
        isSuperAdmin: true, // Backend deve validar isso
      );

      _authStateController.add(_currentUser);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    _apiService.setToken(null);
    _currentUser = null;
    _authStateController.add(null);
  }

  Future<bool> isSuperAdmin(AppUser user) async {
    return user.isSuperAdmin;
  }
}
