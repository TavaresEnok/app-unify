import 'package:flutter/material.dart';
import 'dart:ui'; // For PlatformDispatcher
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

Future<void> _ensureFirebaseSession() async {
  if (FirebaseAuth.instance.currentUser != null) {
    return;
  }

  try {
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint('🔐 Firebase Auth anônimo inicializado com sucesso.');
  } catch (error, stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: 'anonymous_firebase_auth_bootstrap_failed',
    );
    debugPrint('⚠️ Falha ao iniciar sessão anônima no Firebase: $error');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _ensureFirebaseSession();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Crashlytics Setup (Immortal Mode)
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
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
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await FirebaseMessaging.instance.requestPermission();

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
          return FatalErrorScreen(error: snapshot.error.toString());
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
      return FatalErrorScreen(error: config.errorMessage!);
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
          if (mounted && currentContext != null) {
            // ignore: use_build_context_synchronously
            RatingPromptDialog.showIfNeeded(currentContext);
          }
        });
      });
      return const PainelPage();
    } else {
      return LayoutSelector.getLoginPage(layoutType: layoutType);
    }
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
