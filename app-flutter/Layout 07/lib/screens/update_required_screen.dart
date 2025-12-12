import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_version_config.dart';

class UpdateRequiredScreen extends StatelessWidget {
  final AppVersionConfig config;
  final String currentVersion;

  const UpdateRequiredScreen({
    super.key,
    required this.config,
    required this.currentVersion,
  });

  Future<void> _openStore(BuildContext context) async {
    final String url =
        Platform.isAndroid ? config.storeUrls.android : config.storeUrls.ios;

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link da loja não configurado')),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Não foi possível abrir a loja';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir loja: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async => false, // Impede fechar com botão voltar
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone de atualização
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Título
                  Text(
                    config.updateMessage.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Mensagem
                  Text(
                    config.updateMessage.message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Info de versões
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildVersionRow(
                          'Versão Atual',
                          currentVersion,
                          Icons.phone_android,
                          colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _buildVersionRow(
                          'Versão Mínima',
                          config.minVersion,
                          Icons.check_circle,
                          colorScheme,
                        ),
                        if (config.latestVersion != config.minVersion) ...[
                          const SizedBox(height: 8),
                          _buildVersionRow(
                            'Última Versão',
                            config.latestVersion,
                            Icons.new_releases,
                            colorScheme,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botão de atualizar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _openStore(context),
                      icon: const Icon(Icons.download_rounded, size: 24),
                      label: Text(
                        config.updateMessage.buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionRow(
    String label,
    String version,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          version,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
