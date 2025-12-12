import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'shared/widgets/app_page.dart';

class DownDetectorPage extends StatefulWidget {
  const DownDetectorPage({super.key});

  @override
  State<DownDetectorPage> createState() => _DownDetectorPageState();
}

class _DownDetectorPageState extends State<DownDetectorPage> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: "Status dos Serviços",
      isLoading: _isLoading,
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri("https://downdetector.com.br/"),
        ),
        onLoadStop: (controller, url) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      ),
    );
  }
}
