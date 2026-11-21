import 'package:flutter/material.dart';

import '../vibe/vibe_controls.dart';
import '../vibe/vibe_tokens.dart';

/// Estado recuperável de uma tela (sem dados, erro, recurso indisponível),
/// com as peças do layout aprovado. Detalhes técnicos ficam fora da tela.
class ContentState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const ContentState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message,
      this.actionLabel,
      this.onAction});

  /// Ícone de traço do layout equivalente ao ícone pedido.
  static String _glyph(IconData icon) {
    if (icon == Icons.cloud_off_outlined ||
        icon == Icons.wifi_off ||
        icon == Icons.wifi_off_outlined) {
      return 'alert';
    }
    if (icon == Icons.error_outline) return 'alert';
    if (icon == Icons.history) return 'clock';
    if (icon == Icons.person_outline) return 'user';
    if (icon == Icons.receipt_long_outlined) return 'file';
    if (icon == Icons.support_agent) return 'chat';
    return 'info';
  }

  @override
  Widget build(BuildContext context) => VibeStatePanel(
        icon: _glyph(icon),
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        tone: icon == Icons.error_outline ||
                icon == Icons.cloud_off_outlined ||
                icon == Icons.wifi_off ||
                icon == Icons.wifi_off_outlined
            ? VibeTone.warning
            : VibeTone.neutral,
      );
}
