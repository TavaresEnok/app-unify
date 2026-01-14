import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/services/meu_ip_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../layouts/layout_03/theme.dart';

class MeuIpPage extends ConsumerStatefulWidget {
  const MeuIpPage({super.key});

  @override
  ConsumerState<MeuIpPage> createState() => _MeuIpPageState();
}

class _MeuIpPageState extends ConsumerState<MeuIpPage> {
  late Future<Map<String, dynamic>> _ipFuture;
  final MeuIpService _service = MeuIpService();

  @override
  void initState() {
    super.initState();
    _ipFuture = _service.fetchIpInfo();
  }

  void _retry() {
    setState(() {
      _ipFuture = _service.fetchIpInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = ref.watch(configurationProvider);
    final layoutType = configProvider.providerConfig?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_04';

    final theme = Theme.of(context);
    Color backgroundColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
    }

    // Retorna apenas o conteúdo - PainelPage já fornece Scaffold e AppBar
    return Container(
      color: backgroundColor,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _ipFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      _formatErrorMessage(snapshot.error),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            return _buildIpInfoCard(context, snapshot.data!, isLayout05,
                isDarkLayout: isDarkLayout);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatErrorMessage(Object? error) {
    if (error is TimeoutException) {
      return 'O servidor demorou muito para responder. Por favor, tente novamente.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Widget _buildIpInfoCard(
      BuildContext context, Map<String, dynamic> ipData, bool isLayout05,
      {bool isDarkLayout = false}) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    final decoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05
            ? Layout03Theme.neumorphicDecoration
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4)),
                ],
              ));

    final highlightColor = isDarkLayout
        ? const Color(0xFF00D9FF)
        : (isLayout05 ? Layout03Theme.primary : primaryColor);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: decoration,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 48, color: highlightColor),
                  const SizedBox(height: 16),
                  Text("Seu IP Público é:",
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDarkLayout
                            ? const Color(0xFF8E8E93)
                            : (isLayout05 ? Layout03Theme.textGrey : null),
                      )),
                  const SizedBox(height: 8),
                  Text(
                    ipData['ip'] ?? 'Não encontrado',
                    style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold, color: highlightColor),
                  ),
                  Divider(
                      height: 40,
                      color: isLayout05 ? Colors.transparent : null),
                  _buildInfoRow(context,
                      icon: Icons.location_city,
                      title: "Localização",
                      value:
                          "${ipData['city'] ?? 'N/A'}, ${ipData['region'] ?? 'N/A'}",
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.public,
                      title: "País",
                      value: ipData['country'] ?? 'N/A',
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.router,
                      title: "Provedor",
                      value: ipData['org'] ?? 'Não encontrado',
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.access_time,
                      title: "Fuso Horário",
                      value: ipData['timezone'] ?? 'N/A',
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: isLayout05
                        ? ElevatedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Atualizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Layout03Theme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Atualizar'),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 180), // Padding for BottomNav
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon,
      required String title,
      required String value,
      bool isLayout05 = false,
      bool isDarkLayout = false}) {
    final textTheme = Theme.of(context).textTheme;
    final color = isDarkLayout
        ? Colors.white
        : (isLayout05 ? Layout03Theme.textDark : null);
    final iconColor = isDarkLayout
        ? const Color(0xFF00D9FF)
        : (isLayout05 ? Layout03Theme.primary : textTheme.bodySmall?.color);

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 16),
        Text("$title:",
            style: textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(color: color))),
      ],
    );
  }
}
