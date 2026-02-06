import 'package:flutter/material.dart';

class ThemeConfig {
  final ThemeColors colors;
  final ThemeTypography typography;
  final ThemeSpacing spacing;
  final ThemeBorderRadius borderRadius;
  final ThemeEffects effects;
  final DarkModeConfig darkMode;

  const ThemeConfig({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.borderRadius,
    required this.effects,
    required this.darkMode,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      colors: ThemeColors.fromJson(json['colors'] ?? {}),
      typography: ThemeTypography.fromJson(json['typography'] ?? {}),
      spacing: ThemeSpacing.fromJson(json['spacing'] ?? {}),
      borderRadius: ThemeBorderRadius.fromJson(json['borderRadius'] ?? {}),
      effects: ThemeEffects.fromJson(json['effects'] ?? {}),
      darkMode: DarkModeConfig.fromJson(json['darkMode'] ?? {}),
    );
  }

  static ThemeConfig get defaultTheme => ThemeConfig(
        colors: ThemeColors.defaultColors,
        typography: ThemeTypography.defaultTypography,
        spacing: ThemeSpacing.defaultSpacing,
        borderRadius: ThemeBorderRadius.defaultBorderRadius,
        effects: ThemeEffects.defaultEffects,
        darkMode: DarkModeConfig.defaultDarkMode,
      );
}

class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color error;
  final Color success;
  final Color warning;
  final Color info;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
  });

  factory ThemeColors.fromJson(Map<String, dynamic> json) {
    return ThemeColors(
      primary: _parseColor(json['primary'], const Color(0xFF673AB7)),
      secondary: _parseColor(json['secondary'], const Color(0xFF9575CD)),
      background: _parseColor(json['background'], const Color(0xFF0F172A)),
      surface: _parseColor(json['surface'], const Color(0xFF1E293B)),
      error: _parseColor(json['error'], const Color(0xFFEF4444)),
      success: _parseColor(json['success'], const Color(0xFF10B981)),
      warning: _parseColor(json['warning'], const Color(0xFFF59E0B)),
      info: _parseColor(json['info'], const Color(0xFF3B82F6)),
      textPrimary: _parseColor(json['textPrimary'], Colors.white),
      textSecondary: _parseColor(json['textSecondary'], const Color(0xFF94A3B8)),
      textHint: _parseColor(json['textHint'], const Color(0xFF64748B)),
    );
  }

  static Color _parseColor(dynamic value, Color fallback) {
    if (value == null) return fallback;
    if (value is String && value.startsWith('#')) {
      try {
        return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  static const ThemeColors defaultColors = ThemeColors(
    primary: Color(0xFF673AB7),
    secondary: Color(0xFF9575CD),
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF94A3B8),
    textHint: Color(0xFF64748B),
  );
}

class ThemeTypography {
  final String fontFamily;
  final Map<String, double> fontSizes;

  const ThemeTypography({required this.fontFamily, required this.fontSizes});

  factory ThemeTypography.fromJson(Map<String, dynamic> json) {
    final sizes = json['fontSizes'] as Map<String, dynamic>? ?? {};
    return ThemeTypography(
      fontFamily: json['fontFamily'] ?? 'Inter',
      fontSizes: {
        'h1': (sizes['h1'] ?? 32).toDouble(),
        'h2': (sizes['h2'] ?? 24).toDouble(),
        'h3': (sizes['h3'] ?? 20).toDouble(),
        'body': (sizes['body'] ?? 14).toDouble(),
        'caption': (sizes['caption'] ?? 12).toDouble(),
      },
    );
  }

  static const ThemeTypography defaultTypography = ThemeTypography(
    fontFamily: 'Inter',
    fontSizes: {'h1': 32, 'h2': 24, 'h3': 20, 'body': 14, 'caption': 12},
  );
}

class ThemeSpacing {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  const ThemeSpacing({required this.xs, required this.sm, required this.md, required this.lg, required this.xl});

  factory ThemeSpacing.fromJson(Map<String, dynamic> json) {
    return ThemeSpacing(
      xs: (json['xs'] ?? 4).toDouble(),
      sm: (json['sm'] ?? 8).toDouble(),
      md: (json['md'] ?? 16).toDouble(),
      lg: (json['lg'] ?? 24).toDouble(),
      xl: (json['xl'] ?? 32).toDouble(),
    );
  }

  static const ThemeSpacing defaultSpacing = ThemeSpacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32);
}

class ThemeBorderRadius {
  final double sm;
  final double md;
  final double lg;
  final double xl;

  const ThemeBorderRadius({required this.sm, required this.md, required this.lg, required this.xl});

  factory ThemeBorderRadius.fromJson(Map<String, dynamic> json) {
    return ThemeBorderRadius(
      sm: (json['sm'] ?? 4).toDouble(),
      md: (json['md'] ?? 8).toDouble(),
      lg: (json['lg'] ?? 16).toDouble(),
      xl: (json['xl'] ?? 24).toDouble(),
    );
  }

  static const ThemeBorderRadius defaultBorderRadius = ThemeBorderRadius(sm: 4, md: 8, lg: 16, xl: 24);
}

class ThemeEffects {
  final bool enableGlassmorphism;
  final bool enableGradients;
  final bool enableAnimations;
  final double glassOpacity;
  final double glassBlur;

  const ThemeEffects({
    required this.enableGlassmorphism,
    required this.enableGradients,
    required this.enableAnimations,
    required this.glassOpacity,
    required this.glassBlur,
  });

  factory ThemeEffects.fromJson(Map<String, dynamic> json) {
    return ThemeEffects(
      enableGlassmorphism: json['enableGlassmorphism'] ?? true,
      enableGradients: json['enableGradients'] ?? true,
      enableAnimations: json['enableAnimations'] ?? true,
      glassOpacity: (json['glassOpacity'] ?? 0.7).toDouble(),
      glassBlur: (json['glassBlur'] ?? 12).toDouble(),
    );
  }

  static const ThemeEffects defaultEffects = ThemeEffects(
    enableGlassmorphism: true,
    enableGradients: true,
    enableAnimations: true,
    glassOpacity: 0.7,
    glassBlur: 12,
  );
}

class DarkModeConfig {
  final bool enabled;
  final String defaultMode;

  const DarkModeConfig({required this.enabled, required this.defaultMode});

  factory DarkModeConfig.fromJson(Map<String, dynamic> json) {
    return DarkModeConfig(
      enabled: json['enabled'] ?? true,
      defaultMode: json['defaultMode'] ?? 'auto',
    );
  }

  static const DarkModeConfig defaultDarkMode = DarkModeConfig(enabled: true, defaultMode: 'auto');
}
