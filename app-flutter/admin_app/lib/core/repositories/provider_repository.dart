import '../services/api_service.dart';
import '../models/provider_model.dart';

class ProviderRepository {
  final ApiService _apiService;

  ProviderRepository(this._apiService);

  Future<List<ProviderModel>> getProviders() async {
    return _apiService.getProviders();
  }

  Future<void> saveProvider(ProviderModel provider) async {
    await _apiService.saveProvider(provider);
  }

  // TODO: Add getProvider(id), deleteProvider(id) if API supports it
}
