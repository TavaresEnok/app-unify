import '../services/api_service.dart';

class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  Future<List<Map<String, dynamic>>> getUsers() async {
    return _apiService.getUsers();
  }
}
