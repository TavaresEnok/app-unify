import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_data.dart';
import 'robust_api_service.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Enviar feedback para o Firestore com retry
  Future<bool> submitFeedback({
    required FeedbackData feedback,
    required String providerId,
    String? userId,
  }) async {
    try {
      debugPrint('📝 Enviando feedback para Firestore...');

      // Usar retry logic para operação robusta
      await RobustApiService.executeWithRetry(() async {
        await _firestore.collection('feedbacks').add({
          'providerId': providerId,
          'userId': userId ?? 'anonymous',
          'rating': feedback.rating,
          'npsScore': feedback.npsScore,
          'message': feedback.message,
          'timestamp': FieldValue.serverTimestamp(),
          'platform': 'flutter',
          'appVersion': feedback.appVersion,
          'categories': feedback.categories,
        });
      });

      debugPrint('✅ Feedback enviado com sucesso!');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao enviar feedback: $e');
      return false;
    }
  }

  /// Buscar feedbacks de um provedor (opcional - para analytics)
  Future<List<Map<String, dynamic>>> getFeedbacks(String providerId) async {
    try {
      final snapshot = await _firestore
          .collection('feedbacks')
          .where('providerId', isEqualTo: providerId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar feedbacks: $e');
      return [];
    }
  }

  /// Calcular estatísticas de feedback
  Future<Map<String, dynamic>> getStatistics(String providerId) async {
    try {
      final feedbacks = await getFeedbacks(providerId);

      if (feedbacks.isEmpty) {
        return {
          'totalFeedbacks': 0,
          'averageRating': 0.0,
          'averageNps': 0.0,
        };
      }

      double totalRating = 0;
      double totalNps = 0;
      int ratingCount = 0;
      int npsCount = 0;

      for (final fb in feedbacks) {
        if (fb['rating'] != null) {
          totalRating += (fb['rating'] as num).toDouble();
          ratingCount++;
        }
        if (fb['npsScore'] != null) {
          totalNps += (fb['npsScore'] as num).toDouble();
          npsCount++;
        }
      }

      return {
        'totalFeedbacks': feedbacks.length,
        'averageRating': ratingCount > 0 ? totalRating / ratingCount : 0.0,
        'averageNps': npsCount > 0 ? totalNps / npsCount : 0.0,
      };
    } catch (e) {
      debugPrint('❌ Erro ao calcular estatísticas: $e');
      return {
        'totalFeedbacks': 0,
        'averageRating': 0.0,
        'averageNps': 0.0,
      };
    }
  }
}
