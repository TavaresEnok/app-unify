import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_config.dart';

/// Serviço para carregar configuração do dashboard do Firestore
class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Carrega a configuração do dashboard do provedor
  Future<DashboardConfig> loadConfig(String providerId) async {
    try {
      final doc =
          await _firestore.collection('provedores').doc(providerId).get();

      if (doc.exists && doc.data()?['dashboard'] != null) {
        final dashboardData = doc.data()!['dashboard'] as Map<String, dynamic>;
        return DashboardConfig.fromJson(dashboardData);
      }

      print('Dashboard config não encontrado para $providerId, usando padrão');
      return DashboardConfig.defaultConfig;
    } catch (e) {
      print('Erro ao carregar dashboard config: $e');
      return DashboardConfig.defaultConfig;
    }
  }

  /// Stream para ouvir mudanças em tempo real
  Stream<DashboardConfig> watchConfig(String providerId) {
    return _firestore
        .collection('provedores')
        .doc(providerId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data()?['dashboard'] != null) {
        final dashboardData = doc.data()!['dashboard'] as Map<String, dynamic>;
        return DashboardConfig.fromJson(dashboardData);
      }
      return DashboardConfig.defaultConfig;
    });
  }
}
