import 'dart:async';
import 'package:app_provedor/shared/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:app_provedor/shared/widgets/app_page.dart';
import 'package:app_provedor/shared/widgets/app_button.dart';

enum SpeedTestStatus { initial, testing, completed, error }

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  final internetSpeedTest = FlutterInternetSpeedTest();
  
  SpeedTestStatus _status = SpeedTestStatus.initial;
  String _testInProgress = '';
  double _downloadRate = 0;
  double _uploadRate = 0;
  String? _errorMessage;

  final List<FlSpot> _downloadHistory = [];
  final List<FlSpot> _uploadHistory = [];
  int _downloadIndex = 0;
  int _uploadIndex = 0;

  @override
  void dispose() {
    // Cancela o teste se estiver rodando ao sair da tela
    internetSpeedTest.cancelTest();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _status = SpeedTestStatus.initial;
      _testInProgress = '';
      _downloadRate = 0;
      _uploadRate = 0;
      _errorMessage = null;
      _downloadHistory.clear();
      _uploadHistory.clear();
      _downloadIndex = 0;
      _uploadIndex = 0;
    });
  }

  void _startTest() {
    _reset();
    setState(() {
      _status = SpeedTestStatus.testing;
    });

    internetSpeedTest.startTesting(
      onStarted: () {
        if (!mounted) return;
        setState(() => _testInProgress = 'Conectando...');
      },
      onProgress: (double percent, TestResult data) {
        if (!mounted) return;
        setState(() {
          switch (data.type) {
            case TestType.download:
              _testInProgress = 'Baixando...';
              _downloadRate = data.transferRate;
              _downloadHistory.add(FlSpot(_downloadIndex.toDouble(), data.transferRate));
              _downloadIndex++;
              break;
            case TestType.upload:
              _testInProgress = 'Enviando...';
              _uploadRate = data.transferRate;
              _uploadHistory.add(FlSpot(_uploadIndex.toDouble(), data.transferRate));
              _uploadIndex++;
              break;
          }
        });
      },
      onCompleted: (TestResult download, TestResult upload) {
        if (!mounted) return;
        setState(() {
          _status = SpeedTestStatus.completed;
          _testInProgress = 'Concluído';
          _downloadRate = download.transferRate;
          _uploadRate = upload.transferRate;
        });
      },
      onError: (String errorMessage, String speedTestError) {
        if (!mounted) return;
        setState(() {
          _status = SpeedTestStatus.error;
          _errorMessage = errorMessage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppPage(
      title: 'Teste de Velocidade',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                _buildResultDisplay(textTheme),
                const SizedBox(height: 32),
                _buildSparkLineChart(),
              ],
            ),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultDisplay(TextTheme textTheme) {
    return Column(
      children: [
        Text(_testInProgress, style: textTheme.headlineSmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStat('Download', _downloadRate, 'Mbps'),
            _buildStat('Upload', _uploadRate, 'Mbps'),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(String title, double value, String unit) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(title, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(value.toStringAsFixed(1), style: textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(unit, style: textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildSparkLineChart() {
    final bool isTesting = _status == SpeedTestStatus.testing;
    final primaryColor = Theme.of(context).primaryColor;

    return SizedBox(
      height: 100,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            _buildLine(
              _downloadHistory,
              isTesting && _testInProgress == 'Baixando...' ? primaryColor : Colors.grey,
            ),
            _buildLine(
              _uploadHistory,
              isTesting && _testInProgress == 'Enviando...' ? Colors.cyan : Colors.grey,
            ),
          ],
        ),
        duration: const Duration(milliseconds: 150),
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> data, Color color) {
    return LineChartBarData(
      spots: data.length > 1 ? data : [const FlSpot(0, 0), const FlSpot(1, 0)],
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    String label = 'Iniciar Teste';
    IconData icon = Icons.play_arrow;
    VoidCallback? action = _startTest;

    if (_status == SpeedTestStatus.testing) {
      label = _testInProgress;
      icon = Icons.hourglass_empty;
      action = null;
    } else if (_status == SpeedTestStatus.completed || _status == SpeedTestStatus.error) {
      label = 'Testar Novamente';
      icon = Icons.refresh;
      action = _resetAndTest;
    }

    return Column(
      children: [
        if (_status == SpeedTestStatus.error)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text('Erro: ${_errorMessage ?? "Não foi possível concluir o teste."}', style: const TextStyle(color: AppColors.error)),
          ),
        AppButton(label: label, onPressed: action, icon: icon, isLoading: _status == SpeedTestStatus.testing),
      ],
    );
  }

  void _resetAndTest() {
    _reset();
    Future.delayed(const Duration(milliseconds: 100), _startTest);
  }
}
