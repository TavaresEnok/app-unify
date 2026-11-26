import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'vibe_text.dart';
import 'vibe_tokens.dart';

/// Marca do provedor nas telas do layout aprovado (`.lg` do protótipo).
///
/// O protótipo desenha a marca da Vibe em vetor. No app a marca é a imagem
/// enviada pelo provedor, que costuma vir quadrada, com muita margem
/// transparente e nas cores da própria marca. Por isso a imagem é lida uma
/// vez: a margem transparente é recortada e a cor média decide a
/// apresentação. Se a logo se confunde com o fundo, ela vai sobre uma placa
/// clara ou escura, como a caixa branca `.wt .lm` do protótipo. Sem imagem
/// (ou se ela falhar), vale a inicial em caixa e o nome.
class VibeLogo extends StatefulWidget {
  const VibeLogo({
    super.key,
    required this.name,
    this.logoUrl,
    this.onBrand = false,
    this.height = 30,
    this.maxWidth = 190,
    this.image,
    this.background,
    this.fallback,
  });

  final String name;
  final String? logoUrl;
  final bool onBrand;
  final double height;
  final double maxWidth;

  /// Imagem já resolvida (testes e prévias); sem ela, usa [logoUrl].
  final ImageProvider? image;

  /// Cor atrás da marca, quando não é a da marca nem a do fundo do layout.
  final Color? background;

  /// O que mostrar sem imagem, no lugar da inicial em caixa com o nome.
  final Widget? fallback;

  @override
  State<VibeLogo> createState() => _VibeLogoState();
}

/// Resultado da leitura de uma logo: a imagem sem fundo, a área útil, a cor
/// média do desenho e a cor do fundo original, quando havia um.
class VibeLogoAnalysis {
  const VibeLogoAnalysis(this.image, this.bounds, this.average, this.matte);
  final ui.Image image;
  final Rect bounds;
  final Color average;

  /// Fundo uniforme que a imagem trazia (em geral branco) e foi removido.
  final Color? matte;

  static final Map<Object, VibeLogoAnalysis> _cache = {};

  /// Lê [image]: remove o fundo uniforme, recorta a margem vazia e calcula a
  /// cor média do desenho.
  static Future<VibeLogoAnalysis> of(Object key, ui.Image image) async {
    final cached = _cache[key];
    if (cached != null) return cached;
    final w = image.width, h = image.height;
    final full = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    final data =
        await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    if (data == null) {
      return _cache[key] =
          VibeLogoAnalysis(image, full, const Color(0xFF808080), null);
    }
    final px = Uint8List.fromList(data.buffer.asUint8List());

    // Fundo uniforme: os quatro cantos opacos e da mesma cor.
    int at(int x, int y) => (y * w + x) * 4;
    final corners = [at(0, 0), at(w - 1, 0), at(0, h - 1), at(w - 1, h - 1)];
    var uniform = corners.every((i) => px[i + 3] > 250);
    for (final i in corners) {
      for (var c = 0; c < 3; c++) {
        if ((px[i + c] - px[corners.first + c]).abs() > 6) uniform = false;
      }
    }
    Color? matte;
    if (uniform) {
      final br = px[corners.first],
          bgG = px[corners.first + 1],
          bb = px[corners.first + 2];
      matte = Color.fromARGB(255, br, bgG, bb);
      final bg = [br, bgG, bb];
      // "Cor para alfa": cada pixel vira o desenho sobre o fundo, com a
      // transparência que reproduz a mistura original. Mantém as bordas
      // suaves em vez de recortar no serrilhado.
      for (var i = 0; i < px.length; i += 4) {
        var alpha = 0.0;
        for (var c = 0; c < 3; c++) {
          final v = px[i + c], k = bg[c];
          final a = v > k
              ? (k == 255 ? 1.0 : (v - k) / (255 - k))
              : v < k
                  ? (k == 0 ? 1.0 : (k - v) / k)
                  : 0.0;
          if (a > alpha) alpha = a;
        }
        if (alpha < .02) {
          px[i + 3] = 0;
          continue;
        }
        for (var c = 0; c < 3; c++) {
          px[i + c] =
              ((px[i + c] - bg[c]) / alpha + bg[c]).round().clamp(0, 255);
        }
        px[i + 3] = (alpha * px[i + 3]).round().clamp(0, 255);
      }
    }

    var left = w, top = h, right = -1, bottom = -1;
    double r = 0, g = 0, b = 0, weight = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        final a = px[i + 3];
        if (a < 24) continue;
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
        final k = a / 255;
        r += px[i] * k;
        g += px[i + 1] * k;
        b += px[i + 2] * k;
        weight += k;
      }
    }
    final bounds = right < left || bottom < top
        ? full
        : Rect.fromLTRB(
                math.max(0, left - 1).toDouble(),
                math.max(0, top - 1).toDouble(),
                math.min(w, right + 2).toDouble(),
                math.min(h, bottom + 2).toDouble())
            .intersect(full);
    final average = weight == 0
        ? const Color(0xFF808080)
        : Color.fromARGB(255, (r / weight).round(), (g / weight).round(),
            (b / weight).round());

    var result = image;
    if (matte != null) {
      // O motor espera alfa pré-multiplicado.
      for (var i = 0; i < px.length; i += 4) {
        final a = px[i + 3];
        if (a == 255) continue;
        px[i] = px[i] * a ~/ 255;
        px[i + 1] = px[i + 1] * a ~/ 255;
        px[i + 2] = px[i + 2] * a ~/ 255;
      }
      final done = Completer<ui.Image>();
      ui.decodeImageFromPixels(
          px, w, h, ui.PixelFormat.rgba8888, done.complete);
      result = await done.future;
    }
    return _cache[key] = VibeLogoAnalysis(result, bounds, average, matte);
  }
}

class _VibeLogoState extends State<VibeLogo> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  VibeLogoAnalysis? _analysis;
  bool _failed = false;
  Object? _key;

  ImageProvider? get _provider {
    if (widget.image != null) return widget.image;
    final url = widget.logoUrl?.trim() ?? '';
    final uri = Uri.tryParse(url);
    if (url.isEmpty ||
        uri == null ||
        !(uri.scheme == 'https' || uri.scheme == 'http')) {
      return null;
    }
    // 512 px de largura bastam para a marca e limitam o custo da leitura.
    // Cache em disco: a partir da segunda abertura a marca aparece na hora,
    // sem o espaço vazio enquanto baixa.
    return ResizeImage.resizeIfNeeded(512, null, vibeLogoImageProvider(url));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(VibeLogo old) {
    super.didUpdateWidget(old);
    if (old.logoUrl != widget.logoUrl || old.image != widget.image) _resolve();
  }

  void _resolve() {
    final provider = _provider;
    final key = widget.image ?? widget.logoUrl;
    if (key == _key && (_analysis != null || _failed || _stream != null)) {
      return;
    }
    _detach();
    _key = key;
    _analysis = null;
    _failed = provider == null;
    if (provider == null) return;
    final cached = VibeLogoAnalysis._cache[key!];
    if (cached != null) {
      _analysis = cached;
      return;
    }
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) async {
      // Cópia própria: o cache de imagens pode descartar a original.
      final image = info.image.clone();
      info.dispose();
      final analysis = await VibeLogoAnalysis.of(key, image);
      if (mounted && _key == key) setState(() => _analysis = analysis);
    }, onError: (_, __) {
      if (mounted && _key == key) setState(() => _failed = true);
    });
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final name = widget.name.trim();
    final background = widget.background ?? (widget.onBrand ? t.ac : t.bg);
    final analysis = _analysis;
    Widget child;
    if (analysis != null) {
      final aspect = analysis.bounds.width / analysis.bounds.height;
      final direct = vibeContrast(analysis.average, background) >= 2.4;
      // Sem contraste com o fundo, a logo vai sobre uma placa: a cor do
      // fundo que a própria imagem trazia ou, sem ela, branco ou grafite.
      final matte = analysis.matte;
      final plate = direct
          ? null
          : matte != null && vibeContrast(analysis.average, matte) >= 1.6
              ? matte
              : vibeContrast(analysis.average, Colors.white) >= 1.6
                  ? Colors.white
                  : const Color(0xFF15171C);
      // Com placa a imagem fica um pouco menor, para sobrar o respiro.
      final imageHeight = plate == null ? widget.height : widget.height - 8;
      final padH = plate == null ? 0.0 : 9.0;
      final width = math.min(imageHeight * aspect, widget.maxWidth - padH * 2);
      final image = SizedBox(
        width: width,
        height: math.min(imageHeight, width / aspect),
        child: CustomPaint(painter: _LogoPainter(analysis)),
      );
      // `widthFactor: 1` mantém a largura da própria marca, sem esticar.
      child = plate == null
          ? SizedBox(
              height: widget.height,
              child: Center(widthFactor: 1, child: image))
          : Container(
              height: widget.height,
              padding: EdgeInsets.symmetric(horizontal: padH),
              decoration: BoxDecoration(
                  color: plate, borderRadius: BorderRadius.circular(9)),
              child: Center(widthFactor: 1, child: image),
            );
    } else if (_failed) {
      child = widget.fallback ?? _fallback(t, name);
    } else {
      // Enquanto a imagem carrega, reserva a altura sem piscar o nome.
      child = SizedBox(height: widget.height, width: widget.height);
    }
    return Semantics(
      label: name.isEmpty ? 'Marca do provedor' : name,
      image: analysis != null,
      excludeSemantics: true,
      child: child,
    );
  }

  /// Inicial em caixa e nome (`.lm` + `b` do protótipo).
  Widget _fallback(VibeTokens t, String name) {
    final onBrand = widget.onBrand;
    final box = widget.height;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: box,
        height: box,
        decoration: BoxDecoration(
            color: onBrand ? Colors.white : t.ac,
            borderRadius: BorderRadius.circular(box * .3)),
        alignment: Alignment.center,
        child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: vibeText(t, box * .53, 800,
                color: onBrand ? t.whiteButtonText : t.on, height: 1)),
      ),
      if (name.isNotEmpty) ...[
        const SizedBox(width: 8),
        Flexible(
          child: Text(name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: vibeText(t, box * .67, 800,
                  color: onBrand ? t.on : t.ink,
                  height: 1.15,
                  letterSpacingEm: -.03)),
        ),
      ],
    ]);
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.analysis);
  final VibeLogoAnalysis analysis;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
        analysis.image,
        analysis.bounds,
        Offset.zero & size,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.analysis != analysis;
}

/// Imagem de rede da marca com cache em disco. Em testes (sem os plugins de
/// arquivo) usa a imagem de rede comum.
ImageProvider vibeLogoImageProvider(String url) {
  if (vibeLogoDiskCache) return CachedNetworkImageProvider(url);
  return NetworkImage(url);
}

/// Desligado nos testes de widget, que não têm sistema de arquivos.
bool vibeLogoDiskCache =
    !const bool.fromEnvironment('FLUTTER_TEST') && !_isFlutterTest();

bool _isFlutterTest() {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}
