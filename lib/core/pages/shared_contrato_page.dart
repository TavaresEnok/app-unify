import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../layouts/layout_05/theme.dart';

class ContratoPage extends ConsumerWidget {
  const ContratoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configProvider = ref.watch(configurationProvider);
    final authState = ref.watch(authNotifierProvider);
    final usuario = authState.value;
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    final layoutType = configProvider.providerConfig?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06';

    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout05Theme.background;
      appBarColor = Layout05Theme.background;
      appBarTextColor = Layout05Theme.textDark;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
      appBarColor = theme.primaryColor;
      appBarTextColor = Colors.white;
    }

    if (usuario == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('Meu Contrato', style: TextStyle(color: appBarTextColor)),
          backgroundColor: appBarColor,
          iconTheme: IconThemeData(color: appBarTextColor),
        ),
        body: const Center(child: Text('Usuário não logado')),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Meu Contrato', style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card do Cliente
            _buildAdaptiveCard(
              isLayout05: isLayout05,
              isDarkLayout: isDarkLayout,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isLayout05
                            ? Layout05Theme.primary.withValues(alpha: 0.1)
                            : primaryColor.withValues(alpha: 0.1),
                        child: Icon(Icons.person,
                            size: 32,
                            color: isLayout05
                                ? Layout05Theme.primary
                                : primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario.nome,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkLayout
                                    ? Colors.white
                                    : (isLayout05
                                        ? Layout05Theme.textDark
                                        : null),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CPF/CNPJ: ${_formatCpfCnpj(usuario.cpfCnpj)}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: isDarkLayout
                                    ? const Color(0xFF8E8E93)
                                    : (isLayout05
                                        ? Layout05Theme.textGrey
                                        : textTheme.bodySmall?.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card do Plano
            _buildAdaptiveCard(
              isLayout05: isLayout05,
              isDarkLayout: isDarkLayout,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plano Contratado',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkLayout
                            ? Colors.white
                            : (isLayout05 ? Layout05Theme.textDark : null),
                      )),
                  const Divider(height: 24),
                  _buildInfoRow(context,
                      icon: Icons.wifi,
                      label: 'Plano',
                      value: usuario.plano,
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.check_circle_outline,
                      label: 'Status',
                      value: usuario.status,
                      valueColor: _getStatusColor(usuario.status),
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  if (usuario.contratoId != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(context,
                        icon: Icons.tag,
                        label: 'Contrato ID',
                        value: '#${usuario.contratoId}',
                        isLayout05: isLayout05,
                        isDarkLayout: isDarkLayout),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Financeiro
            _buildAdaptiveCard(
              isLayout05: isLayout05,
              isDarkLayout: isDarkLayout,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informações Financeiras',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkLayout
                            ? Colors.white
                            : (isLayout05 ? Layout05Theme.textDark : null),
                      )),
                  const Divider(height: 24),
                  _buildInfoRow(context,
                      icon: Icons.attach_money,
                      label: 'Valor',
                      value: 'R\$ ${usuario.valorFatura}',
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.calendar_today,
                      label: 'Vencimento',
                      value: 'Dia ${usuario.vencimentoFatura}',
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card do Provedor
            if (configProvider.providerConfig != null)
              _buildAdaptiveCard(
                isLayout05: isLayout05,
                isDarkLayout: isDarkLayout,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Provedor',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkLayout
                              ? Colors.white
                              : (isLayout05 ? Layout05Theme.textDark : null),
                        )),
                    const Divider(height: 24),
                    _buildInfoRow(context,
                        icon: Icons.business,
                        label: 'Empresa',
                        value: configProvider.providerConfig!.name,
                        isLayout05: isLayout05,
                        isDarkLayout: isDarkLayout),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveCard(
      {required Widget child,
      required bool isLayout05,
      bool isDarkLayout = false}) {
    if (isDarkLayout) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }
    if (isLayout05) {
      return Container(
        decoration: Layout05Theme.neumorphicDecoration,
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }
    return DashboardCard(child: child);
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      Color? valueColor,
      required bool isLayout05,
      bool isDarkLayout = false}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon,
            size: 20,
            color: isDarkLayout
                ? const Color(0xFF00D9FF)
                : (isLayout05
                    ? Layout05Theme.textGrey
                    : textTheme.bodySmall?.color)),
        const SizedBox(width: 12),
        Text('$label:',
            style: textTheme.bodyMedium?.copyWith(
              color: isDarkLayout
                  ? const Color(0xFF8E8E93)
                  : (isLayout05 ? Layout05Theme.textDark : null),
            )),
        const Spacer(),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ??
                (isDarkLayout
                    ? Colors.white
                    : (isLayout05 ? Layout05Theme.textDark : null)),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ativo':
        return Colors.green;
      case 'bloqueado':
        return Colors.red;
      case 'pendente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatCpfCnpj(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9)}';
    } else if (clean.length == 14) {
      return '${clean.substring(0, 2)}.${clean.substring(2, 5)}.${clean.substring(5, 8)}/${clean.substring(8, 12)}-${clean.substring(12)}';
    }
    return value;
  }
}
