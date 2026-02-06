// ARQUIVO: lib/promessa_pagamento.dart (MIGRADO PARA CONSUMO VIA PROVIDER)

import 'package:app_provedor/models/provider_config.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // Para TimeoutException
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart'; // <-- NOVO
import 'utils.dart';
import 'services/promessa_service.dart';
import 'configuration_provider.dart'; // <-- NOVO

enum PromiseState {
  eligible,
  notEligible,
  loading,
  success,
  error,
}

class PromessaPagamentoPage extends StatefulWidget {
  final String? status;
  final String cpfCnpj;
  // REMOVIDO: final Map<String, dynamic> providerConfig;

  const PromessaPagamentoPage({
    super.key,
    this.status,
    required this.cpfCnpj,
    // REMOVIDO: required this.providerConfig,
  });

  @override
  State<PromessaPagamentoPage> createState() => _PromessaPagamentoPageState();
}

class _PromessaPagamentoPageState extends State<PromessaPagamentoPage> {
  PromiseState _currentState = PromiseState.eligible;
  String _message = '';
  late final Color primaryColor;
  late final PromessaService _service;

  // Variável para armazenar a configuração localmente
  late final ProviderConfig _providerConfig;

  @override
  void initState() {
    super.initState();

    // Acessa a configuração do provedor (ConfigurationProvider)
    _providerConfig = Provider.of<ConfigurationProvider>(context, listen: false)
        .providerConfig!;

    primaryColor = hexToColor(_providerConfig.config.themeColor);

    // --- Configuração do Serviço ---
    final String baseUrl = _providerConfig.apiUrl;
    final String apiUrl = '$baseUrl/make-payment-promise';

    final sgpParams = {
      "token": _providerConfig.config.integrations.apiToken,
      "app": _providerConfig.config.integrations.appName,
      "sgpBaseUrl": _providerConfig.config.integrations.sgpBaseUrl
    };

    _service = PromessaService(
      apiUrl: apiUrl,
      sgpParams: sgpParams,
      cpfCnpj: widget.cpfCnpj,
    );
    // --- Fim da Configuração ---

    // Lógica de elegibilidade (opcional, se status não for passado assume elegível para tentar)
    if (widget.status != null) {
      final bool isEligible =
          widget.status == 'Suspenso' || widget.status == 'Ativo V. Reduzida';
      if (!isEligible) {
        _currentState = PromiseState.notEligible;
        _message =
            "Esta opção está disponível apenas para contratos suspensos ou com velocidade reduzida.";
      }
    }
  }

  Future<void> _makePromise() async {
    setState(() {
      _currentState = PromiseState.loading;
    });
    try {
      // Chama o serviço
      final successMessage = await _service.makePaymentPromise();
      setState(() {
        _currentState = PromiseState.success;
        _message = successMessage;
      });
    } catch (e) {
      setState(() {
        _currentState = PromiseState.error;
        // Pega a mensagem de erro tratada do service
        _message = (e is TimeoutException)
            ? 'O servidor demorou muito para responder.'
            : e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Promessa de Pagamento"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentState) {
      case PromiseState.loading:
        return CircularProgressIndicator(color: primaryColor);
      case PromiseState.success:
        return _buildStatusCard(
          icon: Icons.check_circle_outline,
          color: Colors.green.shade700,
          title: "Sucesso!",
          message: _message,
        );
      case PromiseState.error:
      case PromiseState.notEligible:
        return _buildStatusCard(
          icon: Icons.error_outline,
          color: Colors.red.shade700,
          title: "Atenção!",
          message: _message,
        );
      case PromiseState.eligible:
        return _buildPromiseUI();
    }
  }

  Widget _buildPromiseUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FaIcon(FontAwesomeIcons.handshake, size: 80, color: primaryColor),
        const SizedBox(height: 24),
        const Text(
          "Desbloqueio por Confiança",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          "Ao confirmar, sua conexão será reestabelecida temporariamente por um período de 48 horas para que você possa regularizar sua situação.",
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.5),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _makePromise,
          icon: const Icon(Icons.lock_open, color: Colors.white),
          label: const Text("Confirmar Promessa",
              style: TextStyle(color: Colors.white, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
      {required IconData icon,
      required Color color,
      required String title,
      required String message}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: Colors.grey.shade800, height: 1.4),
          ),
        ],
      ),
    );
  }
}
