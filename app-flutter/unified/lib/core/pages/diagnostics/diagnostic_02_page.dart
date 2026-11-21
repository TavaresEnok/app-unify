import 'package:flutter/material.dart';
import '../shared_diagnostico_page.dart';

/// Presentation only: all diagnostics use the same execution and results.
class Diagnostic02Page extends StatelessWidget {
  const Diagnostic02Page({super.key});
  @override
  Widget build(BuildContext context) =>
      const DiagnosticoPage(appearance: 'layout_04');
}

typedef DiagnosticPage = Diagnostic02Page;
