import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/theme_config.dart';

class ThemeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Carrega o tema customizado do provedor do Firestore
  Future<ThemeConfig> loadTheme(String providerId) async {
    try {
      final doc =
          await _firestore.collection('provedores').doc(providerId).get();

      if (doc.exists && doc.data()?['theme'] != null) {
        return ThemeConfig.fromJson(
            doc.data()!['theme'] as Map<String, dynamic>);
      }

      print('Tema não encontrado para $providerId, usando tema padrão');
      return ThemeConfig.defaultTheme;
    } catch (e) {
      print('Erro ao carregar tema: $e');
      return ThemeConfig.defaultTheme;
    }
  }

  /// Stream para ouvir mudanças em tempo real
  Stream<ThemeConfig> watchTheme(String providerId) {
    return _firestore
        .collection('provedores')
        .doc(providerId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data()?['theme'] != null) {
        return ThemeConfig.fromJson(
            doc.data()!['theme'] as Map<String, dynamic>);
      }
      return ThemeConfig.defaultTheme;
    });
  }
}
