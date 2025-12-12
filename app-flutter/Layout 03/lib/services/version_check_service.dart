import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version_config.dart';

class VersionCheckService {
  /// Retorna a versão atual do app (do pubspec.yaml)
  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Verifica se precisa atualizar baseado na config
  Future<VersionCheckResult> checkVersion(
    AppVersionConfig? config,
  ) async {
    if (config == null) {
      return VersionCheckResult.noCheckNeeded();
    }

    final currentVersion = await getCurrentVersion();

    // Verifica se precisa atualização forçada
    if (config.isUpdateRequired(currentVersion) && config.forceUpdate) {
      return VersionCheckResult.forceUpdateRequired(
        currentVersion: currentVersion,
        minVersion: config.minVersion,
        config: config,
      );
    }

    // Verifica se há nova versão disponível (opcional)
    if (config.hasNewVersion(currentVersion) && !config.forceUpdate) {
      return VersionCheckResult.optionalUpdateAvailable(
        currentVersion: currentVersion,
        latestVersion: config.latestVersion,
        config: config,
      );
    }

    return VersionCheckResult.upToDate(currentVersion);
  }
}

/// Resultado da verificação de versão
class VersionCheckResult {
  final VersionCheckStatus status;
  final String currentVersion;
  final String? requiredVersion;
  final AppVersionConfig? config;

  const VersionCheckResult({
    required this.status,
    required this.currentVersion,
    this.requiredVersion,
    this.config,
  });

  factory VersionCheckResult.noCheckNeeded() {
    return const VersionCheckResult(
      status: VersionCheckStatus.noCheckNeeded,
      currentVersion: '0.0.0',
    );
  }

  factory VersionCheckResult.forceUpdateRequired({
    required String currentVersion,
    required String minVersion,
    required AppVersionConfig config,
  }) {
    return VersionCheckResult(
      status: VersionCheckStatus.forceUpdateRequired,
      currentVersion: currentVersion,
      requiredVersion: minVersion,
      config: config,
    );
  }

  factory VersionCheckResult.optionalUpdateAvailable({
    required String currentVersion,
    required String latestVersion,
    required AppVersionConfig config,
  }) {
    return VersionCheckResult(
      status: VersionCheckStatus.optionalUpdateAvailable,
      currentVersion: currentVersion,
      requiredVersion: latestVersion,
      config: config,
    );
  }

  factory VersionCheckResult.upToDate(String currentVersion) {
    return VersionCheckResult(
      status: VersionCheckStatus.upToDate,
      currentVersion: currentVersion,
    );
  }

  bool get needsForceUpdate => status == VersionCheckStatus.forceUpdateRequired;
  bool get hasOptionalUpdate =>
      status == VersionCheckStatus.optionalUpdateAvailable;
}

enum VersionCheckStatus {
  noCheckNeeded,
  upToDate,
  optionalUpdateAvailable,
  forceUpdateRequired,
}
