// Layout 02 - Página de Consumo de Internet
import 'package:flutter/material.dart';

class ConsumoPage extends StatefulWidget {
  const ConsumoPage({super.key});

  @override
  State<ConsumoPage> createState() => _ConsumoPageState();
}

class _ConsumoPageState extends State<ConsumoPage> {
  bool _isLoading = true;
  String? _error;
  double _usedGb = 0;
  double _totalGb = 0;
  String _planName = '';
  String _period = '';

  @override
  void initState() {
    super.initState();
    _loadConsumptionData();
  }

  Future<void> _loadConsumptionData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simula carregamento - substitua por chamada real à API
      await Future.delayed(const Duration(seconds: 1));

      // TODO: Implementar chamada ao ConsumoService
      // Por enquanto, usa dados mockados
      setState(() {
        _usedGb = 45.5;
        _totalGb = 100.0;
        _planName = 'Plano 100MB';
        _period = 'Dezembro 2024';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadConsumptionData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final percentage = _totalGb > 0 ? (_usedGb / _totalGb) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card principal com gráfico circular
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Consumo de Internet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _period,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Gráfico circular
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: percentage,
                          strokeWidth: 16,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percentage > 0.9
                                ? Colors.red
                                : percentage > 0.7
                                    ? Colors.orange
                                    : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_usedGb.toStringAsFixed(1)} GB',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'de ${_totalGb.toStringAsFixed(0)} GB',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}% utilizado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: percentage > 0.9
                        ? Colors.red
                        : percentage > 0.7
                            ? Colors.orange
                            : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Card com detalhes do plano
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalhes do Plano',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(theme, 'Plano', _planName),
                _buildDetailRow(
                    theme, 'Franquia', '${_totalGb.toStringAsFixed(0)} GB'),
                _buildDetailRow(
                    theme, 'Consumido', '${_usedGb.toStringAsFixed(1)} GB'),
                _buildDetailRow(theme, 'Disponível',
                    '${(_totalGb - _usedGb).toStringAsFixed(1)} GB'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar consumo',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Erro desconhecido',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadConsumptionData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
