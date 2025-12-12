import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/configuration_provider.dart';
// import '../../core/services/onu_wifi_service.dart'; // TODO: Enable
import 'theme.dart';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage>
    with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  Map<String, dynamic>? _onuData;

  @override
  void initState() {
    super.initState();
    _startDiagnosis();
  }

  void _startDiagnosis() {
    setState(() {
      _isScanning = true;
      _onuData = null;
    });

    // Simulando delay de rede/hardware
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          // Mock Data
          _onuData = {
            'signalRx': -19.5,
            'signalTx': 2.4,
            'temp': 42.0,
            'voltage': 3.3,
            'status': 'Online',
            'onuId': '101',
            'model': 'Huawei HG8245Q2'
          };
        });
      }
    });
  }

  Color _getSignalColor(double signal) {
    if (signal > -25) return Layout05Theme.success;
    if (signal > -27) return Layout05Theme.warning;
    return Layout05Theme.error;
  }

  String _getSignalStatus(double signal) {
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
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startDiagnosis,
          ),
        ],
      ),
      body: _isScanning ? _buildScanningUI() : _buildResultsUI(),
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
          const Text(
            'Verificando sinal óptico e status da ONU.\nIsso pode levar alguns segundos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Layout05Theme.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsUI() {
    if (_onuData == null)
      return const Center(child: Text('Erro ao obter dados.'));

    final signal = _onuData!['signalRx'] as double;
    final color = _getSignalColor(signal);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: Layout05Theme.cardDecoration,
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
                    _buildMiniStat('Download', '${_onuData!['signalRx']} dBm'),
                    _buildMiniStat('Upload', '${_onuData!['signalTx']} dBm'),
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
              _buildDetailCard(Icons.device_hub, 'Modelo', _onuData!['model']),
              _buildDetailCard(
                  Icons.thermostat, 'Temperatura', '${_onuData!['temp']}°C'),
              _buildDetailCard(
                  Icons.bolt, 'Voltagem', '${_onuData!['voltage']}V'),
              _buildDetailCard(
                  Icons.info_outline, 'Status', _onuData!['status']),
            ],
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _startDiagnosis,
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
        Text(label,
            style:
                const TextStyle(color: Layout05Theme.textGrey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Layout05Theme.textDark)),
      ],
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Layout05Theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Layout05Theme.textGrey),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Layout05Theme.textGrey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Layout05Theme.textDark)),
        ],
      ),
    );
  }
}
