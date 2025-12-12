import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/locator.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'painel.dart';
import 'financeiro_page.dart';
import 'local_notification_service.dart';
import 'configuration_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'providers/theme_provider.dart';
import 'models/theme_config.dart';
import 'utils.dart';

const String providerId = 'vibe';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LocalNotificationService.showNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
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

  void _handleNotificationClick(RemoteMessage message) {
    final screen = message.data['screen'];
    if (screen == 'invoices' || screen == 'faturas') {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        if (authService.isAuthenticated && authService.usuario != null) {
          navigatorKey.currentState?.push(MaterialPageRoute(
              builder: (context) => FinanceiroPage(
                    cpfCnpj: authService.usuario!.cpfCnpj,
                    senha: authService.usuario!.senha,
                    sgpParams: const {},
                  )));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DynamicThemeProvider>(context);

    return Consumer<ConfigurationProvider>(
      builder: (context, configProvider, child) {
        final config = configProvider.providerConfig?.config;
        final primaryColor =
            config != null ? hexToColor(config.themeColor) : Colors.white;

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Layout 03',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: FutureBuilder(
            future: _initialization,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return FatalErrorScreen(error: snapshot.error.toString());
              }
              if (snapshot.connectionState == ConnectionState.done) {
                return const AuthGate();
              }
              return SplashScreen(backgroundColor: primaryColor);
            },
          ),
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
          final color = configProvider.providerConfig != null
              ? hexToColor(configProvider.providerConfig!.config.themeColor)
              : Colors.white;
          return SplashScreen(backgroundColor: color);
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
  final Color backgroundColor;
  const SplashScreen({super.key, this.backgroundColor = Colors.white});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: const Center(child: CircularProgressIndicator(color: Colors.blue)),
    );
  }
}

class FatalErrorScreen extends StatelessWidget {
  final String error;
  const FatalErrorScreen({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Erro crítico',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
