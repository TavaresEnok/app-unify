import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/account_data_cache.dart';
import '../services/consumo_service.dart';
import 'providers.dart';

class ConsumoState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;
  final int selectedMonth;
  final int selectedYear;

  ConsumoState({
    this.isLoading = false,
    this.error,
    this.data,
    required this.selectedMonth,
    required this.selectedYear,
  });

  ConsumoState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? data,
    int? selectedMonth,
    int? selectedYear,
    bool clearData = false,
  }) {
    return ConsumoState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: clearData ? null : data ?? this.data,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }
}

/// Consumo por mês. Cada mês consultado fica guardado (em memória e no
/// aparelho): trocar de mês ou atualizar mantém o gráfico na tela enquanto a
/// resposta nova não chega, e uma falha não apaga o que já estava lá.
class ConsumoViewModel extends StateNotifier<ConsumoState> {
  final ConsumoService? _service;
  final AccountDataCache _cache;
  final Map<String, Map<String, dynamic>> _months = {};
  int _requestNumber = 0;

  ConsumoViewModel(this._service, {AccountDataCache? cache})
      : _cache = cache ?? AccountDataCache.instance,
        super(ConsumoState(
          selectedMonth: DateTime.now().month,
          selectedYear: DateTime.now().year,
        )) {
    loadData();
  }

  String _monthKey(int month, int year) =>
      '$year-${month.toString().padLeft(2, '0')}';

  String? _diskKey(String monthKey) {
    final service = _service;
    if (service == null) return null;
    return AccountDataCache.keyFor('consumption',
        providerId: service.providerId,
        document: service.cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
        contratoId: service.contratoId,
        extra: monthKey);
  }

  Future<void> loadData() async {
    final service = _service;
    if (service == null) {
      state = state.copyWith(error: 'Serviço não inicializado');
      return;
    }

    final requestNumber = ++_requestNumber;
    final month = state.selectedMonth;
    final year = state.selectedYear;
    final key = _monthKey(month, year);
    final known = _months[key];
    state = state.copyWith(isLoading: true, error: null, data: known);

    // Sem nada na tela, o último consumo guardado deste mês entra enquanto
    // a consulta anda (sem atrasar a consulta).
    final diskKey = _diskKey(key);
    final generation = _cache.generation;
    if (state.data == null && diskKey != null) {
      unawaited(_cache.read(diskKey).then((saved) {
        final data = saved?.data;
        if (!mounted ||
            requestNumber != _requestNumber ||
            state.data != null ||
            data is! Map) {
          return;
        }
        state = state.copyWith(data: Map<String, dynamic>.from(data));
      }));
    }

    try {
      final result = await service.fetchConsumptionData(
        month: month,
        year: year,
      );
      if (!mounted || requestNumber != _requestNumber) return;
      _months[key] = result;
      if (diskKey != null) {
        unawaited(_cache.write(diskKey, result, generation: generation));
      }
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      if (!mounted || requestNumber != _requestNumber) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void changeMonth(int month, int year) {
    if (state.selectedMonth == month && state.selectedYear == year) return;

    final known = _months[_monthKey(month, year)];
    state = state.copyWith(
        selectedMonth: month,
        selectedYear: year,
        data: known,
        clearData: known == null);
    loadData();
  }
}

/// Provider que fornece o ViewModel de Consumo. Só é recriado quando mudam
/// o provedor, a URL da API ou a conta — não a cada atualização da
/// configuração ou do cadastro.
final consumoViewModelProvider =
    StateNotifierProvider<ConsumoViewModel, ConsumoState>((ref) {
  final config = ref.watch(configurationProvider.select((c) {
    final p = c.providerConfig;
    return p == null ? null : (id: p.id, apiUrl: p.apiUrl);
  }));
  final account = ref.watch(authNotifierProvider.select((a) {
    final u = a.valueOrNull;
    return u == null ? null : (cpf: u.cpfCnpj, contrato: u.contratoId);
  }));

  if (config == null || account == null) {
    return ConsumoViewModel(null);
  }

  return ConsumoViewModel(ConsumoService(
    apiUrl: '${config.apiUrl}/get-consumption-data',
    providerId: config.id,
    cpfCnpj: account.cpf,
    contratoId: account.contrato,
  ));
});
