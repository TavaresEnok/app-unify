import 'package:flutter/material.dart';

class DiagnosticoStatusBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isTesting;
  final String message;
  final Color primaryColor;
  final Color textColor;

  const DiagnosticoStatusBar({
    super.key,
    required this.isTesting,
    required this.message,
    required this.primaryColor,
    this.textColor = Colors.black54, // Default suitable for light background
  });

  @override
  Size get preferredSize => const Size.fromHeight(40.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: isTesting ? primaryColor.withOpacity(0.1) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          message,
          key: ValueKey<String>(message),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isTesting ? primaryColor : textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
