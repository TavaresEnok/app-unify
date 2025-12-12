import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/locator.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'painel.dart';
import 'local_notification_service.dart';
import 'configuration_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'providers/theme_provider.dart';
import 'models/theme_config.dart';
import 'utils.dart';

const String providerId = 'vibe';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    try {
      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('✅ Mensagem recebida em primeiro plano!');
        LocalNotificationService.showNotification(message);
      });
    } catch (e) {
      print('Erro ao inicializar Firebase Messaging: $e');
    }

    // Carregar configuração
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

    return Consumer<ConfigurationProvider>(
      builder: (context, configProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Layout 06',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => FutureBuilder(
                  future: _initialization,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print(
                          "Erro na inicialização (pode ser ignorado se app abrir): ${snapshot.error}");
                    }
                    return const AuthGate();
                  },
                ),
            '/login': (context) => const LoginPage(),
            '/painel': (context) => const PainelPage(),
          },
        );
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
  bool _locatorInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ConfigurationProvider>(context, listen: false)
          .loadConfig(providerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConfigurationProvider, AuthService>(
      builder: (context, configProvider, authService, child) {
        if (configProvider.isLoading || authService.isLoading) {
          return const SplashScreen();
        }

        if (configProvider.providerConfig != null && !_locatorInitialized) {
          setupLocator(configProvider.providerConfig!);
          _locatorInitialized = true;
        }

        if (configProvider.errorMessage != null) {
          return FatalErrorScreen(error: configProvider.errorMessage!);
        }

        if (authService.isAuthenticated) {
          return const PainelPage();
        } else {
          return const LoginPage();
        }
      },
    );
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: scheme.error.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: scheme.error, size: 72),
              const SizedBox(height: 16),
              Text('Erro crítico',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'Não foi possível iniciar o aplicativo.\n\nDetalhe: $error',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
