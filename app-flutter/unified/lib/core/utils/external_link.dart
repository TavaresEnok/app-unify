import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre um link http(s) fora do app; avisa quando não consegue.
Future<void> openExternalLink(BuildContext context, String? url,
    {String failure = 'Não foi possível abrir este link.'}) async {
  final uri = Uri.tryParse(url ?? '');
  try {
    if (uri != null &&
        ['https', 'http'].contains(uri.scheme) &&
        uri.host.isNotEmpty &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
  } catch (_) {
    // Mostra o aviso abaixo.
  }
  if (context.mounted) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(failure)));
  }
}
