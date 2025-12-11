import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'core/providers/configuration_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/models/theme_config.dart';
import 'core/painel_page.dart';
import 'layout_selector.dart';

// ========================================
// CONFIGURAÇÃO DO PROVEDOR
// Altere este valor para cada build de provedor
// ========================================
const String providerId = 'vibe'; // TODO: Carregar de config ou flavor

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
                debugPrint('Erro ao processar tema: $e');
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
    await FirebaseMessaging.instance.requestPermission();

    // Carregar configuração do provedor
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
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'App Provedor',
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
              return const SplashScreen();
            },
          ),
        );
      },
    );
  }
}

/// Widget que decide entre Login e Painel baseado no estado de autenticação.
/// Usa o LayoutSelector para escolher o layout correto baseado no `layoutType`.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
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

        if (configProvider.errorMessage != null) {
          return FatalErrorScreen(error: configProvider.errorMessage!);
        }

        // ====================================================
        // AQUI ESTÁ A MÁGICA: Seleção dinâmica do layout!
        // ====================================================
        final layoutType =
            configProvider.providerConfig?.layoutType ?? 'layout_06';

        if (authService.isAuthenticated) {
          // Usa o PainelPage que gerencia navegação e usa LayoutSelector internamente
          return const PainelPage();
        } else {
          // Usa o LayoutSelector para escolher a tela de login
          return LayoutSelector.getLoginPage(layoutType: layoutType);
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
      body: const Center(child: CircularProgressIndicator()),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
