import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'core/providers/providers.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Blue Premium Theme Palette
    const primaryColor = Color(0xFF2563EB); // Blue 600
    const secondaryColor = Color(0xFF0EA5E9); // Sky 500
    const backgroundColor = Color(0xFF0F172A); // Slate 900
    const surfaceColor = Color(0xFF1E293B); // Slate 800
    const textColor = Colors.white;

    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      // Dark Theme (Default)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: surfaceColor,
        ),

        // Typography
        textTheme: baseTextTheme.apply(
          bodyColor: textColor,
          displayColor: textColor,
        ),

        // AppBar Style
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceColor.withValues(alpha: 0.8),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        // Card Style
        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),

        // Input Fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(color: Colors.grey[400]),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),

        // Navigation Bar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surfaceColor,
          indicatorColor: primaryColor.withValues(alpha: 0.2),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primaryColor);
            }
            return IconThemeData(color: Colors.grey[400]);
          }),
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),

        // Dialogs
        dialogTheme: DialogThemeData(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (state) {
        if (state.isAuthenticated) {
          if (!state.isSuperAdmin) {
            return const AccessDeniedScreen();
          }
          return const HomePage();
        }
        return const LoginPage();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Erro fatal de inicialização: $error')),
      ),
    );
  }
}

class AccessDeniedScreen extends ConsumerWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gpp_bad, size: 64, color: Colors.red),
              ),
              const SizedBox(height: 24),
              Text(
                'Acesso Restrito',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apenas administradores podem acessar este painel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Voltar ao Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
