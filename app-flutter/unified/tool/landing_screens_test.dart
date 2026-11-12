// ignore_for_file: invalid_use_of_visible_for_testing_member
// Gera as imagens das telas reais do app usadas na landing page.
// Não é teste: renderiza os dashboards de verdade com dados fictícios.
//
//   flutter test --no-pub --update-goldens tool/landing_screens_test.dart
//
// Só o layout 05 entra: os outros dependem de fontes do google_fonts ou de
// Firebase, que o ambiente de teste não tem.
// Saída: tool/screens/*.png (copiar para landing-page/img/).
import 'dart:io';

import 'package:app_provedor_unified/layouts/layout_05/dashboard_page.dart' as l05;
import 'package:app_provedor_unified/layouts/layout_05/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fonts = '/home/app/flutter/bin/cache/artifacts/material_fonts';

Future<void> _loadFonts() async {
  final roboto = FontLoader('Roboto');
  for (final file in ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold', 'Roboto-Light', 'Roboto-Black']) {
    roboto.addFont(File('$_fonts/$file.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(File('$_fonts/MaterialIcons-Regular.otf').readAsBytes().then((b) => ByteData.view(b.buffer)));
  await icons.load();
}

Future<void> _capture(WidgetTester tester, String name, ThemeData theme, Widget page) async {
  tester.view.physicalSize = const Size(1236, 2676); // 412 x 892 lógicos
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(debugShowCheckedModeBanner: false, theme: theme, home: page),
  ));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/$name.png'));
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // O dashboard escuta a conectividade; no teste não há plugin nativo.
    for (final channel in ['dev.fluttercommunity.plus/connectivity_status', 'dev.fluttercommunity.plus/connectivity']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (call) async => call.method == 'check' ? ['wifi'] : null);
    }
  });

  final due = DateTime.now().add(const Duration(days: 6));
  void go(String _) {}

  testWidgets('layout 05', (tester) async {
    await _capture(tester, 'app-layout-05', Layout05Theme.themeData, l05.DashboardPage(
      customerName: 'Marina', planName: 'Fibra 500 Mega', connectionStatus: 'Online',
      billAmount: 109.90, billDueDate: due, usedGb: 182, totalGb: 500,
      downloadMbps: 487, uploadMbps: 243, onNavigate: go));
  });
}
