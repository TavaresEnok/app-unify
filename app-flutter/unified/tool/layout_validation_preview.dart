// Isolated visual catalog entry point. Never used by the production build.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_provedor_unified/firebase_options.dart';
import 'package:app_provedor_unified/layout_selector.dart';
import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/models/usuario.dart';
import 'package:app_provedor_unified/core/models/fatura.dart';
import 'package:app_provedor_unified/core/notifiers/auth_notifier.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/providers/theme_provider.dart';
import 'package:app_provedor_unified/core/providers/configuration_provider.dart';
import 'package:app_provedor_unified/core/providers/financeiro_provider.dart';
import 'package:app_provedor_unified/core/providers/consumo_provider.dart';
import 'package:app_provedor_unified/core/services/notification_service.dart';
import 'package:app_provedor_unified/core/models/diagnostico_state.dart';
import 'package:app_provedor_unified/core/widgets/diagnostics/diagnostic_view.dart';
import 'package:app_provedor_unified/core/pages/shared_ping_page.dart';
import 'package:app_provedor_unified/core/pages/onboarding_page.dart';
import 'package:app_provedor_unified/core/pages/achievements_page.dart';
import 'package:app_provedor_unified/core/painel_page.dart';

String scenario = 'duas';
String previewColor = '#FC46AA';
bool previewDark = false;

Usuario get demoUser => Usuario(
    nome: 'Cliente Demonstração',
    cpfCnpj: '00000000000',
    senha: '',
    plano: 'Fibra 500 Mega',
    status: 'Online',
    contractStatus: scenario == 'suspensa' ? 'Suspenso' : 'Ativo',
    valorFatura: '99.90',
    vencimentoFatura: '20/11/2026',
    contratoId: 1);

class DemoAuth extends AuthNotifier {
  @override
  FutureOr<Usuario?> build() => demoUser;
  @override
  Future<void> refreshUserData(ProviderConfig c) async {}
}

class DemoConfig extends ConfigurationProvider {
  final ProviderConfig data;
  DemoConfig(String layout)
      : data = ProviderConfig.fromJson(
            jsonDecode(jsonEncode({
              'name': 'Vibe Telecom',
              'apiUrl': 'https://example.invalid/api',
              'layoutType': layout,
              'themeColor': previewColor,
              'faq': [
                {
                  'id': '1',
                  'question': 'Como melhorar o sinal do Wi-Fi?',
                  'answer':
                      'Posicione o roteador em um local central e livre de obstáculos.'
                },
                {
                  'id': '2',
                  'question': 'Como consultar minhas faturas?',
                  'answer': 'Acesse Faturas pelo menu do aplicativo.'
                }
              ],
              'supportContacts': [
                {
                  'name': 'Central de atendimento',
                  'type': 'url',
                  'value': 'https://example.invalid/atendimento'
                }
              ],
              'promotions': {
                'enabled': true,
                'items': [
                  {
                    'id': '1',
                    'title': 'Oferta de teste 1',
                    'description': 'Conteúdo demonstrativo',
                    'active': true,
                    'startDate': '2020-01-01',
                    'endDate': '2099-12-31'
                  },
                  {
                    'id': '2',
                    'title': 'Oferta de teste 2',
                    'description': 'Conteúdo demonstrativo',
                    'active': true,
                    'startDate': '2020-01-01',
                    'endDate': '2099-12-31'
                  },
                  {
                    'id': '3',
                    'title': 'Oferta expirada',
                    'active': true,
                    'endDate': '2020-12-31'
                  }
                ]
              },
              'tips': [],
              'menuConfig': {}
            })),
            'demo');
  @override
  ProviderConfig get providerConfig => data;
  @override
  bool get isLoading => false;
  @override
  Future<void> loadConfig(String id) async {}
}

class DemoFinance extends FinanceiroProvider {
  DemoFinance() : super(null);
  @override
  FinanceiroState get state => FinanceiroState.success;
  @override
  List<Fatura> get invoices {
    final now = DateTime.now();
    final future = DateTime(now.year, now.month + 1, 20);
    final past = DateTime(now.year, now.month - 1, 20);
    Fatura invoice(String number, double value, DateTime due, String status) =>
        Fatura(
            numero: number,
            valor: value,
            vencimento: due,
            status: status,
            pixCopiaECola: 'PIX-TESTE-$number',
            urlBoleto: 'https://example.invalid/boleto/$number');
    switch (scenario) {
      case 'paga':
        return [invoice('PAGA', 75.25, past, 'pago')];
      case 'unica':
        return [invoice('UNICA', 99.90, future, 'pendente')];
      case 'vencida':
      case 'suspensa':
        return [invoice('VENCIDA', 85.35, past, 'pendente')];
      default:
        return [
          invoice('MES-1', 99.90, future, 'pendente'),
          invoice('MES-2', 127.45, DateTime(future.year, future.month + 1, 20),
              'pendente')
        ];
    }
  }

  @override
  Map<int, double> get monthlyTotals => {9: 99.9, 10: 99.9, 11: 99.9};
  @override
  Future<void> fetchHistory() async {}
}

class DemoConsumption extends ConsumoViewModel {
  DemoConsumption() : super(null) {
    state = ConsumoState(selectedMonth: 11, selectedYear: 2026, data: {
      'usedGb': 125.4,
      'planName': 'Fibra 500 Mega',
      'details': <dynamic>[]
    });
  }
  @override
  Future<void> loadData() async {}
}

class DemoNotifications extends NotificationService {
  @override
  Future<void> syncRemoteNotifications(Usuario u, String id) async {}
}

final previewKey = GlobalKey<CatalogState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8765);
  server.listen((request) async {
    if (request.uri.path == '/show') {
      scenario = request.uri.queryParameters['scenario'] ?? 'duas';
      previewColor = request.uri.queryParameters['color'] ?? '#FC46AA';
      previewDark = request.uri.queryParameters['dark'] == '1';
      previewKey.currentState?.show(
          request.uri.queryParameters['theme'] ?? 'layout_02',
          request.uri.queryParameters['page'] ?? 'login');
      await Future<void>.delayed(const Duration(milliseconds: 1800));
    }
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({
      'theme': previewKey.currentState?.layout,
      'page': previewKey.currentState?.page,
      'scenario': scenario,
      'clipboard': (await Clipboard.getData(Clipboard.kTextPlain))?.text,
      'dark': previewDark,
      'color': previewColor
    }));
    await request.response.close();
  });
  runApp(Catalog(key: previewKey));
}

class Catalog extends StatefulWidget {
  const Catalog({super.key});
  @override
  State<Catalog> createState() => CatalogState();
}

class CatalogState extends State<Catalog> {
  String layout = 'layout_02', page = 'login';
  int version = 0;
  void show(String l, String p) => setState(() {
        layout = l;
        page = p;
        version++;
      });
  Widget screen(ProviderConfig config) {
    switch (page) {
      case 'login':
        return LayoutSelector.getLoginPage(layoutType: layout);
      case 'dashboard':
      case 'painel':
        return const PainelPage(refreshOnOpen: false);
      case 'conexao':
        return const PainelPage(
            initialDestination: 'connection', refreshOnOpen: false);
      case 'menu':
      case 'conta':
        return const PainelPage(
            initialDestination: 'account', refreshOnOpen: false);
      case 'faturas':
        return const PainelPage(
            initialDestination: 'invoices', refreshOnOpen: false);
      case 'suporte':
        return const PainelPage(
            initialDestination: 'support', refreshOnOpen: false);
      case 'diagnostico_default':
        return const PainelPage(
            initialDestination: 'network_diagnostic', refreshOnOpen: false);
      case 'diagnostico_em_andamento':
      case 'diagnostico_resultado':
      case 'diagnostico_interrompido':
        return Scaffold(
            appBar: AppBar(title: const Text('Verificar conexão')),
            body: DiagnosticView(
                state: _demoDiagnosticState(page),
                onQuick: () {},
                onComplete: () {},
                onCancel: () {},
                onShare: () {}));
      case 'consumo':
        return LayoutSelector.getConsumoPage(layoutType: layout);
      case 'meu_ip':
        return LayoutSelector.getMeuIpPage(layoutType: layout);
      case 'velocidade':
        return const PainelPage(
            initialDestination: 'speed_test', refreshOnOpen: false);
      case 'traceroute':
        return LayoutSelector.getTraceRoutePage(layoutType: layout);
      case 'ping':
        return const SharedPingPage();
      case 'wifi':
        return const PainelPage(
            initialDestination: 'wifi', refreshOnOpen: false);
      case 'faq':
        return LayoutSelector.getFaqPage(layoutType: layout);
      case 'contrato':
        return const PainelPage(
            initialDestination: 'contract', refreshOnOpen: false);
      case 'notificacoes':
        return LayoutSelector.getNotificationPage(layoutType: layout);
      case 'historico':
        return const PainelPage(
            initialDestination: 'history', refreshOnOpen: false);
      case 'conquistas':
        return const AchievementsPage();
      case 'onboarding':
        return OnboardingPage(onComplete: () {});
      default:
        return LayoutSelector.getDiagnosticByStyle(
            layoutType: layout,
            diagnosticStyle: page == 'diagnostico_default'
                ? 'default'
                : page.replaceFirst('diagnostico_', 'diagnostic_'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = DemoConfig(layout);
    return ProviderScope(
        key: ValueKey(version),
        overrides: [
          configurationProvider.overrideWith((_) => config),
          themeProvider.overrideWith((_) {
            final theme = DynamicThemeProvider();
            theme.setThemeMode(previewDark ? ThemeMode.dark : ThemeMode.light);
            return theme;
          }),
          authNotifierProvider.overrideWith(DemoAuth.new),
          financeiroViewModelProvider.overrideWith((_) => DemoFinance()),
          consumoViewModelProvider.overrideWith((_) => DemoConsumption()),
          notificationProvider.overrideWith((_) {
            final n = DemoNotifications();
            n.loadNotifications();
            return n;
          })
        ],
        child: Consumer(
            builder: (context, ref, _) => MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ref.watch(layoutTokensProvider).themeData(),
                home: screen(config.data))));
  }
}

DiagnosticoState _demoDiagnosticState(String page) {
  final entries = DiagnosticoState.initial().testResultsDisplay;
  final when = DateTime(2026, 11, 16, 12);
  entries['deviceInfo'] = {
    'status': TestStatus.success,
    'label': 'Informações do dispositivo',
    'result': 'Aparelho de demonstração',
    'measuredAt': when.toIso8601String()
  };
  entries['onuInfo'] = {
    'status': TestStatus.success,
    'label': 'Sinal da fibra',
    'result': {'rxPower': -20.5},
    'measuredAt': when.toIso8601String()
  };
  if (page == 'diagnostico_em_andamento') {
    entries['wifiInfo']!['status'] = TestStatus.running;
  } else if (page == 'diagnostico_resultado') {
    entries['wifiInfo'] = {
      'status': TestStatus.success,
      'label': 'Informações do Wi-Fi',
      'result': {'display': 'Rede demonstrativa · sinal disponível'},
      'measuredAt': when.toIso8601String()
    };
    entries['pingGateway'] = {
      'status': TestStatus.success,
      'label': 'Resposta do roteador',
      'metrics': {'latencyMs': 3, 'lossPercent': 0},
      'result': 'Latência: 3 ms'
    };
    entries['pingGoogle'] = {
      'status': TestStatus.error,
      'label': 'Resposta externa'
    };
  }
  return DiagnosticoState.initial().copyWith(
      testResultsDisplay: entries,
      runMode: DiagnosticRunMode.quick,
      isTesting: page == 'diagnostico_em_andamento',
      wasInterrupted: page == 'diagnostico_interrompido',
      startedAt: when,
      finishedAt: page == 'diagnostico_em_andamento' ? null : when,
      geralStatusMessage: 'Verificando as informações do Wi-Fi…');
}
