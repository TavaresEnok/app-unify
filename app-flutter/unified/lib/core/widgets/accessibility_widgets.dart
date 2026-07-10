/// Widgets de Acessibilidade
/// Componentes com suporte a screen readers e acessibilidade
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Botão acessível com Semantics integrado
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final bool excludeFromSemantics;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      excludeSemantics: excludeFromSemantics,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: child,
      ),
    );
  }
}

/// IconButton acessível
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final Color? color;
  final double size;
  final EdgeInsets padding;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.color,
    this.size = 24,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        padding: padding,
        tooltip: semanticLabel,
      ),
    );
  }
}

/// Card acessível com descrição para screen readers
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final BoxDecoration? decoration;

  const AccessibleCard({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
    this.padding,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration ??
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
      child: child,
    );

    return Semantics(
      label: semanticLabel,
      container: true,
      child: onTap != null
          ? GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap!();
              },
              child: cardContent,
            )
          : cardContent,
    );
  }
}

/// Status indicator acessível
class AccessibleStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String? customLabel;

  const AccessibleStatusIndicator({
    super.key,
    required this.isConnected,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = isConnected ? 'Conectado' : 'Desconectado';
    final statusColor = isConnected ? Colors.green : Colors.red;

    return Semantics(
      label: customLabel ?? 'Status da conexão: $statusText',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper para adicionar Semantics a qualquer widget
class SemanticWrapper extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final bool isButton;
  final bool isHeader;
  final bool isLink;

  const SemanticWrapper({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.isButton = false,
    this.isHeader = false,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      header: isHeader,
      link: isLink,
      child: child,
    );
  }
}

/// Extension para adicionar acessibilidade rapidamente
extension AccessibilityExtension on Widget {
  Widget withSemantics({
    required String label,
    String? hint,
    bool isButton = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      child: this,
    );
  }
}
