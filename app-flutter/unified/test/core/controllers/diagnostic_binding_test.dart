import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/controllers/diagnostic_binding.dart';
import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/models/usuario.dart';
import 'package:app_provedor_unified/core/notifiers/auth_notifier.dart';
import 'package:app_provedor_unified/core/providers/configuration_provider.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/services/diagnostico_service.dart';

class Config extends ConfigurationProvider {
  ProviderConfig? current;
  @override
  ProviderConfig? get providerConfig => current;
  void publish() {
    current = ProviderConfig.fromJson(
        const {'name': 'Test', 'apiUrl': 'https://example.test/api'}, 'test');
    notifyListeners();
  }
}

class Auth extends AuthNotifier {
  @override
  FutureOr<Usuario?> build() => null;
  void loginContract(int contract) => state = AsyncData(Usuario(
      nome: 'Test',
      cpfCnpj: '12345678901',
      senha: '',
      plano: '',
      status: '',
      valorFatura: '',
      vencimentoFatura: '',
      contratoId: contract));
}

class Harness extends ConsumerStatefulWidget {
  final void Function(DiagnosticoService?) onChanged;
  const Harness(this.onChanged, {super.key});
  @override
  ConsumerState<Harness> createState() => HarnessState();
}

class HarnessState extends ConsumerState<Harness> {
  DiagnosticBinding? binding;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    binding ??= DiagnosticBinding(
        ref, context, (service, _) => widget.onChanged(service));
  }

  @override
  void dispose() {
    binding?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets(
      'late config binds; switching contract closes the previous stream; leaving closes the new stream',
      (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.shaz.plugin.fist/method'), (_) async => true);
    final config = Config();
    final auth = Auth();
    final changes = <DiagnosticoService?>[];
    await tester.pumpWidget(ProviderScope(overrides: [
      configurationProvider.overrideWith((_) => config),
      authNotifierProvider.overrideWith(() => auth)
    ], child: MaterialApp(home: Harness(changes.add))));
    await tester.pump();
    expect(changes.last, isNull);
    auth.loginContract(1);
    config.publish();
    await tester.pump();
    final first = changes.last!;
    expect(first.onuService?.contrato, '1');
    var firstClosed = false;
    first.stateStream.listen((_) {}, onDone: () => firstClosed = true);
    auth.loginContract(2);
    await tester.pump();
    await tester.pump();
    expect(firstClosed, isTrue);
    final second = changes.last!;
    expect(second.onuService?.contrato, '2');
    expect(identical(first, second), isFalse);
    var secondClosed = false;
    second.stateStream.listen((_) {}, onDone: () => secondClosed = true);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(secondClosed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
