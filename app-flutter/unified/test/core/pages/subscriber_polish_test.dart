import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/pages/shared_meu_ip_page.dart';
import 'package:app_provedor_unified/core/pages/unified_login_page.dart';

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
}
