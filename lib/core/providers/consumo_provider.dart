import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  }) {
    return ConsumoState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }
}

class ConsumoViewModel extends StateNotifier<ConsumoState> {
  final ConsumoService? _service;

  ConsumoViewModel(this._service)
      : super(ConsumoState(
          selectedMonth: DateTime.now().month,
          selectedYear: DateTime.now().year,
        )) {
    loadData();
  }

  Future<void> loadData() async {
    if (_service == null) {
      state = state.copyWith(error: 'Serviço não inicializado');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _service.fetchConsumptionData(
        month: state.selectedMonth,
        year: state.selectedYear,
      );
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void changeMonth(int month, int year) {
    if (state.selectedMonth == month && state.selectedYear == year) return;

    state = state.copyWith(selectedMonth: month, selectedYear: year);
    loadData();
  }
}

/// Provider que fornece o ViewModel de Consumo
final consumoViewModelProvider =
    StateNotifierProvider<ConsumoViewModel, ConsumoState>((ref) {
  final configConfig = ref.watch(configurationProvider).providerConfig?.config;
  final usuario = ref.watch(authNotifierProvider).value;

  if (configConfig == null || usuario == null) {
    return ConsumoViewModel(null);
  }

  // Create service instance
  final service = ConsumoService(
    apiUrl: 'http://168.194.13.18:3000/get-consumption-data',
    sgpParams: {
      'token': configConfig.integrations.apiToken,
      'app': configConfig.integrations.appName,
      'sgpBaseUrl': configConfig.integrations.sgpBaseUrl,
    },
    cpfCnpj: usuario.cpfCnpj,
    senha: usuario.senha,
  );

  return ConsumoViewModel(service);
});
