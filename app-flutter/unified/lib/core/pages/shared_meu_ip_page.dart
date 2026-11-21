import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/meu_ip_service.dart';
import '../widgets/customer_ui.dart';

class MeuIpPage extends StatefulWidget {
  const MeuIpPage({super.key});

  @override
  State<MeuIpPage> createState() => _MeuIpPageState();
}

class _MeuIpPageState extends State<MeuIpPage> {
  final _service = MeuIpService();
  late Future<Map<String, dynamic>> _ipFuture;

  @override
  void initState() {
    super.initState();
    _ipFuture = _service.fetchIpInfo();
  }

  void _retry() => setState(() => _ipFuture = _service.fetchIpInfo());

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _ipFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return CustomerList(children: [
              CustomerCard(
                  child: Column(children: [
                const Icon(Icons.public_off_outlined, size: 42),
                const SizedBox(height: 12),
                const Text('Não foi possível consultar seu IP público.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente')),
              ])),
            ]);
          }
          final data = snapshot.data!;
          final ip = data['ip']?.toString() ?? '';
          final location = [data['city'], data['region']]
              .where(
                  (part) => part != null && part.toString().trim().isNotEmpty)
              .join(', ');
          final rows = <String, String>{
            'Localização aproximada': location,
            'País': data['country']?.toString() ?? '',
            'Provedor': data['org']?.toString() ?? '',
            'Fuso horário': data['timezone']?.toString() ?? '',
          };
          return CustomerList(children: [
            CustomerCard(
                child: Column(children: [
              const Text('IP público'),
              const SizedBox(height: 10),
              SelectableText(ip.isEmpty ? 'Não informado' : ip,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (ip.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: ip));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('IP copiado.')));
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar IP'),
                ),
            ])),
            const SizedBox(height: 16),
            CustomerCard(
                child: Column(children: [
              for (final row in rows.entries)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(row.key)),
                          Expanded(
                              child: Text(
                                  row.value.isEmpty
                                      ? 'Não informado'
                                      : row.value,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                        ])),
            ])),
            const SizedBox(height: 16),
            OutlinedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar')),
          ]);
        },
      );
}
