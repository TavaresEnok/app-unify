import 'package:flutter/material.dart';
import 'customer_style.dart';
import '../models/provider_config.dart';
import '../vibe/vibe_tokens.dart';

/// Fonte ÚNICA de design por `layoutType`.
///
/// Antes, a aparência era decidida por dezenas de comparações `layoutType ==
/// 'layout_0X'` espalhadas pelo código e por 11 métodos estáticos separados em
/// [SharedThemeHelper]. Aqui o `layoutType` é resolvido UMA vez em um objeto
/// imutável — as telas leem um token, não reinterpretam a string do layout.
///
/// Os valores espelham exatamente os que estavam no `SharedThemeHelper`, para
/// que consolidar não mude o visual. `SharedThemeHelper` passou a delegar a esta
/// classe (compatibilidade), então a migração das telas pode ser incremental.
@immutable
class LayoutTokens {
  final String layoutType;

  final Color background;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final Color card;
  final Color border;
  final Color success;
  final Color error;
  final Color warning;
  final Color? secondary;
  final Color? cardText;
  final Color? iconColor;
  final Color? quickActionsCard;
  final Color? quickActionsText;
  final Color? otherCards;
  final Color? otherCardsText;
  final Color? invoiceColor;
  final Color? actionColor;

  final bool isDark;
  final bool isNeumorphic;

  /// Raio padrão de cantos (cards, campos, botões).
  final double radius;

  const LayoutTokens({
    required this.layoutType,
    required this.background,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.card,
    required this.border,
    required this.success,
    required this.error,
    required this.warning,
    this.secondary,
    this.cardText,
    this.iconColor,
    this.quickActionsCard,
    this.quickActionsText,
    this.otherCards,
    this.otherCardsText,
    this.invoiceColor,
    this.actionColor,
    required this.isDark,
    required this.isNeumorphic,
    this.radius = 16,
  });

  /// Contrast is measured after compositing translucent foregrounds.
  static double contrast(Color foreground, Color background) {
    final a = Color.alphaBlend(foreground, background).computeLuminance();
    final b = background.computeLuminance();
    return (a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05));
  }

  static Color foregroundFor(Color background) =>
      contrast(Colors.black, background) >= contrast(Colors.white, background)
          ? Colors.black
          : Colors.white;

  static Color readable(Color preferred, Color background,
          {double minimum = 4.5}) =>
      contrast(preferred, background) >= minimum
          ? preferred
          : foregroundFor(background);

  Color get onPrimary => foregroundFor(primary);

  LayoutTokens withPrimary(Color color) => LayoutTokens(
        layoutType: layoutType,
        background: background,
        primary: color,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        card: card,
        border: border,
        success: success,
        error: error,
        warning: warning,
        secondary: secondary,
        cardText: cardText,
        iconColor: iconColor,
        quickActionsCard: quickActionsCard,
        quickActionsText: quickActionsText,
        otherCards: otherCards,
        otherCardsText: otherCardsText,
        invoiceColor: invoiceColor,
        actionColor: actionColor,
        isDark: isDark,
        isNeumorphic: isNeumorphic,
        radius: radius,
      );

  /// White and dark appearances are available for every provider layout.
  LayoutTokens withBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return LayoutTokens(
      layoutType: layoutType,
      background: dark ? const Color(0xFF101319) : const Color(0xFFF5F6F9),
      primary: primary,
      textPrimary: dark ? const Color(0xFFF5F6FA) : const Color(0xFF18202C),
      textSecondary: dark ? const Color(0xFFB4BDCC) : const Color(0xFF596577),
      card: dark ? const Color(0xFF1C2029) : Colors.white,
      border: dark ? const Color(0xFF393F4C) : const Color(0xFFDCE1E8),
      success: dark ? const Color(0xFF52D998) : const Color(0xFF137650),
      error: dark ? const Color(0xFFFF7A81) : const Color(0xFFC52B40),
      warning: dark ? const Color(0xFFFFD479) : const Color(0xFF8A5600),
      isDark: dark,
      isNeumorphic: false,
      radius: radius,
    );
  }

  /// Apply provider choices on matching surfaces while keeping both modes legible.
  LayoutTokens withProviderColors(ConfigSection config) {
    Color? parse(String? value) {
      if (value == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
        return null;
      }
      return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
    }

    Color? compatible(String? value) {
      final color = parse(value);
      if (color == null) return null;
      final colorIsDark =
          ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
      return colorIsDark == isDark ? color : null;
    }

    final backgroundColor = compatible(config.backgroundColor) ?? background;
    final surfaceColor = compatible(config.cardColor) ?? card;
    final preferredText = parse(config.textColor) ?? textPrimary;
    final primaryText = readable(preferredText, backgroundColor);
    final textOnCard = readable(
      parse(config.cardTextColor) ?? preferredText,
      surfaceColor,
    );
    final secondaryText = readable(
        parse(config.textSecondaryColor) ?? textSecondary, surfaceColor);
    final quickSurface = compatible(config.quickActionsCardColor);
    final otherSurface = compatible(config.otherCardsColor);
    final quickText = parse(config.quickActionsTextColor);
    final otherText = parse(config.otherCardsTextColor);
    final customIcon = parse(config.iconColor);
    return LayoutTokens(
      layoutType: layoutType,
      background: backgroundColor,
      primary: primary,
      textPrimary: primaryText,
      textSecondary: secondaryText,
      card: surfaceColor,
      border: border,
      success: success,
      error: error,
      warning: warning,
      secondary: parse(config.secondaryColor),
      cardText: textOnCard,
      iconColor: customIcon == null
          ? null
          : readable(customIcon, surfaceColor, minimum: 3),
      quickActionsCard: quickSurface,
      quickActionsText: quickText == null
          ? null
          : readable(quickText, quickSurface ?? surfaceColor),
      otherCards: otherSurface,
      otherCardsText: otherText == null
          ? null
          : readable(otherText, otherSurface ?? surfaceColor),
      invoiceColor: parse(config.invoiceColor),
      actionColor: parse(config.actionColor),
      isDark: isDark,
      isNeumorphic: isNeumorphic,
      radius: radius,
    );
  }

  /// Tokens do layout aprovado (layout-app/vibe-5-definitivas.html) para a
  /// cor da marca e a aparência atuais. Fundo, cartão e textos configurados
  /// pelo provedor substituem os do layout; sem configuração, valem os do
  /// protótipo.
  VibeTokens get vibe {
    final base =
        VibeTokens.resolve(layout: layoutType, brand: primary, dark: isDark);
    final standard = LayoutTokens.of(layoutType)
        .withPrimary(primary)
        .withBrightness(isDark ? Brightness.dark : Brightness.light);
    // Valores quase iguais aos do layout (como os padrões gravados pelo
    // painel, #F4F5F8 e #172033) contam como o próprio layout.
    Color? custom(Color value, Color reference) {
      final close = (value.r - reference.r).abs() * 255 <= 8 &&
          (value.g - reference.g).abs() * 255 <= 8 &&
          (value.b - reference.b).abs() * 255 <= 8;
      return close ? null : value;
    }

    return base.copyWith(
      bg: custom(background, standard.background),
      card: custom(card, standard.card),
      ink: custom(cardText ?? textPrimary, standard.textPrimary),
      mut: custom(textSecondary, standard.textSecondary),
    );
  }

  /// Componentes Material com a tipografia, as cores e os raios do layout
  /// aprovado, para que as telas comuns sigam o mesmo desenho.
  ThemeData themeData({ThemeData? base}) {
    final v = vibe;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: v.ac,
      brightness: brightness,
    ).copyWith(
      primary: v.ac,
      onPrimary: v.on,
      secondary: secondary,
      onSecondary: secondary == null ? null : foregroundFor(secondary!),
      surface: v.card,
      surfaceContainerLowest: v.bg,
      onSurface: v.ink,
      onSurfaceVariant: v.mut,
      error: v.bad,
      onError: foregroundFor(v.bad),
      errorContainer: v.badb,
      onErrorContainer: v.bad,
      outline: v.line,
      outlineVariant: v.line,
    );
    final cardRadius = BorderRadius.circular(v.rad - 2 < 10 ? 10 : v.rad - 2);
    final buttonRadius = BorderRadius.circular(v.rad - 4 < 10 ? 10 : v.rad - 4);
    final family = v.fontFamily;
    final text =
        (base?.textTheme ?? ThemeData(brightness: brightness).textTheme)
            .apply(fontFamily: family, bodyColor: v.ink, displayColor: v.ink);
    TextStyle style(double size, FontWeight weight, [Color? color]) =>
        TextStyle(
            fontFamily: family,
            fontSize: size,
            fontWeight: weight,
            color: color ?? v.ink);
    return (base ?? ThemeData(useMaterial3: true, brightness: brightness))
        .copyWith(
      brightness: brightness,
      extensions: [
        CustomerStyle(
          radius: v.rad,
          quickActionsCard: quickActionsCard,
          quickActionsText: quickActionsText,
          otherCards: otherCards,
          otherCardsText: otherCardsText,
          invoiceColor: invoiceColor,
          actionColor: actionColor,
          iconColor: iconColor,
          border: v.line,
          shadows: const [],
        ),
        v,
      ],
      colorScheme: scheme,
      primaryColor: v.ac,
      cardColor: v.card,
      dividerColor: v.line,
      scaffoldBackgroundColor: v.bg,
      canvasColor: v.bg,
      textTheme: text,
      primaryTextTheme: text,
      dividerTheme: DividerThemeData(color: v.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: v.hero,
        foregroundColor: v.hx,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: style(21, FontWeight.w800, v.hx),
        iconTheme: IconThemeData(color: v.hx),
        actionsIconTheme: IconThemeData(color: v.hx),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(v.rad))),
      ),
      iconTheme: IconThemeData(color: v.ink),
      cardTheme: CardThemeData(
        color: v.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: cardRadius, side: BorderSide(color: v.line)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: v.at,
        textColor: v.ink,
        titleTextStyle: style(14, FontWeight.w700),
        subtitleTextStyle: style(12.5, FontWeight.w500, v.mut),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        backgroundColor: v.ac,
        foregroundColor: v.on,
        minimumSize: const Size(48, 48),
        textStyle: style(14.5, FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: v.ac,
        foregroundColor: v.on,
        elevation: 0,
        minimumSize: const Size(48, 48),
        textStyle: style(14.5, FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        foregroundColor: v.ink,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: v.line, width: 1.5),
        textStyle: style(14.5, FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      )),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        foregroundColor: v.at,
        textStyle: style(13.5, FontWeight.w700),
      )),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? v.card
                  : v.ink.withValues(alpha: .08)),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? v.ink : v.mut),
          side: WidgetStatePropertyAll(BorderSide(color: v.line)),
          textStyle: WidgetStatePropertyAll(style(13.5, FontWeight.w700)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: v.ink.withValues(alpha: .08),
        selectedColor: v.ac,
        labelStyle: style(13, FontWeight.w600),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: v.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: style(13, FontWeight.w600, v.mut),
        hintStyle: style(15, FontWeight.w500, v.mut),
        prefixIconColor: v.mut,
        suffixIconColor: v.mut,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: v.line, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: v.line, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: v.ac, width: 2)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF141821),
        contentTextStyle: style(14, FontWeight.w600, Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: v.ac),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? v.on : null),
        trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? v.ac : null),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: v.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(v.rad + 4))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: v.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        titleTextStyle: style(17, FontWeight.w800),
        contentTextStyle: style(13.5, FontWeight.w500, v.mut),
      ),
    );
  }

  /// Sombra neumórfica (só faz sentido no layout_03).
  BoxDecoration get neumorphicDecoration => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
        ],
      );

  /// Decoração de card apropriada ao layout (neumórfico, escuro ou claro).
  BoxDecoration get cardDecoration {
    if (isNeumorphic) return neumorphicDecoration;
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }

  static bool _isDark(String? layoutType) =>
      layoutType == 'layout_04' ||
      layoutType == 'layout_05' ||
      layoutType == 'layout_06';

  /// Resolve os tokens para um `layoutType` (default: layout_06).
  factory LayoutTokens.of(String? layoutType) {
    layoutType = [
      'layout_02',
      'layout_03',
      'layout_04',
      'layout_05',
      'layout_06'
    ].contains(layoutType)
        ? layoutType
        : 'layout_06';
    final isDark = _isDark(layoutType);
    final isNeu = layoutType == 'layout_03';

    Color background;
    Color primary;
    Color card;
    switch (layoutType) {
      case 'layout_02':
        background = const Color(0xFFF7FAFC);
        primary = const Color(0xFF3182CE);
        card = Colors.white;
        break;
      case 'layout_03':
        background = const Color(0xFFE8EEF5);
        primary = const Color(0xFF00D4FF);
        card = const Color(0xFFE8EEF5);
        break;
      case 'layout_04':
        background = const Color(0xFF0A0A0A);
        primary = const Color(0xFF0891B2);
        card = const Color(0xFF1C1C1E);
        break;
      case 'layout_05':
        background = const Color(0xFF050810);
        primary = const Color(0xFF00E5FF);
        card = const Color(0xFF161B22);
        break;
      case 'layout_06':
      default:
        background = const Color(0xFF0A0E21);
        primary = const Color(0xFF00BCD4);
        card = const Color(0xFF0F1225);
        break;
    }

    Color textPrimary;
    if (isDark) {
      textPrimary = Colors.white;
    } else if (layoutType == 'layout_02') {
      textPrimary = const Color(0xFF1A202C);
    } else if (layoutType == 'layout_03') {
      textPrimary = const Color(0xFF2D3748);
    } else {
      textPrimary = const Color(0xFF1F2937);
    }

    return LayoutTokens(
      layoutType: layoutType ?? 'layout_06',
      background: background,
      primary: primary,
      textPrimary: textPrimary,
      textSecondary: isDark ? const Color(0xFFB8C2D1) : const Color(0xFF475569),
      card: card,
      border: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.2),
      success: isDark ? const Color(0xFF00E676) : const Color(0xFF166534),
      error: isDark ? const Color(0xFFFF5252) : const Color(0xFFE53E3E),
      warning: isDark ? const Color(0xFFFFD740) : const Color(0xFF92400E),
      isDark: isDark,
      isNeumorphic: isNeu,
      radius: isNeu
          ? 24
          : layoutType == 'layout_04' || layoutType == 'layout_06'
              ? 20
              : 16,
    );
  }
}
