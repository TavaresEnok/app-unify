import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/providers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../layouts/layout_03/theme.dart';

class SharedTraceRoutePage extends ConsumerStatefulWidget {
  const SharedTraceRoutePage({super.key});

  @override
  ConsumerState<SharedTraceRoutePage> createState() =>
      _SharedTraceRoutePageState();
}

class TraceHop {
  final int hop;
  final String ip;
  final String time;
  final String status;

  TraceHop({
    required this.hop,
    required this.ip,
    required this.time,
    required this.status,
  });
}

class _SharedTraceRoutePageState extends ConsumerState<SharedTraceRoutePage> {
  final TextEditingController _ipController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRunning = false;
  final List<TraceHop> _hops = [];
  String _currentStatus = "Aguardando início...";

  @override
  void dispose() {
    _ipController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startTraceRoute() async {
    final target = _ipController.text.trim();
    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite um IP ou Domínio.')),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _hops.clear();
      _currentStatus = "Iniciando Rota (Max 10 saltos)...";
    });

    FocusScope.of(context).unfocus();

    for (int ttl = 1; ttl <= 10; ttl++) {
      if (!_isRunning) break;

      setState(() {
        _currentStatus = "Testando Salto $ttl...";
      });

      try {
        final result = await _pingWithTtl(target, ttl);

        setState(() {
          _hops.add(result);
        });

        // Auto-scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent +
                80, // estimated item height
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }

        if (result.status == "Alcançado") {
          setState(() => _currentStatus = "Destino alcançado!");
          break;
        }
      } catch (e) {
        setState(() {
          _hops.add(TraceHop(hop: ttl, ip: "*", time: "*", status: "Erro: $e"));
        });
      }
    }

    setState(() {
      _isRunning = false;
      if (_currentStatus.startsWith("Testando")) {
        _currentStatus = "Finalizado (Limite de 10 saltos).";
      }
    });
  }

  Future<TraceHop> _pingWithTtl(String target, int ttl) async {
    final stopwatch = Stopwatch()..start();
    ProcessResult? result;
    try {
      result = await Process.run(
          'ping', ['-c', '1', '-t', '$ttl', '-W', '2', target]);
    } catch (e) {
      stopwatch.stop();
      return TraceHop(
          hop: ttl, ip: "Erro", time: "", status: "Falha ao executar");
    }
    stopwatch.stop();

    final output = result.stdout.toString();
    // print("DEBUG: TTL $ttl Output: $output"); // Uncomment for debugging

    String ip = "*";
    String time = "${stopwatch.elapsedMilliseconds} ms";
    // Default time is wall-clock time (RTT approx)

    String status = "Sem Resposta";

    if (output.contains("Time to live exceeded") ||
        output.contains("exceeded")) {
      // checking for "exceeded" covers generic case
      status = "Salto $ttl"; // Cleaner status
      final match = RegExp(r"From\s+([0-9\.]+)(?::| )").firstMatch(output);
      if (match != null) {
        ip = match.group(1) ?? "*";
      }
    } else if (output.contains("bytes from")) {
      status = "Alcançado";
      final matchIp = RegExp(r"from\s+([0-9\.]+)(?::| )").firstMatch(output);
      if (matchIp != null) ip = matchIp.group(1) ?? target;

      // Try to parse exact ping time, fallback to stopwatch
      final matchTime = RegExp(r"time=([0-9\.]+)").firstMatch(output);
      if (matchTime != null) {
        time = "${matchTime.group(1)} ms";
      }
    } else if (output.contains("100% packet loss")) {
      time = "*";
      status = "Esgotado";
    }

    if (ip == "*" && status == "Sem Resposta") {
      status = "Tempo Esgotado";
      time = "*";
    }

    return TraceHop(hop: ttl, ip: ip, time: time, status: status);
  }

  Future<void> _sharePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Relatório de Rota (Tracert)',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text(DateTime.now().toString().split('.')[0]),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Alvo: ${_ipController.text}'),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Salto', 'IP', 'Tempo', 'Status'],
                  ..._hops.map((hop) =>
                      [hop.hop.toString(), hop.ip, hop.time, hop.status]),
                ],
              ),
            ],
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/trace_route_report.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)],
          text: 'Relatório de Rota (Tracert)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configProvider = ref.watch(configurationProvider);
    final layoutType = configProvider.providerConfig?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06' || layoutType == 'layout_04' || layoutType == 'layout_01' || layoutType == 'layout_11' || layoutType == 'layout_14';

    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
      appBarColor = theme.primaryColor;
      appBarTextColor = Colors.white;
    }

    final cardDecoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05 ? Layout03Theme.neumorphicDecoration : null);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Rota (Tracert)', style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarTextColor),
        actions: [
          if (_hops.isNotEmpty && !_isRunning)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
              tooltip: "Compartilhar PDF",
            )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isDarkLayout
                ? Container(
                    decoration: cardDecoration,
                    padding: const EdgeInsets.all(16),
                    child: _buildInputContent(context, isLayout05,
                        isDarkLayout: isDarkLayout),
                  )
                : (isLayout05
                    ? Container(
                        decoration: Layout03Theme.neumorphicDecoration,
                        padding: const EdgeInsets.all(16),
                        child: _buildInputContent(context, isLayout05,
                            isDarkLayout: isDarkLayout),
                      )
                    : DashboardCard(
                        child: _buildInputContent(context, isLayout05,
                            isDarkLayout: isDarkLayout),
                      )),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
              itemCount: _hops.length,
              itemBuilder: (context, index) {
                final hop = _hops[index];
                return _buildHopCard(hop, isLayout05,
                    isDarkLayout: isDarkLayout);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputContent(BuildContext context, bool isLayout05,
      {bool isDarkLayout = false}) {
    final textColor = isDarkLayout ? Colors.white : Colors.black87;
    // final primaryColor =
    //    isDarkLayout ? const Color(0xFF00D9FF) : Theme.of(context).primaryColor;

    return Column(
      children: [
        TextField(
          controller: _ipController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'IP ou Domínio de Destino',
            labelStyle:
                TextStyle(color: isDarkLayout ? const Color(0xFF8E8E93) : null),
            hintText: 'Ex: 8.8.8.8 ou google.com',
            hintStyle:
                TextStyle(color: isDarkLayout ? const Color(0xFF8E8E93) : null),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                  color: isDarkLayout ? const Color(0xFF3A3A3C) : Colors.grey),
            ),
            enabledBorder: isDarkLayout
                ? OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            focusedBorder: isDarkLayout
                ? OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            prefixIcon: Icon(Icons.search,
                color: isDarkLayout ? const Color(0xFF8E8E93) : null),
            filled: isLayout05 || isDarkLayout,
            fillColor: isDarkLayout
                ? const Color(0xFF1C1C1E)
                : (isLayout05 ? Colors.white.withValues(alpha: 0.5) : null),
          ),
          onSubmitted: (_) => _isRunning ? null : _startTraceRoute(),
        ),
        const SizedBox(height: 16),
        Text(_currentStatus,
            style: TextStyle(
                color: _isRunning
                    ? (isDarkLayout
                        ? const Color(0xFF00D9FF)
                        : (isLayout05
                            ? Layout03Theme.primary
                            : Theme.of(context).primaryColor))
                    : (isDarkLayout ? const Color(0xFF8E8E93) : Colors.grey))),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: isDarkLayout
              ? ElevatedButton.icon(
                  onPressed: () {
                    if (_isRunning) {
                      setState(() => _isRunning = false);
                    } else {
                      _startTraceRoute();
                    }
                  },
                  icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow,
                      color: Colors.black),
                  label: Text(_isRunning ? "Parar" : "Iniciar Rota",
                      style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )
              : AppButton(
                  label: _isRunning ? "Parar" : "Iniciar Rota",
                  icon: _isRunning ? Icons.stop : Icons.play_arrow,
                  onPressed: () {
                    if (_isRunning) {
                      setState(() => _isRunning = false);
                    } else {
                      _startTraceRoute();
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHopCard(TraceHop hop, bool isLayout05,
      {bool isDarkLayout = false}) {
    if (isDarkLayout) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: hop.status == "Alcançado"
                ? const Color(0xFF00D9FF)
                : const Color(0xFF3A3A3C),
            child: Text("${hop.hop}",
                style: TextStyle(
                    color: hop.status == "Alcançado"
                        ? Colors.black
                        : Colors.white)),
          ),
          title: Text(hop.ip,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text(hop.status,
              style: const TextStyle(color: Color(0xFF8E8E93))),
          trailing: Text(hop.time,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF00D9FF))),
        ),
      );
    }
    if (isLayout05) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: Layout03Theme.neumorphicDecoration.copyWith(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: hop.status == "Alcançado"
                ? Layout03Theme.primary
                : Layout03Theme.textGrey.withValues(alpha: 0.3),
            child: Text("${hop.hop}",
                style: TextStyle(
                    color: hop.status == "Alcançado"
                        ? Colors.white
                        : Layout03Theme.textDark)),
          ),
          title: Text(hop.ip,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Layout03Theme.textDark)),
          subtitle: Text(hop.status,
              style: const TextStyle(color: Layout03Theme.textGrey)),
          trailing: Text(hop.time,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Layout03Theme.textDark)),
        ),
      );
    }
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              hop.status == "Alcançado" ? Colors.green : Colors.grey[300],
          child: Text("${hop.hop}",
              style: TextStyle(
                  color: hop.status == "Alcançado"
                      ? Colors.white
                      : Colors.black87)),
        ),
        title:
            Text(hop.ip, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(hop.status),
        trailing:
            Text(hop.time, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
