import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/theme_config.dart';
import '../../layouts/layout_06/theme.dart';

class DynamicThemeProvider with ChangeNotifier {
  ThemeData _lightTheme;
  ThemeData _darkTheme;
  ThemeMode _themeMode = ThemeMode.system;
  ThemeConfig _currentConfig;

  DynamicThemeProvider()
      : _currentConfig = ThemeConfig.defaultTheme,
        _lightTheme = _buildTheme(ThemeConfig.defaultTheme, Brightness.light),
        _darkTheme = _buildTheme(ThemeConfig.defaultTheme, Brightness.dark) {
    // Force Light Mode as default initially
    _themeMode = ThemeMode.light;
  }

  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;
  ThemeMode get themeMode => _themeMode;
  ThemeConfig get config => _currentConfig;

  void updateFromConfig(ThemeConfig config, {String? layoutType}) {
    _currentConfig = config;

    if (layoutType == 'layout_06') {
      // Layout 06 uses its own specialized theme builder
      _lightTheme = Layout06Theme.getTheme(config);
      _darkTheme = Layout06Theme.getTheme(config);
      _themeMode = ThemeMode.dark; // Force Dark Mode
    } else {
      _lightTheme = _buildTheme(config, Brightness.light);
      _darkTheme = _buildTheme(config, Brightness.dark);
    }

    // Atualiza o modo do tema baseado na config
    if (config.darkMode.enabled) {
      switch (config.darkMode.defaultMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.light;
      }
    } else {
      _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  static ThemeData _buildTheme(ThemeConfig config, Brightness brightness) {
    final colors = config.colors;
    final isDark = brightness == Brightness.dark;

    // Use configured colors directly if possible, falling back only if needed.
    // NOTE: In our new system, `colors.background` and `colors.surface` are already
    // populated precisely from the user's config in `providers.dart`.
    // So we should trust them unless they are defaults that we successfully identified as "should change based on mode".
    // For now, let's trust the config object as the source of truth for these custom overrides.

    final primary = colors.primary;
    final secondary = colors.secondary;

    // [FIX] Trust the config's background/surface.
    // If the user set a custom color, `colors.background` holds it.
    // If they didn't, it holds the default.
    // To distinguish "User set specific color" vs "Default", we rely on the fact
    // that `providers.dart` constructs this `ThemeConfig` dynamically.
    final background = colors.background;
    final surface = colors.surface;

    final textPrimary = colors.textPrimary; // Trust config
    final textSecondary = colors.textSecondary; // Trust config

    // Typography setup
    final textTheme =
        _buildTextTheme(config.typography, textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: background,

      // [NEW] Map Icon Theme
      iconTheme: IconThemeData(
        color: config.effects.iconColor ?? primary,
      ),

      // Color Scheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: colors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerLowest: background,
        onSurfaceVariant: textPrimary,
      ),

      // Typography
      textTheme: textTheme,
      fontFamily: config.typography.fontFamily,

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: config.effects.enableGlassmorphism ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.md),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.sm),
          borderSide:
              BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.sm),
          borderSide:
              BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.sm),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: colors.textHint),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: config.spacing.lg,
            vertical: config.spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius.sm),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(
      ThemeTypography config, Color primaryColor, Color textSecondaryColor) {
    try {
      return GoogleFonts.getTextTheme(
        config.fontFamily,
        TextTheme(
          displayLarge: TextStyle(
            fontSize: config.fontSizes['h1'],
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
          headlineMedium: TextStyle(
            fontSize: config.fontSizes['h2'],
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
          titleLarge: TextStyle(
            fontSize: config.fontSizes['h3'],
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
          bodyLarge: TextStyle(
            fontSize: config.fontSizes['body'],
            color: primaryColor,
          ),
          bodyMedium: TextStyle(
            fontSize: config.fontSizes['body'],
            color: textSecondaryColor,
          ),
          labelSmall: TextStyle(
            fontSize: config.fontSizes['caption'],
            color: textSecondaryColor,
          ),
        ),
      );
    } catch (e) {
      // Fallback se a fonte não carregar ou não existir
      debugPrint('Erro ao carregar fonte ${config.fontFamily}: $e');
      return TextTheme(
        displayLarge:
            TextStyle(fontSize: config.fontSizes['h1'], color: primaryColor),
        bodyLarge:
            TextStyle(fontSize: config.fontSizes['body'], color: primaryColor),
      );
    }
  }
}
