// ARQUIVO: lib/core/services/suporte_service.dart
// DESCRIÇÃO: Serviço para criar tickets de suporte

import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuporteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  SuporteService();

  /// Cria um ticket de suporte
  /// 1. Faz o upload da imagem (se houver) para o Firebase Storage
  /// 2. Cria o documento no Firestore via Cloud Function
  Future<String> createTicket({
    required String subject,
    required String message,
    required XFile? imageFile,
    required String providerId,
    required String providerName,
    required String userEmail,
  }) async {
    String? imageUrl;
    String? requesterUid = FirebaseAuth.instance.currentUser?.uid;

    if (requesterUid == null) {
      throw Exception('Falha na autenticação. Usuário não logado.');
    }

    if (imageFile != null) {
      // Faz upload da imagem
      final fileExtension = imageFile.name.split('.').last;
      final storageRef = _storage.ref().child(
          'ticket_images/$providerId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension');

      await storageRef.putData(await imageFile.readAsBytes());
      imageUrl = await storageRef.getDownloadURL();
    }

    // Cria a requisição para a Cloud Function
    final requestId = _firestore.collection('function_requests').doc().id;
    final requestDocRef =
        _firestore.collection('function_requests').doc(requestId);
    final responseDocRef =
        _firestore.collection('function_responses').doc(requestId);

    try {
      // Envia a requisição
      await requestDocRef.set({
        'type': 'CREATE_TICKET',
        'createdAt': FieldValue.serverTimestamp(),
        'payload': {
          'subject': subject,
          'message': message,
          'providerName': providerName,
          'providerId': providerId,
          'userEmail': userEmail,
          'imageUrl': imageUrl,
          'requesterUid': requesterUid,
        },
      });

      // Aguarda a resposta com timeout de 60 segundos
      final responseSnapshot = await responseDocRef
          .snapshots()
          .firstWhere((snap) => snap.exists)
          .timeout(const Duration(seconds: 60));

      final response = responseSnapshot.data();

      if (response == null || response['completedAt'] == null) {
        throw Exception('Resposta incompleta do servidor.');
      }

      if (response['error'] != null) {
        throw Exception(response['error']);
      }

      return response['result']['ticketId'] ?? 'ID_NÃO_INFORMADO';
    } on TimeoutException {
      throw TimeoutException(
          'O servidor demorou muito para processar o ticket.');
    } catch (e) {
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Erro de permissão. Seu login pode estar inválido.');
      }
      rethrow;
    }
  }
}
