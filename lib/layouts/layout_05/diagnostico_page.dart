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

    print('[DiagnosticoPage] _runDiagnostics START');
    try {
      // Simulate at least 2 seconds for visual effect if real call is too fast
      final minTime = Future.delayed(const Duration(seconds: 2));
      print('[DiagnosticoPage] Calling fetchOnuSignal...');
      final dataTask = _onuService!.fetchOnuSignal();

      await Future.wait([minTime, dataTask]).then((results) {
        print(
            '[DiagnosticoPage] Future completed. Result type: ${results[1].runtimeType}');
        if (mounted) {
          setState(() {
            _onuData = results[1] as OnuData;
            print(
                '[DiagnosticoPage] Data received: Status=${_onuData?.connectionStatus}, Rx=${_onuData?.signalRx}, Model=${_onuData?.model}');
            _scanning = false;
          });
        }
      });
    } catch (e, stack) {
      print('[DiagnosticoPage] ERROR: $e');
      print('[DiagnosticoPage] STACK: $stack');
      if (mounted) {
        setState(() {
          // Check if it's a known error or generic
          final msg = e.toString().replaceAll('Exception: ', '');
          _errorMessage = msg.isNotEmpty && msg != 'null'
              ? msg
              : 'Não foi possível comunicar com a ONU.\nVerifique se o equipamento está ligado.';
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
        iconTheme: const IconThemeData(color: Layout05Theme.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
          Container(
            height: 160,
            width: 160,
            decoration: BoxDecoration(
              color: Layout05Theme.background,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white,
                  offset: const Offset(-8, -8),
                  blurRadius: 16,
                ),
                BoxShadow(
                  color: const Color(0xFFA3B1C6).withOpacity(0.4),
                  offset: const Offset(8, 8),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  height: 140,
                  width: 140,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Layout05Theme.primary),
                  ),
                ),
                Icon(Icons.router_rounded,
                    size: 56, color: Layout05Theme.textGrey),
              ],
            ),
          ),
          const SizedBox(height: 48),
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
    print(
        '[DiagnosticoPage] Building Results UI. Error: $_errorMessage, Data: ${_onuData != null}');
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 60, color: Layout05Theme.error),
              const SizedBox(height: 16),
              Text(
                'Ops! Algo deu errado.',
                style: Layout05Theme.heading2,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Layout05Theme.bodyText
                    .copyWith(color: Layout05Theme.textGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _runDiagnostics,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('TENTAR NOVAMENTE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Layout05Theme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_onuData == null) {
      return Center(
          child: Text('Aguardando teste...', style: Layout05Theme.bodyText));
    }

    final signal = _onuData!.signalRx;
    final color = _getSignalColor(signal);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        children: [
          // Main Status Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: Layout05Theme.neumorphicDecoration,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Layout05Theme.background,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.white,
                            offset: Offset(-3, -3),
                            blurRadius: 5),
                        BoxShadow(
                            color: Color(0x19000000),
                            offset: Offset(3, 3),
                            blurRadius: 5),
                      ]),
                  child: Icon(Icons.wifi_tethering, size: 56, color: color),
                ),
                const SizedBox(height: 24),
                Text(
                  _getSignalStatus(signal),
                  style: TextStyle(
                      color: color, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text('Sinal Óptico Real', style: Layout05Theme.bodyText),
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
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.4,
            children: [
              _buildDetailCard(
                  Icons.device_hub_rounded, 'Modelo', _onuData!.model),
              _buildDetailCard(Icons.thermostat_rounded, 'Temperatura',
                  '${_onuData!.temperature ?? "N/A"}°C'),
              _buildDetailCard(Icons.bolt_rounded, 'Voltagem',
                  '${_onuData!.voltage ?? "N/A"}V'),
              _buildDetailCard(Icons.info_outline_rounded, 'Status',
                  _onuData!.connectionStatus),
            ],
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _runDiagnostics,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('REFAZER TESTE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Layout05Theme.primary,
                foregroundColor: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
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
        const SizedBox(height: 8),
        Text(value,
            style:
                Layout05Theme.heading2.copyWith(color: Layout05Theme.textDark)),
      ],
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Layout05Theme.flatDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Layout05Theme.textGrey),
              const SizedBox(width: 8),
              Text(label, style: Layout05Theme.label.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: Layout05Theme.heading2.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
