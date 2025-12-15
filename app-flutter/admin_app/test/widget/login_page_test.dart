import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:admin_app/pages/login_page.dart';
import 'package:admin_app/core/providers/providers.dart';
import 'package:admin_app/core/notifiers/auth_notifier.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:admin_app/l10n/app_localizations.dart';

class MockAuthNotifier extends AsyncNotifier<AuthState>
    implements AuthNotifier {
  bool signInCalled = false;
  Completer<void>? signInCompleter;

  @override
  FutureOr<AuthState> build() {
    return const AuthState();
  }

  @override
  Future<void> signIn(String email, String password) async {
    signInCalled = true;
    state = const AsyncValue.loading();

    if (signInCompleter != null) {
      await signInCompleter!.future;
    }

    state = const AsyncValue.data(AuthState()); // Simulate success
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  Widget createWidget({List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('pt')],
        home: LoginPage(),
      ),
    );
  }

  testWidgets('LoginPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('LoginPage validation shows error on empty fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Preencha todos os campos'), findsOneWidget);
  });

  testWidgets('LoginPage shows loading and calls signIn', (
    WidgetTester tester,
  ) async {
    final mockNotifier = MockAuthNotifier();
    mockNotifier.signInCompleter = Completer<void>();

    await tester.pumpWidget(
      createWidget(
        overrides: [authNotifierProvider.overrideWith(() => mockNotifier)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'E-mail'),
      'test@test.com',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Senha'), '123456');
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));

    // Update to loading state
    await tester.pump();

    // Verify loading (CircularProgressIndicator or Button disabled state)
    // In our implementation, the button shows a CircularProgressIndicator when loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(mockNotifier.signInCalled, true);

    // Complete future
    mockNotifier.signInCompleter!.complete();
    await tester.pump();

    // Should return to normal
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
