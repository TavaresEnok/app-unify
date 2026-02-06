// ARQUIVO: lib/utils.dart

import 'package:flutter/material.dart';

Color hexToColor(String hexString) {
  try {
    final buffer = StringBuffer();
    if (hexString.length >= 6) buffer.write('ff');

    // MUDANÇA AQUI: Adicionado .trim() para remover espaços
    buffer.write(hexString.trim().replaceAll('#', ''));

    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    // Retorna uma cor padrão em caso de erro de formatação
    print('Erro ao converter hex para cor: $e, String: "$hexString"');
    return const Color(0xFF673AB7);
  }
}
