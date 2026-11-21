import 'package:flutter/material.dart';
import '../shared_diagnostico_page.dart';

/// Presentation only: all diagnostics use the same execution and results.
class Diagnostic06Page extends StatelessWidget {
  const Diagnostic06Page({super.key});
  @override
  Widget build(BuildContext context) =>
      const DiagnosticoPage(appearance: 'layout_03');
}
