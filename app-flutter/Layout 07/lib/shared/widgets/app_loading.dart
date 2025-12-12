import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  final String? label;
  const AppLoading({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ]
        ],
      ),
    );
  }
}
