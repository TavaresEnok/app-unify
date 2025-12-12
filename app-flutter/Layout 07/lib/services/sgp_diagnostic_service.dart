import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/onu_signal_data.dart';

// Service para integração com SGP API (diagnóstico)
class SGPDiagnosticService {
  final String baseUrl;
  final String token;
  final String appName;

  SGPDiagnosticService({
    required this.baseUrl,
    required this.token,
    required this.appName,
  });

  /// Buscar informações da ONU incluindo sinal
  Future<OnuSignalData?> getOnuSignal({
    required String cpfCnpj,
    required int contractId,
  }) async {
    try {
      print('🔍 Buscando sinal ONU para contrato $contractId...');

      final response = await http.post(
        Uri.parse('$baseUrl/api/fttx/onu/list/'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'token': token,
          'app': appName,
          'cpfcnpj': cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
          'contrato': contractId.toString(),
          'signal': '1', // Pedir informação de sinal
          'connection': '1', // Pedir status de conexão
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          final onu = data[0];

          // Extrair sinal RX/TX
          final double signalRx = _parseSignal(onu['signal']?['rx']);
          final double signalTx = _parseSignal(onu['signal']?['tx']);

          print('✅ Sinal ONU obtido: RX=$signalRx dBm, TX=$signalTx dBm');

          return OnuSignalData(
            signalRx: signalRx,
            signalTx: signalTx,
            connectionStatus: onu['connection']?.toString() ?? 'unknown',
            oltId: onu['olt_id'] as int?,
            slot: onu['slot'] as int?,
            pon: onu['pon'] as int?,
            onuId: onu['onuid'] as int?,
          );
        } else {
          print('⚠️ Nenhuma ONU encontrada na resposta');
          return null;
        }
      } else {
        print('❌ Erro SGP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao buscar sinal ONU: $e');
      return null;
    }
  }

  /// Parser seguro de sinal (pode vir em vários formatos)
  double _parseSignal(dynamic signalValue) {
    if (signalValue == null) return -999.0;

    if (signalValue is num) {
      return signalValue.toDouble();
    }

    if (signalValue is String) {
      // Remove espaços e tenta parsear
      final cleaned = signalValue.trim().replaceAll(' ', '');
      return double.tryParse(cleaned) ?? -999.0;
    }

    return -999.0;
  }

  /// Verificar status de acesso (manutenção, bloqueio, etc)
  Future<Map<String, dynamic>?> verifyAccessStatus({
    required int contractId,
  }) async {
    try {
      print('🔍 Verificando status de acesso...');

      final response = await http.post(
        Uri.parse('$baseUrl/ws/ura/verificaacesso/'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'token': token,
          'app': appName,
          'contrato': contractId.toString(),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Status de acesso obtido');
        return data as Map<String, dynamic>;
      } else {
        print('❌ Erro ao verificar acesso: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao verificar acesso: $e');
      return null;
    }
  }
}
