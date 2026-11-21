import 'package:app_provedor_unified/core/models/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('situação contratual prevalece sobre estado online e é persistida', () {
    final user = Usuario(
        nome: 'Nome Completo',
        cpfCnpj: '123',
        senha: '',
        plano: '',
        status: 'Online',
        contractStatus: 'Suspenso',
        valorFatura: '',
        vencimentoFatura: '');
    expect(user.isSuspended, isTrue);
    expect(Usuario.fromJson(user.toJson()).isSuspended, isTrue);
  });

  test('sessão antiga recupera situação do status legado', () {
    final user = Usuario(
        nome: '',
        cpfCnpj: '',
        senha: '',
        plano: '',
        status: 'Bloqueado',
        valorFatura: '',
        vencimentoFatura: '');
    expect(user.isSuspended, isTrue);
  });
}
