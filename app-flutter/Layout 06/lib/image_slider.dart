// ARQUIVO: lib/image_slider.dart (MANTIDO E GARANTIDO)

import 'dart:async';
import 'package:flutter/material.dart';
import 'utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final double? height;
  final Color? backgroundColor; // Recebe a cor já resolvida

  const ImageSlider({
    super.key,
    required this.imageUrls,
    this.height,
    this.backgroundColor,
  });

  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> with SingleTickerProviderStateMixin {
  // --- VARIÁVEIS DE ESTADO RESTAURADAS ---
  late final PageController _pageController;
  late final AnimationController _shimmerController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  late Color _effectiveBackgroundColor;
  // -------------------------------------

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage, viewportFraction: 1.0);
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1200));

    // Usa a cor passada ou um fallback seguro
    _effectiveBackgroundColor = widget.backgroundColor ?? hexToColor('#673AB7');

    if (widget.imageUrls.length > 1) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  // --- MÉTODOS RESTAURADOS ---
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (widget.imageUrls.isEmpty || !mounted || !_pageController.hasClients) return;
      int nextPage = _pageController.page!.round() + 1;
      if (nextPage >= widget.imageUrls.length) {
        nextPage = 0;
      }
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Widget _buildShimmerPlaceholder() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
                begin: Alignment.topLeft,

                end: Alignment.centerRight,
                colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                stops: [_shimmerController.value - 0.3, _shimmerController.value, _shimmerController.value + 0.3]
            ).createShader(bounds);
          },
          child: Container(
            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(0),
              color: Colors.black.withOpacity(0.1),
            ),
          ),
        );
      },
    );
  }
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: Container(
        color: _effectiveBackgroundColor,
        child: Listener(
          onPointerDown: (_) => _autoScrollTimer?.cancel(),
          onPointerUp: (_) {
            if (widget.imageUrls.length > 1) _startAutoScroll();
          },
          child: PageView.builder(

            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },

            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: SizedBox.expand(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.cover,
                    // Mostra o shimmer que já tínhamos enquanto carrega
                    placeholder: (context, url) => _buildShimmerPlaceholder(),
                    // Mostra um ícone de erro se falhar
                    errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(

                          borderRadius: BorderRadius.circular(0),
                          color: Colors.black.withOpacity(0.1),
                        ),
                        child: Center(child: Icon(Icons.error_outline, color: Colors.white.withOpacity(0.2)))

                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}