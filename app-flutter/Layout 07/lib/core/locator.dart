import 'package:get_it/get_it.dart';
import '../models/provider_config.dart';
import '../services/login_service.dart';
import '../services/meu_ip_service.dart';
import '../services/suporte_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator(ProviderConfig config) {
  if (locator.isRegistered<ProviderConfig>()) {
    locator.unregister<ProviderConfig>();
  }
  locator.registerSingleton<ProviderConfig>(config);

  if (!locator.isRegistered<SuporteService>()) {
    locator.registerLazySingleton(() => SuporteService());
    locator.registerLazySingleton(() => MeuIpService());

    locator.registerFactoryParam<LoginService, String, String>((apiUrl, cpfCnpj) {
      final providerConfig = locator<ProviderConfig>();
      return LoginService(
        apiUrl: apiUrl,
        cpfCnpjUnformatted: cpfCnpj,
        sgpParams: {
          'token': providerConfig.config.integrations.apiToken,
          'app': providerConfig.config.integrations.appName,
          'sgpBaseUrl': providerConfig.config.integrations.sgpBaseUrl, // ADICIONADO
        },
      );
    });
  }

  print("✅ Localizador de Serviços (GetIt) configurado com a configuração do provedor!");
}
