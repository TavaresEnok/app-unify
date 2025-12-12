import 'package:flutter/material.dart';
import 'app_error.dart';
import 'app_loading.dart';

class AppPage extends StatelessWidget {
  final String title;
  final Widget body;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const AppLoading();
    }
    if (error != null) {
      return AppError(message: error!, onRetry: onRetry);
    }
    return body;
  }
}
