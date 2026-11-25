import 'package:flutter/material.dart';
import 'core/vibe/vibe_logo.dart';
import 'dart:ui'; // For PlatformDispatcher
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'core/providers/providers.dart';
import 'core/painel_page.dart';
import 'core/services/push_notification_service.dart';
import 'core/pages/onboarding_page.dart';
import 'core/widgets/rating_prompt_dialog.dart';
import 'core/widgets/content_state.dart';
import 'layout_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ========================================
// CONFIGURAÇÃO DO PROVEDOR
// ========================================
const String providerId = 'vibe';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('ℹ️ Firebase (FCM) indisponível neste dispositivo: $e');
  }

  // Crashlytics Setup + ErrorWidget customizado para debug
  FlutterError.onError = (errorDetails) {
    try {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    } catch (_) {}
    debugPrint('🚨 FLUTTER ERROR: ${errorDetails.exception}');
    debugPrint('📍 ${errorDetails.stack}');
  };

  // Async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {}
    debugPrint('🚨 ZONE ERROR: $error');
    debugPrint('📍 $stack');
    return true;
  };

  // Override ErrorWidget para mostrar o erro REAL em vez de tela cinza/branca
  // Essencial para diagnóstico de crashes em release mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!kDebugMode) {
      return const Material(
          child: SafeArea(
              child: ContentState(
        icon: Icons.error_outline,
        title: 'Não conseguimos mostrar esta tela',
        message:
            'Feche e abra o aplicativo novamente. Se o problema continuar, fale com seu provedor.',
      )));
    }
    final message = details.exception.toString();
    final shortMsg =
        message.length > 200 ? '${message.substring(0, 200)}...' : message;
    return Material(
      color: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bug_report, color: Color(0xFFE94560), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Erro interno',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                shortMsg,
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Envie este texto ao suporte técnico',
                style: TextStyle(color: Color(0xFF666666), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Theme Provider
    final themeNotifer = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'App Provedor',
      theme: themeNotifer.lightTheme,
      darkTheme: themeNotifer.darkTheme,
      themeMode: themeNotifer.themeMode,
      home: const AppInitializationWrapper(),
    );
  }
}

class AppInitializationWrapper extends ConsumerStatefulWidget {
  const AppInitializationWrapper({super.key});

  @override
  ConsumerState<AppInitializationWrapper> createState() =>
      _AppInitializationWrapperState();
}

class _AppInitializationWrapperState
    extends ConsumerState<AppInitializationWrapper> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}

    // Initialize Push Notification Service for foreground handling
    final notificationService = ref.read(notificationProvider);
    await PushNotificationService()
        .initialize(notificationService: notificationService);

    if (mounted) {
      // Usamos read aqui pois é uma ação única na inicialização
      await ref.read(configurationProvider).loadConfig(providerId);
      await ref.read(notificationProvider).loadNotifications();
      // Init Deep Links
      ref.read(deepLinkServiceProvider).init();

      // Subscribe to provider topic for broadcast notifications
      await PushNotificationService().subscribeToTopic('provider_$providerId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FatalErrorScreen(
              error: snapshot.error.toString(),
              onRetry: () {
                final next = _initializeApp();
                setState(() {
                  _initialization = next;
                });
              });
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const AuthGate();
        }
        return const SplashScreen();
      },
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _showOnboarding = false;
  bool _onboardingChecked = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    // Incrementar contador de uso para rating
    RatingPromptDialog.incrementUsage();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    if (mounted) {
      setState(() {
        _showOnboarding = !completed;
        _onboardingChecked = true;
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    final authState = ref.watch(authNotifierProvider);

    if (config.isLoading || authState.isLoading || !_onboardingChecked) {
      return const SplashScreen();
    }

    if (config.errorMessage != null) {
      return FatalErrorScreen(
          error: config.errorMessage!,
          onRetry: () =>
              ref.read(configurationProvider).loadConfig(providerId));
    }

    // Mostrar onboarding para novos usuários
    if (_showOnboarding) {
      return OnboardingPage(onComplete: _onOnboardingComplete);
    }

    final layoutType = config.providerConfig?.layoutType ?? 'layout_06';

    if (authState.value != null) {
      // Mostrar prompt de avaliação após login (com delay)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 3), () {
          final currentContext = navigatorKey.currentContext;
          if (currentContext == null || !currentContext.mounted) return;
          RatingPromptDialog.showIfNeeded(currentContext);
        });
      });
      return const PainelPage();
    } else {
      return LayoutSelector.getLoginPage(layoutType: layoutType);
    }
  }
}

/// Abertura do app: a marca do provedor sobre branco, na mesma posição da
/// tela de abertura nativa, com uma barra fina enquanto os dados carregam.
class SplashScreen extends StatelessWidget {
  final Color backgroundColor;
  const SplashScreen({super.key, this.backgroundColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          VibeLogo(
            name: '',
            image: const AssetImage('assets/images/logo_splash.png'),
            height: 72,
            maxWidth: 220,
            background: backgroundColor,
            fallback: const SizedBox(height: 72),
          ),
          const SizedBox(height: 28),
          Semantics(
            label: 'Carregando',
            child: SizedBox(
              width: 96,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  minHeight: 3,
                  color: Color(0xFF18202C),
                  backgroundColor: Color(0x1A18202C),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class FatalErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  const FatalErrorScreen({super.key, required this.error, this.onRetry});
  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: ContentState(
        icon: Icons.cloud_off_outlined,
        title: 'Não conseguimos iniciar o aplicativo',
        message:
            'Verifique sua conexão e tente novamente. Se o problema continuar, fale com seu provedor.',
        actionLabel: 'Tentar de novo',
        onAction: onRetry,
      )));
}
