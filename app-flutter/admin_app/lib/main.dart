import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Painel',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const AdminWebView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminWebView extends StatefulWidget {
  const AdminWebView({super.key});

  @override
  State<AdminWebView> createState() => _AdminWebViewState();
}

class _AdminWebViewState extends State<AdminWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  // URL inferred from Firebase config
  final String _adminUrl = 'https://app-ajust-provedor.web.app';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_adminUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _controller.reload(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
