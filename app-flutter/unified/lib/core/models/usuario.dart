class Usuario {
  final String nome;
  final String cpfCnpj;
  final String senha;
  final String plano;
  final String status;
  final String valorFatura;
  final String vencimentoFatura;
  final String? email;
  final int? contratoId;

  Usuario({
    required this.nome,
    required this.cpfCnpj,
    required this.senha,
    required this.plano,
    required this.status,
    required this.valorFatura,
    required this.vencimentoFatura,
    this.email,
    this.contratoId,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      nome: json['nome'] as String,
      cpfCnpj: json['cpfCnpj'] as String,
      senha: json['senha'] as String,
      plano: json['plano'] as String,
      status: json['status'] as String,
      valorFatura: json['valorFatura'] as String,
      vencimentoFatura: json['vencimentoFatura'] as String,
      email: json['email'] as String?,
      contratoId: json['contratoId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cpfCnpj': cpfCnpj,
      'senha': senha,
      'plano': plano,
      'status': status,
      'valorFatura': valorFatura,
      'vencimentoFatura': vencimentoFatura,
      'email': email,
      'contratoId': contratoId,
    };
  }
}
