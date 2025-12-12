import 'package:flutter/material.dart';

class Layout05Theme {
  static const Color primary = Color(0xFF00E5FF); // Cyan Neon
  static const Color secondary = Color(0xFFD500F9); // Purple Neon
  static const Color background = Color(0xFF050510);
  static const Color surface = Color(0xFF101025);
  static const Color surfaceLight = Color(0xFF1A1A35);
  static const Color error = Color(0xFFFF1744);

  static BoxDecoration glassDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.08),
        Colors.white.withOpacity(0.03),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        blurRadius: 20,
        spreadRadius: -5,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration neonBorderDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: primary.withOpacity(0.5), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.2),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ],
  );
}
