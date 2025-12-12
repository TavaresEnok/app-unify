import 'package:flutter/material.dart';
import 'app_error.dart';
import 'app_loading.dart';
import '../theme/app_colors.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const AppLoading();
    }
    if (error != null) {
      return AppError(message: error!, onRetry: onRetry);
    }
    return body;
  }
}
