import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectivityStatusProvider).valueOrNull;
    if (connection != ConnectivityResult.none) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Container(
        width: double.infinity,
        color: colors.error,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          Icon(Icons.wifi_off_outlined, color: colors.onError),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
                  'Seu celular está sem rede. Ative o Wi-Fi ou os dados móveis para atualizar as informações.',
                  style: TextStyle(color: colors.onError, height: 1.4))),
        ]));
  }
}
