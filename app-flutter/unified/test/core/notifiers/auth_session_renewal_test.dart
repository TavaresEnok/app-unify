import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/models/usuario.dart';
import 'package:app_provedor_unified/core/providers/configuration_provider.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/repositories/auth_repository.dart';
import 'package:app_provedor_unified/core/services/api_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _config = ProviderConfig(
  id: 'p',
  name: 'Provedor',
  apiUrl: 'https://api.test',
  config: ConfigSection(
    themeColor: '#000000',
    logoUrl: '',
    loginQuote: '',
    integrations: SgpIntegration(),
    faq: [],
    tips: [],
    supportContacts: [],
    imageCarousel: [],
  ),
  features: FeaturesSection(consumption: true, support: true),
  menuConfig: MenuConfig(order: [], items: {}),
);

Usuario _user(String status) => Usuario(
      cpfCnpj: '12345678900',
      senha: '',
      nome: 'Cliente',
      plano: 'Plano',
      status: status,
      valorFatura: '',
      vencimentoFatura: '',
    );

class _Config extends ConfigurationProvider {
  @override
  ProviderConfig get providerConfig => _config;
}

class _Repo extends AuthRepository {
  _Repo(this.answer);
  Object answer;
  int logins = 0;
  int logouts = 0;

  @override
  Future<Usuario?> loadUserFromStorage() async => _user('Online');

  @override
  Future<Usuario> performLoginApi(String cpf, ProviderConfig config) async {
    logins++;
    final a = answer;
    if (a is Usuario) return a;
    throw a;
  }

  @override
  Future<void> saveUserLocally(Usuario usuario, String providerId,
      {String? apiUrl}) async {}

  @override
  Future<void> rememberCpf(String cpf) async {}

  @override
  Future<void> logout(Usuario? currentUser, {String? apiUrl}) async {
    logouts++;
  }
}

Future<ProviderContainer> _start(_Repo repo) async {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repo),
    configurationProvider.overrideWith((_) => _Config()),
  ]);
  addTearDown(container.dispose);
  await container.read(authNotifierProvider.future);
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('401 renova a sessão com o CPF em vez de deslogar', () async {
    final repo = _Repo(_user('Renovado'));
    final container = await _start(repo);
    final before = repo.logins;
    ApiSession.onUnauthorized!();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repo.logins, before + 1);
    expect(repo.logouts, 0);
    expect(container.read(authNotifierProvider).value?.status, 'Renovado');
  });

  test('sem internet a conta continua aberta', () async {
    final repo = _Repo(Exception('offline'));
    final container = await _start(repo);
    ApiSession.onUnauthorized!();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repo.logouts, 0);
    expect(container.read(authNotifierProvider).value, isNotNull);
  });

  test('provedor recusou o CPF: volta ao login', () async {
    final repo = _Repo(const LoginRejectedException('Contrato encerrado'));
    final container = await _start(repo);
    ApiSession.onUnauthorized!();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repo.logouts, 1);
    expect(container.read(authNotifierProvider).value, isNull);
  });
}
