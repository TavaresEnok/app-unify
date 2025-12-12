// ARQUIVO: lib/services/suporte_service.dart

import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuporteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // URL da função que cria o ticket (será substituída pela Cloud Function)
  // Como estamos no Flutter, vamos usar o mecanismo de function_requests.

  SuporteService();

  /// 1. Faz o upload da imagem (se houver) para o Firebase Storage.
  /// 2. Chama a Cloud Function para criar o ticket no Firestore.
  /// Retorna o ID do ticket criado.
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
      // Cria a referência no Storage
      final fileExtension = imageFile.name.split('.').last;
      final storageRef = _storage.ref().child(
          'ticket_images/$providerId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension');

      // Faz o upload
      await storageRef.putData(await imageFile.readAsBytes());

      // Pega a URL de download
      imageUrl = await storageRef.getDownloadURL();
      print("✅ Imagem de ticket enviada para: $imageUrl");
    }

    // --- 2. Chama a Cloud Function para criar o ticket ---
    final requestId = _firestore.collection('function_requests').doc().id;
    final requestDocRef =
        _firestore.collection('function_requests').doc(requestId);
    final responseDocRef =
        _firestore.collection('function_responses').doc(requestId);

    try {
      // 2.1 Envia a requisição
      await requestDocRef.set({
        'type': 'CREATE_TICKET',
        'createdAt': FieldValue.serverTimestamp(),
        'payload': {
          'subject': subject,
          'message': message,
          'providerName': providerName,
          'providerId': providerId,
          'userEmail': userEmail,
          'imageUrl': imageUrl, // A URL da imagem
          'requesterUid': requesterUid,
        },
      });

      // 2.2 Aguarda a resposta (usando Future para timeout)
      // AUMENTADO O TIMEOUT PARA 60 SEGUNDOS
      final responseSnapshot = await responseDocRef
          .snapshots()
          .firstWhere((snap) => snap.exists, orElse: () {
        throw TimeoutException('O servidor demorou para responder.');
      }).timeout(const Duration(seconds: 60));

      final response = responseSnapshot.data();

      if (response == null || response['completedAt'] == null) {
        throw Exception('Resposta incompleta do servidor.');
      }

      if (response['error'] != null) {
        throw Exception(response['error']);
      }

      // Retorna o ID do ticket
      return response['result']['ticketId'] ?? 'ID_NÃO_INFORMADO';
    } on TimeoutException {
      throw TimeoutException(
          'O servidor demorou muito para processar o ticket.');
    } catch (e) {
      print("❌ Erro no SuporteService: $e");
      // Se for um erro técnico, transforma em mensagem amigável
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Erro de permissão. Seu login pode estar inválido.');
      }
      rethrow;
    }
  }
}
