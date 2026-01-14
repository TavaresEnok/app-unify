import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/utils/shared_theme_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    final configProvider = ref.watch(configurationProvider);
    final layoutType = configProvider.providerConfig?.layoutType;

    // Theme variables
    final isLayout03 =
        SharedThemeHelper.isNeumorphic(layoutType) || layoutType == 'layout_05';
    final isDarkLayout = SharedThemeHelper.isDarkLayout(layoutType);
    final backgroundColor = SharedThemeHelper.getBackgroundColor(layoutType);
    final themePrimary = SharedThemeHelper.getPrimaryColor(layoutType);
    final themeTextColor = SharedThemeHelper.getTextColor(layoutType);
    final themeTextGrey = SharedThemeHelper.getTextGreyColor(layoutType);
    final neumorphicDecoration = SharedThemeHelper.neumorphicDecoration;
    final themeSuccess = SharedThemeHelper.getSuccessColor(layoutType);

    final cardDecoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout03 ? neumorphicDecoration : null);

    // Retorna apenas o conteúdo - PainelPage já fornece Scaffold e AppBar
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isDarkLayout
                ? Container(
                    decoration: cardDecoration,
                    padding: const EdgeInsets.all(16),
                    child: _buildInputContent(context, isLayout03,
                        isDarkLayout: isDarkLayout,
                        themePrimary: themePrimary,
                        themeTextDark: themeTextColor,
                        themeTextGrey: themeTextGrey,
                        neumorphicDecoration: neumorphicDecoration),
                  )
                : (isLayout03
                    ? Container(
                        decoration: neumorphicDecoration,
                        padding: const EdgeInsets.all(16),
                        child: _buildInputContent(context, isLayout03,
                            isDarkLayout: isDarkLayout,
                            themePrimary: themePrimary,
                            themeTextDark: themeTextColor,
                            themeTextGrey: themeTextGrey,
                            neumorphicDecoration: neumorphicDecoration),
                      )
                    : DashboardCard(
                        child: _buildInputContent(context, isLayout03,
                            isDarkLayout: isDarkLayout,
                            themePrimary: themePrimary,
                            themeTextDark: themeTextColor,
                            themeTextGrey: themeTextGrey,
                            neumorphicDecoration: neumorphicDecoration),
                      )),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
              itemCount: _hops.length,
              itemBuilder: (context, index) {
                final hop = _hops[index];
                return _buildHopCard(hop, isLayout03,
                    isDarkLayout: isDarkLayout,
                    themePrimary: themePrimary,
                    themeTextDark: themeTextColor,
                    themeTextGrey: themeTextGrey,
                    themeSuccess: themeSuccess,
                    neumorphicDecoration: neumorphicDecoration);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputContent(BuildContext context, bool isLayout03,
      {bool isDarkLayout = false,
      Color? themePrimary,
      Color? themeTextDark,
      Color? themeTextGrey,
      BoxDecoration? neumorphicDecoration}) {
    final textColor = isDarkLayout
        ? Colors.white
        : (isLayout03 ? themeTextDark : Colors.black87);

    return Column(
      children: [
        TextField(
          controller: _ipController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'IP ou Domínio de Destino',
            labelStyle: TextStyle(
                color: isDarkLayout
                    ? const Color(0xFF8E8E93)
                    : (isLayout03 ? themeTextGrey : null)),
            hintText: 'Ex: 8.8.8.8 ou google.com',
            hintStyle: TextStyle(
                color: isDarkLayout
                    ? const Color(0xFF8E8E93)
                    : (isLayout03 ? themeTextGrey : null)),
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
                color: isDarkLayout
                    ? const Color(0xFF8E8E93)
                    : (isLayout03 ? themeTextGrey : null)),
            filled: isLayout03 || isDarkLayout,
            fillColor: isDarkLayout
                ? const Color(0xFF1C1C1E)
                : (isLayout03 ? Colors.white.withValues(alpha: 0.5) : null),
          ),
          onSubmitted: (_) => _isRunning ? null : _startTraceRoute(),
        ),
        const SizedBox(height: 16),
        Text(_currentStatus,
            style: TextStyle(
                color: _isRunning
                    ? (isDarkLayout
                        ? const Color(0xFF00D9FF)
                        : (isLayout03
                            ? themePrimary
                            : Theme.of(context).primaryColor))
                    : (isDarkLayout
                        ? const Color(0xFF8E8E93)
                        : (isLayout03 ? themeTextGrey : Colors.grey)))),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: isDarkLayout || isLayout03
              ? ElevatedButton.icon(
                  onPressed: () {
                    if (_isRunning) {
                      setState(() => _isRunning = false);
                    } else {
                      _startTraceRoute();
                    }
                  },
                  icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow,
                      color: isDarkLayout ? Colors.black : Colors.white),
                  label: Text(_isRunning ? "Parar" : "Iniciar Rota",
                      style: TextStyle(
                          color: isDarkLayout ? Colors.black : Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkLayout ? const Color(0xFF00D9FF) : themePrimary,
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

  Widget _buildHopCard(
    TraceHop hop,
    bool isLayout03, {
    bool isDarkLayout = false,
    Color? themePrimary,
    Color? themeTextDark,
    Color? themeTextGrey,
    Color? themeSuccess,
    BoxDecoration? neumorphicDecoration,
  }) {
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
    if (isLayout03) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: neumorphicDecoration?.copyWith(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: hop.status == "Alcançado"
                ? themePrimary
                : themeTextGrey?.withValues(alpha: 0.3),
            child: Text("${hop.hop}",
                style: TextStyle(
                    color: hop.status == "Alcançado"
                        ? Colors.white
                        : themeTextDark)),
          ),
          title: Text(hop.ip,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: themeTextDark)),
          subtitle: Text(hop.status, style: TextStyle(color: themeTextGrey)),
          trailing: Text(hop.time,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: themeTextDark)),
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
