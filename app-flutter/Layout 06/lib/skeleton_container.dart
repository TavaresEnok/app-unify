// ARQUIVO: lib/widgets/skeleton_container.dart

import 'package:flutter/material.dart';

class SkeletonContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const SkeletonContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius,
      ),
    );
  }
}