import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Um aviso de instabilidade/manutenção publicado pelo provedor.
@immutable
class ProviderIncident {
  final String id;
  final String title;
  final String message;
  final String? area;

  const ProviderIncident({
    required this.id,
    required this.title,
    required this.message,
    this.area,
  });

  factory ProviderIncident.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ProviderIncident(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title'] as String
          : 'Instabilidade identificada',
      message: (data['message'] as String?)?.trim() ??
          'Nossa equipe já está atuando para normalizar.',
      area: (data['area'] as String?)?.trim().isNotEmpty == true
          ? data['area'] as String
          : null,
    );
  }
}

/// Consulta os avisos de instabilidade ativos do provedor.
///
/// Sustenta a proatividade (§ estudo 4.3): antes de deixar o cliente abrir um
/// chamado por algo que o provedor já conhece, o app avisa "já sabemos, equipe
/// atuando" — evitando dezenas de chamados do mesmo problema.
class IncidentService {
  final FirebaseFirestore _firestore;

  IncidentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Retorna o aviso ativo mais recente do provedor, ou null. Best-effort:
  /// qualquer falha (permissão, offline, índice ausente) resolve para null e o
  /// app segue normalmente.
  Future<ProviderIncident?> activeIncident(String providerId) async {
    try {
      final snapshot = await _firestore
          .collection('provedores')
          .doc(providerId)
          .collection('incidents')
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return ProviderIncident.fromDoc(snapshot.docs.first);
    } catch (e) {
      debugPrint('[Instabilidade] Falha ao consultar avisos: $e');
      return null;
    }
  }
}
