import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/dashboard_card.dart';

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
  List<TraceHop> _hops = [];
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
      _currentStatus = "Iniciando Rota (Max 6 saltos)...";
    });

    FocusScope.of(context).unfocus();

    for (int ttl = 1; ttl <= 6; ttl++) {
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
        _currentStatus = "Finalizado (Limite de 6 saltos).";
      }
    });
  }

  Future<TraceHop> _pingWithTtl(String target, int ttl) async {
    // Ping command options:
    // -c 1: Count 1
    // -t <ttl>: Set TTL (Linux/Android)
    // -W 2: Timeout 2 seconds

    // Note: 'ping' behavior might vary slightly by Android version/ROM,
    // but '-t' is standard for TTL on linux-based ping.

    ProcessResult? result;
    try {
      result = await Process.run(
          'ping', ['-c', '1', '-t', '$ttl', '-W', '2', target]);
    } catch (e) {
      return TraceHop(
          hop: ttl, ip: "Erro", time: "", status: "Falha ao executar ping");
    }

    final output = result.stdout.toString();

    // Parse output
    // Case 1: TTL Exceeded (Intermediate Hop)
    // "From 192.168.1.1: icmp_seq=1 Time to live exceeded"
    // Case 2: Reply (Target Reached)
    // "64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=14.2 ms"
    // Case 3: Timeout/Unreachable

    String ip = "*";
    String time = "*";
    String status = "Timeout";

    if (output.contains("Time to live exceeded")) {
      status = "Salto Interm. (TTL Expirado)";
      // Extract IP from "From 1.2.3.4"
      final match = RegExp(r"From\s+([0-9\.]+)(?::| )").firstMatch(output);
      if (match != null) {
        ip = match.group(1) ?? "*";
      }
      // Time isn't usually valid for TTL exceeded in standard ping output unless parsing detailed ICMP,
      // often it just says 'Time to live exceeded' without RTT.
      // We can try to assume it took 'some' time but ping doesn't always show it for errors.
      // Let's check if there is 'time=' anywhere.
    } else if (output.contains("bytes from")) {
      status = "Alcançado";
      // Extract IP
      final matchIp = RegExp(r"from\s+([0-9\.]+)(?::| )").firstMatch(output);
      if (matchIp != null) ip = matchIp.group(1) ?? target;

      // Extract Time
      final matchTime = RegExp(r"time=([0-9\.]+)").firstMatch(output);
      if (matchTime != null) time = "${matchTime.group(1)} ms";
    }

    if (ip == "*" && output.contains("100% packet loss")) {
      return TraceHop(hop: ttl, ip: "*", time: "*", status: "Sem Resposta");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota (Tracert)'),
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
            child: DashboardCard(
              child: Column(
                children: [
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'IP ou Domínio de Destino',
                      hintText: 'Ex: 8.8.8.8 ou google.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _isRunning ? null : _startTraceRoute(),
                  ),
                  const SizedBox(height: 16),
                  Text(_currentStatus,
                      style: TextStyle(
                          color: _isRunning
                              ? Theme.of(context).primaryColor
                              : Colors.grey)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
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
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _hops.length,
              itemBuilder: (context, index) {
                final hop = _hops[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: hop.status == "Alcançado"
                          ? Colors.green
                          : Colors.grey[300],
                      child: Text("${hop.hop}",
                          style: TextStyle(
                              color: hop.status == "Alcançado"
                                  ? Colors.white
                                  : Colors.black87)),
                    ),
                    title: Text(hop.ip,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(hop.status),
                    trailing: Text(hop.time,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
