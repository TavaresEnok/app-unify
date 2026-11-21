import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:app_provedor_unified/core/controllers/wifi_management_controller.dart';
import 'package:app_provedor_unified/core/services/onu_wifi_service.dart';
import '../services/diagnostico_service_test.mocks.dart';

void main() {
  test('coalesces reads and ignores completion after leaving the page', () async {
    final service = MockOnuWifiService();
    final pending = Completer<List<WifiNetwork>>();
    when(service.fetchWifiNetworks()).thenAnswer((_) => pending.future);
    final controller = WifiManagementController(service);
    final first = controller.fetchNetworks();
    final second = controller.fetchNetworks();
    expect(identical(first, second), isTrue);
    expect(controller.value.isLoading, isTrue);
    controller.dispose();
    pending.complete([]);
    await Future.wait([first, second]);
    verify(service.fetchWifiNetworks()).called(1);
  });
  test('missing session produces a recoverable message', () async {
    final controller = WifiManagementController(null);
    await controller.fetchNetworks();
    expect(controller.value.error, isNotNull);
    expect(controller.value.isLoading, isFalse);
    controller.dispose();
  });
}
