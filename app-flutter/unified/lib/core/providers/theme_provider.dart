import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_config.dart';
import '../theme/layout_tokens.dart';

class DynamicThemeProvider with ChangeNotifier {
  ThemeData _lightTheme;
  ThemeData _darkTheme;
  static const _preferenceKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  bool _disposed = false;
  bool _changedByUser = false;
  ThemeConfig _currentConfig;

  DynamicThemeProvider()
      : _currentConfig = ThemeConfig.defaultTheme,
        _lightTheme = _buildTheme(ThemeConfig.defaultTheme, Brightness.light),
        _darkTheme = _buildTheme(ThemeConfig.defaultTheme, Brightness.dark) {
    _loadPreference();
  }

  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;
  ThemeMode get themeMode => _themeMode;
  ThemeConfig get config => _currentConfig;

  void updateFromConfig(ThemeConfig config, {String? layoutType}) {
    _currentConfig = config;

    final tokens =
        LayoutTokens.of(layoutType).withPrimary(config.colors.primary);
    _lightTheme = tokens.withBrightness(Brightness.light).themeData(
          base: _buildTheme(config, Brightness.light),
        );
    _darkTheme = tokens.withBrightness(Brightness.dark).themeData(
          base: _buildTheme(config, Brightness.dark),
        );

    notifyListeners();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_preferenceKey);
      if (_disposed || _changedByUser) return;
      if (saved == ThemeMode.dark.toString()) {
        _themeMode = ThemeMode.dark;
        notifyListeners();
      }
    } catch (_) {
      // The default appearance is available even if local storage fails.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _changedByUser = true;
    _themeMode = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_preferenceKey, _themeMode.toString());
    } catch (_) {
      // Keep the selection active for this session if saving fails.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
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

    final textPrimary =
        LayoutTokens.readable(colors.textPrimary, background); // Trust config
    final textSecondary =
        LayoutTokens.readable(colors.textSecondary, background); // Trust config

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
        onPrimary: LayoutTokens.foregroundFor(primary),
        secondary: secondary,
        onSecondary: LayoutTokens.foregroundFor(secondary),
        error: colors.error,
        onError: LayoutTokens.foregroundFor(colors.error),
        surface: surface,
        onSurface: LayoutTokens.readable(colors.textPrimary, surface),
        surfaceContainerLowest: background,
        onSurfaceVariant: LayoutTokens.readable(colors.textSecondary, surface),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: LayoutTokens.foregroundFor(primary),
        minimumSize: const Size(48, 48),
      )),
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
          foregroundColor: LayoutTokens.foregroundFor(primary),
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
    // Use installed/bundled fonts with the platform fallback. Creating the
    // application theme must not start network requests for font files.
    return TextTheme(
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
    ).apply(fontFamily: config.fontFamily);
  }
}
