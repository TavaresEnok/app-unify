import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/pages/shared_contrato_page.dart';
import 'package:app_provedor_unified/core/pages/shared_meu_ip_page.dart';
import 'package:app_provedor_unified/core/pages/unified_login_page.dart';
import 'package:app_provedor_unified/core/widgets/diagnostics/diagnostic_view.dart';

TextEditingValue _type(String text) => CpfCnpjInputFormatter()
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

void main() {
  test('CPF e CNPJ ganham máscara enquanto o assinante digita', () {
    expect(_type('10331142430').text, '103.311.424-30');
    expect(_type('1033').text, '103.3');
    expect(_type('12345678000190').text, '12.345.678/0001-90');
    expect(_type('123456780001901').text, '12.345.678/0001-90');
  });

  test('provedor do IP sai sem número de AS nem sufixo societário', () {
    expect(
        MeuIpPage.organization('AS264000 FLASH NET TELECOMUNICACOES LTDA - ME'),
        'Flash Net Telecomunicacoes');
    expect(MeuIpPage.organization('Vibe Telecom'), 'Vibe Telecom');
  });

  test('valores do diagnóstico usam vírgula decimal sem estragar IPs', () {
    expect(formatDiagnosticValue('2.4 GHz'), '2,4 GHz');
    expect(formatDiagnosticValue('10.0.2.16'), '10.0.2.16');
    expect(formatDiagnosticValue('192.168.0.1 · 8.8.8.8'),
        '192.168.0.1 · 8.8.8.8');
    expect(formatDiagnosticValue('WiFi'), 'Wi-Fi');
    expect(formatDiagnosticValue('v1.0.9 (Build 10)'), 'v1.0.9 (Build 10)');
  });

  test('vencimento do contrato vira o dia do mês em qualquer formato', () {
    expect(ContratoPage.dueDay('Vence em 6/11/2026'), 'Todo dia 6');
    expect(ContratoPage.dueDay('20/11/2026'), 'Todo dia 20');
    expect(ContratoPage.dueDay('2026-11-06'), 'Todo dia 6');
    expect(ContratoPage.dueDay('Mensal'), 'Mensal');
  });
}
