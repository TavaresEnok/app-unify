import 'package:flutter/material.dart';

/// Widget de banner promocional
class BannerWidget extends StatelessWidget {
  final Map<String, dynamic> config;

  const BannerWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final imageUrl = config['image'] as String?;
    final link = config['link'] as String?;
    final height = (config['height'] as num?)?.toDouble() ?? 180.0;

    if (imageUrl == null) {
      return const SizedBox.shrink();
    }

    Widget banner = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      ),
    );

    if (link != null && link.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          // TODO: Abrir link externo ou navegar
          print('Banner clicado: $link');
        },
        child: banner,
      );
    }

    return banner;
  }
}
