import 'package:flutter/foundation.dart';

@immutable
class AppVersionConfig {
  final String minVersion;
  final String latestVersion;
  final bool forceUpdate;
  final UpdateMessage updateMessage;
  final StoreUrls storeUrls;

  const AppVersionConfig({
    required this.minVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateMessage,
    required this.storeUrls,
  });

  factory AppVersionConfig.fromJson(Map<String, dynamic> json) {
    return AppVersionConfig(
      minVersion: json['minVersion'] as String? ?? '1.0.0',
      latestVersion: json['latestVersion'] as String? ?? '1.0.0',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      updateMessage: UpdateMessage.fromJson(
        json['updateMessage'] as Map<String, dynamic>? ?? {},
      ),
      storeUrls: StoreUrls.fromJson(
        json['storeUrls'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Verifica se a versão atual precisa de atualização
  bool isUpdateRequired(String currentVersion) {
    return _compareVersions(currentVersion, minVersion) < 0;
  }

  /// Verifica se há uma nova versão disponível (não obrigatória)
  bool hasNewVersion(String currentVersion) {
    return _compareVersions(currentVersion, latestVersion) < 0;
  }

  /// Compara duas versões semânticas (X.Y.Z)
  /// Retorna: -1 se v1 < v2, 0 se iguais, 1 se v1 > v2
  int _compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map(int.parse).toList();
      final parts2 = v2.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;

        if (p1 > p2) return 1;
        if (p1 < p2) return -1;
      }
      return 0;
    } catch (e) {
      return 0; // Em caso de erro, considera iguais
    }
  }
}

@immutable
class UpdateMessage {
  final String title;
  final String message;
  final String buttonText;

  const UpdateMessage({
    required this.title,
    required this.message,
    required this.buttonText,
  });

  factory UpdateMessage.fromJson(Map<String, dynamic> json) {
    // Procura por pt_BR, se não tiver, usa valores default
    final ptBR = json['pt_BR'] as Map<String, dynamic>? ?? {};

    return UpdateMessage(
      title: ptBR['title'] as String? ?? 'Atualização Necessária',
      message: ptBR['message'] as String? ??
          'Uma nova versão do app está disponível. Por favor, atualize para continuar.',
      buttonText: ptBR['buttonText'] as String? ?? 'Atualizar Agora',
    );
  }
}

@immutable
class StoreUrls {
  final String android;
  final String ios;

  const StoreUrls({
    required this.android,
    required this.ios,
  });

  factory StoreUrls.fromJson(Map<String, dynamic> json) {
    return StoreUrls(
      android: json['android'] as String? ?? '',
      ios: json['ios'] as String? ?? '',
    );
  }
}
