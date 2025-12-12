import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layout01/shared/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:layout01/configuration_provider.dart';
import 'package:layout01/utils.dart';
import 'package:fl_chart/fl_chart.dart';

enum SpeedTestStatus { initial, testing, completed, error }

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> with SingleTickerProviderStateMixin {
  final internetSpeedTest = FlutterInternetSpeedTest();

  SpeedTestStatus _status = SpeedTestStatus.initial;
  String _currentStep = ''; // 'Download' ou 'Upload'
  double _currentRate = 0; // Velocidade em tempo real
  double _downloadResult = 0;
  double _uploadResult = 0;
  
  // Variáveis para o gráfico
  final List<FlSpot> _downloadSpots = [];
  final List<FlSpot> _uploadSpots = [];
  double _maxX = 0;

  late AnimationController _gaugeController;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    internetSpeedTest.cancelTest(); // Garante que o teste pare ao sair
    super.dispose();
  }

  void _updateGauge(double value) {
    // Anima o ponteiro para o novo valor (0 a 1000 Mbps)
    // Normalizando: 0 Mbps = 0.0, 1000 Mbps = 1.0
    final normalized = (value / 1000).clamp(0.0, 1.0);
    _gaugeController.animateTo(normalized, duration: const Duration(milliseconds: 300));
  }

  void _reset() {
    setState(() {
      _status = SpeedTestStatus.initial;
      _currentStep = '';
      _currentRate = 0;
      _downloadResult = 0;
      _uploadResult = 0;
      _downloadSpots.clear();
      _uploadSpots.clear();
      _maxX = 0;
    });
    _updateGauge(0);
  }

  void _startTest() {
    _reset();
    setState(() => _status = SpeedTestStatus.testing);

    internetSpeedTest.startTesting(
      onStarted: () {
        setState(() => _currentStep = 'Iniciando...');
      },
      onProgress: (double percent, TestResult data) {
        setState(() {
          _currentRate = data.transferRate;
          _maxX++;
          
          if (data.type == TestType.download) {
            _currentStep = 'Testando Download';
            _downloadResult = data.transferRate;
            _downloadSpots.add(FlSpot(_maxX, data.transferRate));
          } else {
            _currentStep = 'Testando Upload';
            _uploadResult = data.transferRate;
            _uploadSpots.add(FlSpot(_maxX, data.transferRate));
          }
        });
        _updateGauge(data.transferRate);
      },
      onCompleted: (TestResult download, TestResult upload) {
        setState(() {
          _status = SpeedTestStatus.completed;
          _currentStep = 'Teste Concluído';
          _currentRate = 0;
          _downloadResult = download.transferRate;
          _uploadResult = upload.transferRate;
        });
        _updateGauge(0);
      },
      onError: (String errorMessage, String speedTestError) {
        setState(() {
          _status = SpeedTestStatus.error;
        });
        _updateGauge(0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $errorMessage')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerConfig = context.watch<ConfigurationProvider>().providerConfig;
    final actionColor = (providerConfig?.config.actionColor != null)
        ? hexToColor(providerConfig!.config.actionColor!)
        : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Velocidade', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView( // Adicionado Scroll para evitar overflow
          child: Column(
            children: [
              const SizedBox(height: 20),
      
              // GAUGE (Velocímetro)
              SizedBox(
                height: 200,
                width: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 15,
                        color: Colors.grey.shade100,
                      ),
                    ),
                    AnimatedBuilder(
                        animation: _gaugeController,
                        builder: (context, child) {
                          return SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: _gaugeController.value,
                              strokeWidth: 15,
                              strokeCap: StrokeCap.round,
                              color: _currentStep.contains('Upload') ? Colors.cyan : actionColor,
                            ),
                          );
                        }
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _status == SpeedTestStatus.testing ? _currentRate.toStringAsFixed(0) : 'GO',
                          style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        Text(
                          _status == SpeedTestStatus.testing ? 'Mbps' : '',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      
              const SizedBox(height: 30),
      
              // STATUS
              Text(
                _status == SpeedTestStatus.initial ? 'Toque em Iniciar' : _currentStep,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
      
              const SizedBox(height: 30),

              // GRÁFICO EM TEMPO REAL
              if (_status == SpeedTestStatus.testing || _status == SpeedTestStatus.completed)
                Container(
                  height: 150,
                  width: double.infinity,
                  padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: _maxX > 50 ? _maxX : 50, // Garante um mínimo de largura
                      minY: 0,
                      // Adiciona uma margem superior para o gráfico não cortar
                      maxY: (_currentRate > _downloadResult ? _currentRate : (_downloadResult > _uploadResult ? _downloadResult : _uploadResult)) * 1.2,
                      lineBarsData: [
                        // Linha de Download
                        LineChartBarData(
                          spots: _downloadSpots,
                          isCurved: true,
                          color: actionColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: actionColor.withOpacity(0.1)),
                        ),
                        // Linha de Upload
                        LineChartBarData(
                          spots: _uploadSpots,
                          isCurved: true,
                          color: Colors.cyan,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: Colors.cyan.withOpacity(0.1)),
                        ),
                      ],
                    ),
                  ),
                ),
      
              const SizedBox(height: 30),
      
              // RESULTADOS (CARDS)
              Row(
                children: [
                  Expanded(
                    child: _ResultCard(
                      title: 'Download',
                      value: _downloadResult,
                      icon: Icons.arrow_downward_rounded,
                      color: actionColor,
                      isActive: _currentStep.contains('Download'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ResultCard(
                      title: 'Upload',
                      value: _uploadResult,
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.cyan,
                      isActive: _currentStep.contains('Upload'),
                    ),
                  ),
                ],
              ),
      
              const SizedBox(height: 40),
      
              // BOTÃO DE AÇÃO
              if (_status != SpeedTestStatus.testing)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _status == SpeedTestStatus.initial ? 'INICIAR TESTE' : 'TESTAR NOVAMENTE',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
      
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final bool isActive;

  const _ResultCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? color : Colors.grey.shade200, width: isActive ? 2 : 1),
          boxShadow: [
            if (isActive)
              BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  value.toStringAsFixed(0),
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('Mbps', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
