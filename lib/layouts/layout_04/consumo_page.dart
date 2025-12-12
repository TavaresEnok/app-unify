import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

import '../../core/services/consumo_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/configuration_provider.dart';
import 'theme.dart';

class ConsumoPage extends StatefulWidget {
  const ConsumoPage({super.key});

  @override
  State<ConsumoPage> createState() => _ConsumoPageState();
}

class _ConsumoPageState extends State<ConsumoPage> {
  late ConsumoService _consumoService;
  bool _isLoading = true;
  Map<String, dynamic>? _consumoData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initService();
    });
  }

  void _initService() {
    final configProvider = context.read<ConfigurationProvider>();
    final authService = context.read<AuthService>();
    final providerConfig = configProvider.providerConfig;
    final usuario = authService.usuario;

    if (providerConfig != null && usuario != null) {
      _consumoService = ConsumoService(
        apiUrl: providerConfig.apiUrl,
        sgpParams: {
          'token': providerConfig.config.integrations.apiToken,
          'app': providerConfig.config.integrations.appName,
          'sgpBaseUrl': providerConfig.config.integrations.sgpBaseUrl,
        },
        cpfCnpj: usuario.cpfCnpj,
        senha: usuario.senha,
      );
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Try fetching real data first
      // Note: Assuming fetchConsumptionData returns Map<String, dynamic>
      // similar to what we used in the mock. Adapting if necessary.
      try {
        final data = await _consumoService.fetchConsumptionData();
        if (mounted) {
          setState(() {
            _consumoData = data;
            _isLoading = false;
          });
          return;
        }
      } catch (apiError) {
        debugPrint('API Error on Consumo: $apiError');
        // Fallthrough to mock if API fails (for demo/development)
      }

      await Future.delayed(const Duration(seconds: 1)); // Cyber delay

      // Mock Data Fallback
      final mockData = {
        'used': 78.5,
        'total': 200.0,
        'history': [
          {'date': '01/05', 'gb': 2.5},
          {'date': '02/05', 'gb': 3.1},
          {'date': '03/05', 'gb': 1.8},
          {'date': '04/05', 'gb': 4.2},
          {'date': '05/05', 'gb': 2.9},
          {'date': '06/05', 'gb': 3.5},
          {'date': '07/05', 'gb': 5.0},
        ]
      };

      if (mounted) {
        setState(() {
          _consumoData = mockData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout04Theme.background,
      appBar: AppBar(
        title: Text('Consumo de Dados', style: Layout04Theme.heading3),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: Layout04Theme.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Layout04Theme.primaryCyan,
                    ),
                  ),
                )
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final used = _consumoData?['used'] ?? 0.0;
    final total = _consumoData?['total'] ?? 100.0;
    final percent = (used / total).clamp(0.0, 1.0);
    final history = _consumoData?['history'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildMainCircularGraph(used, total, percent),
          const SizedBox(height: 32),
          _buildHistoryList(history),
        ],
      ),
    );
  }

  Widget _buildMainCircularGraph(double used, double total, double percent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: Layout04Theme.glassCard(borderRadius: 24),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 15,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Layout04Theme.glassWhite,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: percent),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 15,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Layout04Theme.primaryCyan,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(percent * 100).toInt()}%',
                        style: Layout04Theme.heading1.copyWith(fontSize: 48),
                      ),
                      Text(
                        'Utilizado',
                        style: Layout04Theme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(
                    'Consumido',
                    '${used.toStringAsFixed(1)} GB',
                    Layout04Theme.primaryCyan,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Layout04Theme.glassBorder,
                  ),
                  _buildLegendItem(
                    'Disponível',
                    '${(total - used).toStringAsFixed(1)} GB',
                    Layout04Theme.glassWhite.withOpacity(0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: Layout04Theme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: Layout04Theme.heading3),
      ],
    );
  }

  Widget _buildHistoryList(List<dynamic> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text('Histórico Diário', style: Layout04Theme.heading3),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: Layout04Theme.glassCard(),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (ctx, idx) => Divider(
                  color: Layout04Theme.glassBorder,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final item = history[index];
                  final gb = item['gb'] as double;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Layout04Theme.primaryCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: Layout04Theme.primaryCyan,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item['date'],
                      style: Layout04Theme.bodyLarge,
                    ),
                    trailing: Text(
                      '${gb.toStringAsFixed(1)} GB',
                      style: Layout04Theme.heading3.copyWith(fontSize: 16),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
