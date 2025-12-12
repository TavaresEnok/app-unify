import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._(); // This class is not meant to be instantiated.

  static final TextStyle heading1 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static final TextStyle heading2 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static final TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    color: AppColors.text,
    height: 1.5,
  );

  static final TextStyle bodySecondary = GoogleFonts.inter(
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static final TextStyle button = GoogleFonts.inter(
    fontWeight: FontWeight.bold,
    color: Colors.white, // Geralmente o texto do botão principal é branco
  );

  static final TextStyle hint = GoogleFonts.inter(
    color: AppColors.textHint,
  );
}
