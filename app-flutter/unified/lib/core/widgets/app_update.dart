import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/provider_config.dart';
import '../providers/providers.dart';
import 'content_state.dart';

/// Versão e pacote do app instalado (`null` quando a plataforma não informa).
final installedAppProvider =
    FutureProvider<({String version, String package})?>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return (version: info.version, package: info.packageName);
  } catch (_) {
    return null;
  }
});

/// O que a política de versão pede para este app.
enum AppUpdateNeed { none, suggested, required }

final appUpdateNeedProvider = Provider<AppUpdateNeed>((ref) {
  final policy = ref
      .watch(configurationProvider.select((c) => c.providerConfig?.appVersion));
  final installed = ref.watch(installedAppProvider).valueOrNull;
  if (policy == null || installed == null) return AppUpdateNeed.none;
  if (policy.requiresUpdate(installed.version)) return AppUpdateNeed.required;
  if (policy.suggestsUpdate(installed.version)) return AppUpdateNeed.suggested;
  return AppUpdateNeed.none;
});

/// Abre a loja na página do app (link do painel ou o da Play Store).
Future<bool> openAppStore(AppVersionPolicy? policy, String? packageName) async {
  final url = policy?.storeUrl.isNotEmpty == true
      ? policy!.storeUrl
      : (packageName?.isNotEmpty == true
          ? 'https://play.google.com/store/apps/details?id=$packageName'
          : '');
  final uri = Uri.tryParse(url);
  if (uri == null || url.isEmpty) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Tela que bloqueia o app quando a versão instalada está abaixo da mínima.
class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(
        configurationProvider.select((c) => c.providerConfig?.appVersion));
    final package = ref.watch(installedAppProvider).valueOrNull?.package;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ContentState(
            icon: Icons.system_update_outlined,
            title: policy?.title.isNotEmpty == true
                ? policy!.title
                : 'Atualize o app',
            message: policy?.message.isNotEmpty == true
                ? policy!.message
                : 'Esta versão não funciona mais. Atualize o aplicativo para continuar.',
            actionLabel: policy?.buttonText.isNotEmpty == true
                ? policy!.buttonText
                : 'Atualizar agora',
            onAction: () async {
              final ok = await openAppStore(policy, package);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Não foi possível abrir a loja. Procure o app na Play Store.')));
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Faixa discreta quando há versão mais nova (pode ser fechada).
class UpdateAvailableBanner extends ConsumerStatefulWidget {
  const UpdateAvailableBanner({super.key});

  @override
  ConsumerState<UpdateAvailableBanner> createState() =>
      _UpdateAvailableBannerState();
}

class _UpdateAvailableBannerState extends ConsumerState<UpdateAvailableBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed ||
        ref.watch(appUpdateNeedProvider) != AppUpdateNeed.suggested) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final policy = ref.read(configurationProvider).providerConfig?.appVersion;
    final package = ref.read(installedAppProvider).valueOrNull?.package;
    return Material(
      color: scheme.primary.withValues(alpha: .10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        child: Row(children: [
          Icon(Icons.system_update_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Nova versão do app disponível.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => openAppStore(policy, package),
            child: const Text('Atualizar'),
          ),
          IconButton(
            tooltip: 'Fechar aviso',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ]),
      ),
    );
  }
}
