import 'package:flutter/material.dart';
import '../shared_diagnostico_page.dart';

/// Presentation only: all diagnostics use the same execution and results.
class Diagnostic05Page extends StatelessWidget {
  const Diagnostic05Page({super.key});
  @override
  Widget build(BuildContext context) =>
      const DiagnosticoPage(appearance: 'layout_02');
}
