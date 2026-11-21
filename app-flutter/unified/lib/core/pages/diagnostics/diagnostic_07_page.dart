import 'package:flutter/material.dart';
import '../shared_diagnostico_page.dart';

/// Presentation only: all diagnostics use the same execution and results.
class Diagnostic07Page extends StatelessWidget {
  const Diagnostic07Page({super.key});
  @override
  Widget build(BuildContext context) =>
      const DiagnosticoPage(appearance: 'layout_06');
}
