import 'dart:async';
import 'dart:io';

// Service para testes de rede locais
class NetworkTestService {
  /// Medir latência (ping) em milissegundos
  Future<double?> measureLatency({String host = '8.8.8.8'}) async {
    try {
      final stopwatch = Stopwatch()..start();

      final socket =
          await Socket.connect(host, 53, timeout: const Duration(seconds: 5));
      socket.destroy();

      stopwatch.stop();
      return stopwatch.elapsedMicroseconds / 1000; // Converter para ms
    } catch (e) {
      print('❌ Erro ao medir latência: $e');
      return null;
    }
  }

  /// Verificar se DNS está funcionando
  Future<bool> checkDNS() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty;
    } catch (e) {
      print('❌ Erro ao verificar DNS: $e');
      return false;
    }
  }

  /// Teste de velocidade simplificado (download)
  /// Retorna velocidade em Mbps
  Future<double?> measureDownloadSpeed() async {
    try {
      // URL de teste pequena (~1MB)
      final testUrl = 'https://speed.cloudflare.com/__down?bytes=1000000';

      final client = HttpClient();
      final stopwatch = Stopwatch()..start();

      final request = await client
          .getUrl(Uri.parse(testUrl))
          .timeout(const Duration(seconds: 10));
      final response = await request.close();

      int totalBytes = 0;
      await for (var data in response) {
        totalBytes += data.length;
      }

      stopwatch.stop();
      client.close();

      // Calcular Mbps
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final mbits = (totalBytes * 8) / 1000000;
      return mbits / seconds;
    } catch (e) {
      print('❌ Erro ao medir velocidade: $e');
      return null;
    }
  }

  /// Teste de upload simplificado
  Future<double?> measureUploadSpeed() async {
    // Por enquanto retorna estimativa baseada no download
    // Implementação completa requer servidor de teste
    final download = await measureDownloadSpeed();
    return download != null ? download * 0.5 : null;
  }
}
