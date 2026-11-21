import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Estilo da barra de navegação de cada layout (classe `.nv` do protótipo).
enum VibeNavStyle { standard, circle, dock }

/// Paleta e medidas do layout aprovado (layout-app/vibe-5-definitivas.html).
///
/// Só a cor da marca e a aparência (clara ou escura) variam, como nos
/// controles da galeria do protótipo. Os valores vêm do CSS do protótipo:
/// `#galeria .ph`, `.ph.dk` e, na tela Dock, a função `palette()`.
@immutable
class VibeTokens extends ThemeExtension<VibeTokens> {
  const VibeTokens({
    required this.layout,
    required this.dark,
    required this.fontFamily,
    required this.variableFamily,
    required this.ac,
    required this.on,
    required this.at,
    required this.bg,
    required this.card,
    required this.ink,
    required this.mut,
    required this.line,
    required this.neub,
    required this.chn,
    required this.ok,
    required this.okb,
    required this.wa,
    required this.wab,
    required this.bad,
    required this.badb,
    required this.hero,
    required this.hx,
    required this.rad,
    required this.nav,
    required this.homeStatusOnBrand,
    this.dock,
  });

  /// `layout_02` … `layout_06`.
  final String layout;
  final bool dark;

  /// Família estática (pesos 400–800) e, quando existe, a variável usada
  /// para os pesos intermediários do layout (650, 750, 780…).
  final String fontFamily;
  final String? variableFamily;

  /// Marca, texto sobre a marca e marca como texto (`--ac`, `--on`, `--at`).
  final Color ac, on, at;
  final Color bg, card, ink, mut, line, neub, chn;
  final Color ok, okb, wa, wab, bad, badb;

  /// Faixa do cabeçalho das páginas internas (`--g-hero`, `--g-hx`) e o
  /// raio herdado do layout (`--g-rad`).
  final Color hero, hx;
  final double rad;
  final VibeNavStyle nav;

  /// A faixa de status do Início fica na cor da marca (layouts com topo
  /// colorido) ou na cor do fundo.
  final bool homeStatusOnBrand;

  /// Paleta própria da tela Dock de serviços (layout_03).
  final VibeDockPalette? dock;

  static const _layouts = {
    'layout_02',
    'layout_03',
    'layout_04',
    'layout_05',
    'layout_06'
  };

  static String normalize(String? layout) =>
      _layouts.contains(layout) ? layout! : 'layout_06';

  static VibeTokens of(BuildContext context) =>
      Theme.of(context).extension<VibeTokens>() ??
      VibeTokens.resolve(layout: null, brand: const Color(0xFF2456C9));

  /// Monta os tokens do [layout] para a cor [brand] da marca.
  factory VibeTokens.resolve({
    required String? layout,
    required Color brand,
    bool dark = false,
  }) {
    final id = normalize(layout);
    final ac = Color(0xFF000000 | (brand.toARGB32() & 0xFFFFFF));
    // Texto sobre a marca: branco quando é legível; senão o tom escuro da
    // própria marca (como `--on:#301025` no rosa da galeria) ou preto.
    final onCandidates = [
      Colors.white,
      vibeMix(ac, Colors.black, .81),
      Colors.black
    ];
    final on = onCandidates.firstWhere((c) => vibeContrast(c, ac) >= 4.5,
        orElse: () => onCandidates.reduce(
            (a, b) => vibeContrast(a, ac) >= vibeContrast(b, ac) ? a : b));
    final bg = dark ? const Color(0xFF101319) : const Color(0xFFF5F6F9);
    final card = dark ? const Color(0xFF1C2029) : Colors.white;
    final at = dark
        ? vibeReadable(vibeMix(ac, Colors.white, .38), card)
        : vibeReadable(ac, Colors.white);
    final hx = vibeLuminance(ac) > .2 ? const Color(0xFF111827) : Colors.white;
    final (family, variable) = switch (id) {
      'layout_06' => ('Sora', 'SoraVar'),
      'layout_03' => ('Inter', null),
      _ => ('PlusJakartaSans', 'PlusJakartaSansVar'),
    };
    final base = VibeTokens(
      layout: id,
      dark: dark,
      fontFamily: family,
      variableFamily: variable,
      ac: ac,
      on: on,
      at: at,
      bg: bg,
      card: card,
      ink: dark ? const Color(0xFFF5F6FA) : const Color(0xFF18202C),
      mut: dark ? const Color(0xFFB4BDCC) : const Color(0xFF596577),
      line: dark ? const Color(0xFF393F4C) : const Color(0xFFDCE1E8),
      neub: dark ? const Color(0xFF22252B) : const Color(0xFFEEF1F5),
      chn: dark ? const Color(0xFFD7DAE0) : const Color(0xFF3B4250),
      ok: dark ? const Color(0xFF6EE29B) : const Color(0xFF137A3E),
      okb: dark ? const Color(0x2922C55E) : const Color(0xFFE3F4EA),
      wa: dark ? const Color(0xFFFBBF4C) : const Color(0xFFA35B00),
      wab: dark ? const Color(0x29F59E0B) : const Color(0xFFFFF1DC),
      bad: dark ? const Color(0xFFFF8F8F) : const Color(0xFFC21F2D),
      badb: dark ? const Color(0x29EF4444) : const Color(0xFFFDE8EA),
      hero: ac,
      hx: hx,
      // Raio do bloco de destaque de cada layout, limitado a 12–26 (tokA).
      rad: switch (id) { 'layout_05' => 26, 'layout_04' => 20, _ => 18 },
      nav: switch (id) {
        'layout_04' || 'layout_06' => VibeNavStyle.circle,
        'layout_03' => VibeNavStyle.dock,
        _ => VibeNavStyle.standard,
      },
      homeStatusOnBrand:
          const {'layout_02', 'layout_05', 'layout_06'}.contains(id),
    );
    if (id != 'layout_03') return base;
    final p = VibeDockPalette.resolve(ac, dark: dark);
    return base.copyWith(
      ac: p.brand,
      on: p.onbrand,
      at: p.brand,
      bg: p.base,
      card: p.card,
      ink: p.ink,
      mut: p.muted,
      line: p.hair,
      hero: p.hero,
      hx: p.hink,
      rad: 16,
      dock: p,
    );
  }

  /// Fundo translúcido de selos, sino, avatar e botões sobre a marca.
  Color overlayOnBrand([double light = .18]) => on == Colors.white
      ? Colors.black.withValues(alpha: .14)
      : Colors.white.withValues(alpha: light);

  /// Texto do botão branco sobre a marca (`.b.w`).
  Color get whiteButtonText =>
      on == Colors.white ? (dark ? ac : at) : vibeMix(ac, Colors.black, .45);

  /// Caixa tingida pela marca: `color-mix(var(--ac) N%, #fff)` no claro e a
  /// mistura com a base escura indicada no escuro (`.ph.dk`).
  Color tinted(double light,
          {double darkAmount = .26,
          Color darkBase = const Color(0xFF16181D)}) =>
      dark
          ? vibeMix(darkBase, ac, darkAmount)
          : vibeMix(Colors.white, ac, light);

  Color toneText(VibeTone tone) => switch (tone) {
        VibeTone.neutral => chn,
        VibeTone.warning => wa,
        VibeTone.bad => bad,
        VibeTone.ok => ok,
      };

  Color toneBackground(VibeTone tone) => switch (tone) {
        VibeTone.neutral => neub,
        VibeTone.warning => wab,
        VibeTone.bad => badb,
        VibeTone.ok => okb,
      };

  @override
  VibeTokens copyWith({
    Color? ac,
    Color? on,
    Color? at,
    Color? bg,
    Color? card,
    Color? ink,
    Color? mut,
    Color? line,
    Color? hero,
    Color? hx,
    double? rad,
    VibeDockPalette? dock,
  }) =>
      VibeTokens(
        layout: layout,
        dark: dark,
        fontFamily: fontFamily,
        variableFamily: variableFamily,
        ac: ac ?? this.ac,
        on: on ?? this.on,
        at: at ?? this.at,
        bg: bg ?? this.bg,
        card: card ?? this.card,
        ink: ink ?? this.ink,
        mut: mut ?? this.mut,
        line: line ?? this.line,
        neub: neub,
        chn: chn,
        ok: ok,
        okb: okb,
        wa: wa,
        wab: wab,
        bad: bad,
        badb: badb,
        hero: hero ?? this.hero,
        hx: hx ?? this.hx,
        rad: rad ?? this.rad,
        nav: nav,
        homeStatusOnBrand: homeStatusOnBrand,
        dock: dock ?? this.dock,
      );

  @override
  VibeTokens lerp(covariant VibeTokens? other, double t) =>
      other == null || t < .5 ? this : other;
}

/// Situação da fatura nos selos e textos (`t-neu`, `t-wa`, `t-bad`, `t-ok`).
enum VibeTone { neutral, warning, bad, ok }

/// Paleta da tela Dock (`palette(d)` da página das 9 telas, conceito 22).
@immutable
class VibeDockPalette {
  const VibeDockPalette({
    required this.base,
    required this.card,
    required this.soft,
    required this.ink,
    required this.muted,
    required this.hair,
    required this.brand,
    required this.onbrand,
    required this.hero,
    required this.hink,
    required this.hmuted,
    required this.hthin,
    required this.htint,
    required this.main,
    required this.onmain,
    required this.wash,
    required this.mark,
    required this.onwash,
  });

  final Color base, card, soft, ink, muted, hair, brand, onbrand;
  final Color hero, hink, hmuted, hthin, htint, main, onmain;
  final Color wash, mark, onwash;

  factory VibeDockPalette.resolve(Color a, {bool dark = false}) {
    final base = dark
        ? vibeMix(const Color(0xFF121513), a, .065)
        : vibeMix(const Color(0xFFFAFBF9), a, .045);
    final card =
        dark ? vibeMix(const Color(0xFF1E221F), a, .075) : Colors.white;
    final soft = vibeMix(card, a, dark ? .14 : .115);
    final tx = dark ? const Color(0xFFF6F8F5) : const Color(0xFF19221C);
    final hero = vibeMix(const Color(0xFF101915), a, .43);
    final hx = _inkFor(hero);
    final main = vibeReadable(a, hero, minimum: 3);
    final brand = vibeReadable(a, base, minimum: 4.65);
    return VibeDockPalette(
      base: base,
      card: card,
      soft: soft,
      ink: tx,
      muted: vibeReadable(vibeMix(tx, base, .31), base, minimum: 4.65),
      hair: vibeMix(card, tx, dark ? .22 : .20),
      brand: brand,
      onbrand: _inkFor(brand),
      hero: hero,
      hink: hx,
      hmuted: vibeReadable(vibeMix(hx, hero, .20), hero, minimum: 4.65),
      hthin: vibeMix(hero, hx, .24),
      htint: _shaded(hero, hx, .075),
      main: main,
      onmain: _inkFor(main),
      wash: vibeMix(base, a, dark ? .15 : .13),
      mark: vibeReadable(a, card, minimum: 4.65),
      onwash: vibeReadable(a, soft, minimum: 4.65),
    );
  }

  static Color _inkFor(Color bg) =>
      vibeContrast(const Color(0xFF101411), bg) >= 4.65
          ? const Color(0xFF101411)
          : vibeContrast(Colors.white, bg) >= 4.5
              ? Colors.white
              : Colors.black;

  static Color _shaded(Color bg, Color fg, double weight) {
    final tint = vibeMix(bg, fg, weight);
    return vibeContrast(tint, fg) >= 4.65
        ? tint
        : vibeMix(bg, fg == Colors.white ? Colors.black : Colors.white, weight);
  }
}

/// `color-mix(in srgb, a (1-t), b t)`.
Color vibeMix(Color a, Color b, double t) {
  int ch(double x, double y) =>
      ((x * (1 - t) + y * t) * 255).round().clamp(0, 255);
  return Color.fromARGB(255, ch(a.r, b.r), ch(a.g, b.g), ch(a.b, b.b));
}

double vibeLuminance(Color c) {
  double lin(double v) =>
      v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
  return .2126 * lin(c.r) + .7152 * lin(c.g) + .0722 * lin(c.b);
}

double vibeContrast(Color a, Color b) {
  final x = vibeLuminance(a), y = vibeLuminance(b);
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

/// Aproxima [fg] do preto ou do branco até atingir o contraste mínimo.
Color vibeReadable(Color fg, Color bg, {double minimum = 4.5}) {
  if (vibeContrast(fg, bg) >= minimum) return fg;
  final target =
      vibeContrast(Colors.black, bg) >= vibeContrast(Colors.white, bg)
          ? Colors.black
          : Colors.white;
  for (var i = 1; i <= 20; i++) {
    final c = vibeMix(fg, target, i / 20);
    if (vibeContrast(c, bg) >= minimum) return c;
  }
  return target;
}
