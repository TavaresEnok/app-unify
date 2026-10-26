import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
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

  /// Executa o traceroute NO SERVIDOR.
  ///
  /// A implementação anterior chamava `Process.run('ping', ...)` no aparelho:
  /// isso não funciona no iOS (sem acesso a binários) e é pouco confiável no
  /// Android moderno. O backend já expõe `/diagnostic/traceroute` com validação
  /// de destino (bloqueia faixas internas) — usamos a mesma rota do diagnóstico
  /// completo, garantindo resultado consistente entre as duas telas.
  Future<void> _startTraceRoute() async {
    final target = _ipController.text.trim();
    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite um IP ou Domínio.')),
      );
      return;
    }

    final config = ref.read(configurationProvider).providerConfig;
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuração indisponível. Tente novamente.')),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _hops.clear();
      _currentStatus = "Rastreando rota até $target...";
    });

    FocusScope.of(context).unfocus();

    try {
      final apiUri = Uri.parse(config.apiUrl);
      final baseUrl = '${apiUri.scheme}://${apiUri.host}:${apiUri.port}';
      String? token;
      try {
        token = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (_) {}

      final response = await http
          .post(
            Uri.parse('$baseUrl/diagnostic/traceroute'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode({'target': target, 'maxHops': 15}),
          )
          .timeout(const Duration(seconds: 40));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _isRunning = false;
          _currentStatus = response.statusCode == 400
              ? 'Destino inválido ou não permitido.'
              : 'Não foi possível rastrear a rota agora.';
        });
        return;
      }

      final data = json.decode(response.body);
      final hopsData = data['data']?['hops'] as List<dynamic>? ?? const [];

      setState(() {
        for (final hop in hopsData) {
          final ip = (hop['ip'] ?? '*').toString();
          _hops.add(TraceHop(
            hop: hop['hop'] is int ? hop['hop'] as int : _hops.length + 1,
            ip: ip,
            time: (hop['time'] ?? '*').toString(),
            status: ip == '*' ? 'Sem resposta' : 'Salto',
          ));
        }
        if (_hops.isNotEmpty) {
          _hops.last = TraceHop(
            hop: _hops.last.hop,
            ip: _hops.last.ip,
            time: _hops.last.time,
            status: 'Alcançado',
          );
        }
        _isRunning = false;
        _currentStatus = _hops.isEmpty
            ? 'Nenhum salto retornado.'
            : 'Rota concluída em ${_hops.length} salto(s).';
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _currentStatus = 'O rastreamento demorou demais e foi interrompido.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _currentStatus = 'Falha ao rastrear a rota. Verifique sua conexão.';
      });
    }
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
