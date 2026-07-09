import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/consumo_service.dart';
import 'providers.dart';

/// Estado do consumo mensal
class WeeklyUsageState {
  final List<double> usageData; // Consumo por dia em GB (dados reais do mês)
  final List<String> dayLabels; // Rótulos de dia para o gráfico
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;
  final int month;
  final int year;

  const WeeklyUsageState({
    this.usageData = const [],
    this.dayLabels = const [],
    this.isLoading = false,
    this.error,
    DateTime? lastUpdated,
    int? month,
    int? year,
  })  : lastUpdated = lastUpdated ?? const _DefaultDateTime(),
        month = month ?? 0,
        year = year ?? 0;

  double get totalMonthlyUsage =>
      usageData.fold(0.0, (sum, value) => sum + value);

  // Mantido por compatibilidade com código existente
  double get totalWeeklyUsage => totalMonthlyUsage;

  double get todayUsage => usageData.isNotEmpty ? usageData.last : 0;

  WeeklyUsageState copyWith({
    List<double>? usageData,
    List<String>? dayLabels,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    int? month,
    int? year,
  }) {
    return WeeklyUsageState(
      usageData: usageData ?? this.usageData,
      dayLabels: dayLabels ?? this.dayLabels,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}

// Helper class for default DateTime
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime(2000);
}

/// Provider para consumo mensal com cache
class WeeklyUsageNotifier extends StateNotifier<WeeklyUsageState> {
  final ConsumoService? _service;
  static const String _cacheKey = 'monthly_usage_cache';
  static const Duration _cacheValidity = Duration(hours: 1);

  WeeklyUsageNotifier(this._service) : super(const WeeklyUsageState()) {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);

      if (cached != null) {
        final data = json.decode(cached) as Map<String, dynamic>;
        final cachedTime = DateTime.parse(data['timestamp'] as String);

        if (DateTime.now().difference(cachedTime) < _cacheValidity) {
          final usageData = (data['usage'] as List)
              .map((e) => (e as num).toDouble())
              .toList();
          final dayLabels =
              (data['labels'] as List?)?.map((e) => e.toString()).toList() ??
                  [];
          state = WeeklyUsageState(
            usageData: usageData,
            dayLabels: dayLabels,
            lastUpdated: cachedTime,
            month: data['month'] as int? ?? DateTime.now().month,
            year: data['year'] as int? ?? DateTime.now().year,
          );
          return;
        }
      }
    } catch (_) {}

    await refresh();
  }

  Future<void> _saveToCache(
      List<double> usage, List<String> labels, int month, int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'usage': usage,
        'labels': labels,
        'month': month,
        'year': year,
      };
      await prefs.setString(_cacheKey, json.encode(data));
    } catch (_) {}
  }

  Future<void> refresh() async {
    final now = DateTime.now();
    state = state.copyWith(isLoading: true, error: null);

    try {
      List<double> dailyData;
      List<String> dayLabels;

      if (_service != null) {
        final monthlyData = await _service.fetchConsumptionData(
          month: now.month,
          year: now.year,
        );
        final result = _mapMonthlyData(monthlyData, now.month, now.year);
        dailyData = result.$1;
        dayLabels = result.$2;
      } else {
        final result = _generateRealisticMonthly(now.month, now.year);
        dailyData = result.$1;
        dayLabels = result.$2;
      }

      await _saveToCache(dailyData, dayLabels, now.month, now.year);

      state = WeeklyUsageState(
        usageData: dailyData,
        dayLabels: dayLabels,
        lastUpdated: now,
        month: now.month,
        year: now.year,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Converte dados mensais da API em listas de uso e rótulos para o gráfico
  (List<double>, List<String>) _mapMonthlyData(
      Map<String, dynamic> monthlyData, int month, int year) {
    final details =
        (monthlyData['details'] as List<dynamic>?)?.cast<Map<String, dynamic>>();

    if (details == null || details.isEmpty) {
      // Fallback: usa o total mensal distribuído igualmente
      final totalGb = (monthlyData['usedGb'] as num?)?.toDouble() ?? 0.0;
      final today = DateTime.now().day;
      final dailyAvg = today > 0 ? totalGb / today : 0.0;
      final data = List<double>.generate(today, (_) => dailyAvg);
      final labels = List<String>.generate(today, (i) => (i + 1).toString());
      return (data, labels);
    }

    // Usa os dados reais por dia (pode ter lacunas - dias sem sessões)
    details.sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));

    final data = details.map((e) => (e['gb'] as num).toDouble()).toList();
    final labels = details.map((e) => (e['day'] as int).toString()).toList();

    // Exibe apenas até 15 pontos para não poluir o gráfico mini do dashboard
    if (data.length > 15) {
      final step = (data.length / 15).ceil();
      final sampledData = <double>[];
      final sampledLabels = <String>[];
      for (int i = 0; i < data.length; i += step) {
        sampledData.add(data[i]);
        sampledLabels.add(labels[i]);
      }
      return (sampledData, sampledLabels);
    }

    return (data, labels);
  }

  /// Gera consumo mensal realístico para modo sem serviço
  (List<double>, List<String>) _generateRealisticMonthly(int month, int year) {
    final today = DateTime.now().day;
    final data = <double>[];
    final labels = <String>[];

    for (int day = 1; day <= today; day++) {
      final date = DateTime(year, month, day);
      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final base = isWeekend ? 18.0 : 13.0;
      final variation = 0.7 + (day % 5) * 0.12;
      data.add(base * variation);
      labels.add(day.toString());
    }

    // Exibe apenas até 15 pontos
    if (data.length > 15) {
      final step = (data.length / 15).ceil();
      final sampledData = <double>[];
      final sampledLabels = <String>[];
      for (int i = 0; i < data.length; i += step) {
        sampledData.add(data[i]);
        sampledLabels.add(labels[i]);
      }
      return (sampledData, sampledLabels);
    }

    return (data, labels);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}

/// Provider global de consumo mensal
final weeklyUsageProvider =
    StateNotifierProvider<WeeklyUsageNotifier, WeeklyUsageState>((ref) {
  final providerConfig = ref.watch(configurationProvider).providerConfig;
  final configConfig = providerConfig?.config;
  final usuario = ref.watch(authNotifierProvider).value;

  if (configConfig == null || usuario == null || providerConfig == null) {
    return WeeklyUsageNotifier(null);
  }

  final baseApiUrl = providerConfig.apiUrl;

  final service = ConsumoService(
    apiUrl: '$baseApiUrl/get-consumption-data',
    sgpParams: {
      'token': configConfig.integrations.apiToken,
      'app': configConfig.integrations.appName,
      'sgpBaseUrl': configConfig.integrations.sgpBaseUrl,
    },
    cpfCnpj: usuario.cpfCnpj,
    senha: usuario.senha,
  );

  return WeeklyUsageNotifier(service);
});
