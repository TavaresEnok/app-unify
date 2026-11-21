import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/providers/consumo_provider.dart';
import 'package:app_provedor_unified/core/services/consumo_service.dart';

class PendingConsumptionService extends ConsumoService {
  PendingConsumptionService() : super(apiUrl: '', providerId: '', cpfCnpj: '');
  final requests = <Completer<Map<String, dynamic>>>[];

  @override
  Future<Map<String, dynamic>> fetchConsumptionData({int? month, int? year}) {
    final request = Completer<Map<String, dynamic>>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  test('uma resposta antiga não substitui o consumo do mês escolhido',
      () async {
    final service = PendingConsumptionService();
    final model = ConsumoViewModel(service);
    final previousMonth =
        DateTime(model.state.selectedYear, model.state.selectedMonth - 1);
    model.changeMonth(previousMonth.month, previousMonth.year);
    expect(service.requests, hasLength(2));

    service.requests[1].complete({'usedGb': 25.0});
    await Future<void>.delayed(Duration.zero);
    service.requests[0].complete({'usedGb': 99.0});
    await Future<void>.delayed(Duration.zero);

    expect(model.state.selectedMonth, previousMonth.month);
    expect(model.state.data?['usedGb'], 25.0);
    model.dispose();
  });
}
