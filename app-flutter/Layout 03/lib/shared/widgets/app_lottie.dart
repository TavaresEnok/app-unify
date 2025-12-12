import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLottie extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool repeat;

  const AppLottie(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.repeat = true,
  });

  @override
  Widget build(BuildContext context) {
    // Se for uma URL remota
    if (asset.startsWith('http')) {
      return Lottie.network(
        asset,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        repeat: repeat,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error_outline, size: 50, color: Colors.grey);
        },
      );
    }
    
    // Se for um asset local
    return Lottie.asset(
      asset,
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
      repeat: repeat,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
      },
    );
  }
}
