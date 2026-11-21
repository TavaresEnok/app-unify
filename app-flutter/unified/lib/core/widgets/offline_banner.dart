import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/connectivity_provider.dart';
import '../vibe/vibe_icon.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectivityStatusProvider).valueOrNull;
    if (connection != ConnectivityResult.none) return const SizedBox.shrink();
    // Faixa escura como o aviso flutuante do protótipo (`.toast`), acima
    // da barra de navegação.
    final t = VibeTokens.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        color: const Color(0xFF141821),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          const VibeIcon('alert', size: 18, color: Color(0xFFFBBF4C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                'Celular sem rede. As informações podem estar desatualizadas.',
                style: vibeText(t, 13, 600, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}
