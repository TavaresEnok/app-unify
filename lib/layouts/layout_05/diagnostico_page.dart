import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/configuration_provider.dart';
import '../../core/services/onu_wifi_service.dart';
import '../../core/services/auth_service.dart';
import 'theme.dart';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage> {
  bool _scanning = false;
  OnuData? _onuData;
  String? _errorMessage;
  OnuWifiService? _onuService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initService();
    });
  }

  Future<void> _initService() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final configProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);
    final user = authService.usuario;
    final config = configProvider.providerConfig;

    if (user == null || config == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro de autenticação.';
        });
      }
      return;
    }

    _onuService = OnuWifiService(
      apiUrl: config.apiUrl,
      cpfCnpj: user.cpfCnpj,
      senha: user.senha,
      contrato: user.contratoId?.toString(),
      sgpParams: {
        'token': config.config.integrations.apiToken,
        'app': config.config.integrations.appName,
        'sgpBaseUrl': config.config.integrations.sgpBaseUrl,
      },
    );

    // Auto-start scan
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    if (_onuService == null) return;

    if (mounted) {
      setState(() {
        _scanning = true;
        _errorMessage = null;
        _onuData = null;
      });
    }

    try {
      // Simulate at least 2 seconds for visual effect if real call is too fast
      final minTime = Future.delayed(const Duration(seconds: 2));
      final dataTask = _onuService!.fetchOnuSignal();

      await Future.wait([minTime, dataTask]).then((results) {
        if (mounted) {
          setState(() {
            _onuData = results[1] as OnuData;
            _scanning = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Não foi possível comunicar com a ONU.\nVerifique se o equipamento está ligado.';
          _scanning = false;
        });
      }
    }
  }

  Color _getSignalColor(double? signal) {
    if (signal == null) return Layout05Theme.textGrey;
    if (signal > -25) return Layout05Theme.success;
    if (signal > -27) return Layout05Theme.warning;
    return Layout05Theme.error;
  }

  String _getSignalStatus(double? signal) {
    if (signal == null) return 'Desconhecido';
    if (signal > -25) return 'Excelente';
    if (signal > -27) return 'Bom';
    return 'Fraco';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: Text('Diagnóstico de Rede', style: Layout05Theme.heading2),
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Layout05Theme.textWhite),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scanning ? null : _runDiagnostics,
          ),
        ],
      ),
      body: _scanning ? _buildScanningUI() : _buildResultsUI(),
    );
  }

  Widget _buildScanningUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Layout05Theme.primary.withOpacity(0.5)),
                ),
              ),
              const Icon(Icons.router, size: 48, color: Layout05Theme.primary),
            ],
          ),
          const SizedBox(height: 32),
          Text('Analisando sua conexão...', style: Layout05Theme.heading2),
          const SizedBox(height: 12),
          Text(
            'Verificando sinal óptico e status da ONU.\nIsso pode levar alguns segundos.',
            textAlign: TextAlign.center,
            style: Layout05Theme.bodyText,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsUI() {
    if (_errorMessage != null) {
      return Center(
          child: Text(_errorMessage!,
              style: const TextStyle(color: Layout05Theme.error),
              textAlign: TextAlign.center));
    }
    if (_onuData == null) {
      return Center(
          child: Text('Aguardando teste...', style: Layout05Theme.bodyText));
    }

    final signal = _onuData!.signalRx;
    final color = _getSignalColor(signal);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: Layout05Theme.glassDecoration,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wifi_tethering, size: 48, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  _getSignalStatus(signal),
                  style: TextStyle(
                      color: color, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text('Sinal Óptico', style: Layout05Theme.bodyText),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat('Download',
                        '${_onuData!.signalRx?.toStringAsFixed(2) ?? "N/A"} dBm'),
                    _buildMiniStat('Upload',
                        '${_onuData!.signalTx?.toStringAsFixed(2) ?? "N/A"} dBm'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Details Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildDetailCard(Icons.device_hub, 'Modelo', _onuData!.model),
              _buildDetailCard(Icons.thermostat, 'Temperatura',
                  '${_onuData!.temperature ?? "N/A"}°C'),
              _buildDetailCard(
                  Icons.bolt, 'Voltagem', '${_onuData!.voltage ?? "N/A"}V'),
              _buildDetailCard(
                  Icons.info_outline, 'Status', _onuData!.connectionStatus),
            ],
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _runDiagnostics,
              icon: const Icon(Icons.refresh),
              label: const Text('REFAZER TESTE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Layout05Theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: Layout05Theme.label),
        const SizedBox(height: 4),
        Text(value, style: Layout05Theme.heading2),
      ],
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Layout05Theme.glassDecoration, // Using glass for details too
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Layout05Theme.textGrey),
              const SizedBox(width: 8),
              Text(label, style: Layout05Theme.label),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: Layout05Theme.heading2.copyWith(fontSize: 16)),
        ],
      ),
    );
  }
}
