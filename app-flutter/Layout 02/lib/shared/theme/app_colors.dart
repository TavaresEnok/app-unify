import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // This class is not meant to be instantiated.

  static const Color background = Color(0xFF050816);
  static const Color surface = Color(0xFF111827); // Used in AppBar
  static const Color dropdownBackground = Color(0xFF1F2937);
  static final Color inputFill = Colors.white.withOpacity(0.05);
  static final Color inputBorder = Colors.white.withOpacity(0.1);

  static const Color text = Colors.white;
  static final Color textSecondary = Colors.blueGrey[200]!;
  static final Color textHint = Colors.blueGrey[400]!;

  static final Color success = Colors.greenAccent.withOpacity(0.8);
  static const Color error = Colors.redAccent;

  static const Color primaryBlue = Color(0xFF1E6FF8);
  static const Color textPrimary = Colors.white;
  static final Color divider = Colors.blueGrey.withOpacity(0.2);

  // A cor primária é dinâmica e virá do ProviderConfig.
  // Manteremos a lógica de `hexToColor` para defini-la no tema da aplicação.
}
