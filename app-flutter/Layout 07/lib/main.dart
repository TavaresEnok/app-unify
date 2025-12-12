import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import para inicialização de locale
import 'firebase_options.dart';
import 'login_page.dart';
import 'painel.dart';
import 'local_notification_service.dart';
import 'models/provider_config.dart';
import 'configuration_provider.dart';
import 'providers/theme_provider.dart';
import 'models/theme_config.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'core/locator.dart';

const String providerId = 'vibe';

// Função para tratar mensagens em background (quando o app está fechado)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;
  AppConfigService._internal();
  Map<String, dynamic>? providerConfig;

  Future<void> initialize() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('provedores')
          .doc(providerId)
          .get(const GetOptions(source: Source.server));
      if (doc.exists) {
        providerConfig = doc.data();
        print(
            "✅ Configuração do provedor '$providerId' carregada diretamente do SERVIDOR.");
      } else {
        throw Exception("Provedor '$providerId' não encontrado.");
      }
    } catch (e) {
      print("❌ ERRO FATAL ao carregar configuração: $e");
      rethrow;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Locale do intl
  await initializeDateFormatting('pt_BR', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar Analytics
  await AnalyticsService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfigurationProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProxyProvider<ConfigurationProvider,
            DynamicThemeProvider>(
          create: (_) => DynamicThemeProvider(),
          update: (_, configProvider, themeProvider) {
            final themeConfig = configProvider.providerConfig?.theme;
            if (themeConfig != null && themeProvider != null) {
              try {
                final config = ThemeConfig.fromJson(themeConfig);
                if (themeProvider.config != config) {
                  themeProvider.updateFromConfig(config);
                }
              } catch (e) {
                print('Erro ao processar tema: $e');
              }
            }
            return themeProvider ?? DynamicThemeProvider();
          },
        ),
      ],
      child: const AppContent(),
    );
  }
}

class AppContent extends StatefulWidget {
  const AppContent({super.key});

  @override
  State<AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<AppContent> {
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  Future<void> _initializeApp() async {
    LocalNotificationService.initialize();
    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('✅ Mensagem recebida em primeiro plano!');
      LocalNotificationService.showNotification(message);
    });

    // Inicializa AppConfigService (legado/existente)
    await AppConfigService().initialize();

    // Inicializa o Service Locator
    final configMap = AppConfigService().providerConfig!;
    final providerConfig = ProviderConfig.fromJson(configMap, providerId);
    setupLocator(providerConfig);

    // Carregar configuração no Provider também (para o tema)
    if (mounted) {
      await Provider.of<ConfigurationProvider>(context, listen: false)
          .loadConfig(providerId);

      // Carregar notificações
      await Provider.of<NotificationService>(context, listen: false)
          .loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DynamicThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Layout 07',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder(
              future: _initialization,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return FatalErrorScreen(error: snapshot.error.toString());
                if (snapshot.connectionState == ConnectionState.done)
                  return const AuthGate();
                return const SplashScreen();
              },
            ),
        '/login': (context) => const AuthGate(),
        '/painel': (context) => FutureBuilder(
              future: _initialization,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SplashScreen();
                }
                // Navega para PainelPage assim que estiver pronto
                return Consumer<AuthService>(
                  builder: (context, authService, _) {
                    if (authService.usuario != null) {
                      return PainelPage(
                        cpfCnpj: authService.usuario!.cpfCnpj,
                        senha: authService.usuario!.senha,
                        content: authService.usuario!.nome,
                        plano: authService.usuario!.plano,
                        status: authService.usuario!.status,
                        valorFatura: authService.usuario!.valorFatura,
                        vencimentoFatura: authService.usuario!.vencimentoFatura,
                      );
                    }
                    return const AuthGate();
                  },
                );
              },
            ),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _userCpfCnpj,
      _userSenha,
      _userName,
      _userPlan,
      _userStatus,
      _billValue,
      _billDueDate;
  void _handleLoginSuccess(String cpf, String s, String name, String plan,
      String status, String bill, String due) {
    setState(() {
      _userCpfCnpj = cpf;
      _userSenha = s;
      _userName = name.split(' ').first;
      _userPlan = plan;
      _userStatus = status;
      _billValue = bill;
      _billDueDate = due;
    });
    _saveDeviceToken(cpf);
  }

  Future<void> _saveDeviceToken(String cpfCnpj) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('clientes')
            .doc(cpfCnpj)
            .set(
          {
            'fcmToken': token,
            'providerId': providerId,
            'lastUpdated': FieldValue.serverTimestamp()
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      print('❌ Erro ao salvar o token FCM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfigService().providerConfig!;
    if (_userName == null) {
      return LoginPage(
          onLoginSuccess: _handleLoginSuccess, providerConfig: config);
    } else {
      return PainelPage(
        cpfCnpj: _userCpfCnpj!,
        senha: _userSenha!,
        content: _userName!,
        plano: _userPlan!,
        status: _userStatus!,
        valorFatura: _billValue!,
        vencimentoFatura: _billDueDate!,
        providerConfig: config,
      );
    }
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class FatalErrorScreen extends StatelessWidget {
  final String error;
  const FatalErrorScreen({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 80),
              const SizedBox(height: 20),
              Text('Erro Crítico',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Não foi possível iniciar o aplicativo.\n\nDetalhe: $error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
