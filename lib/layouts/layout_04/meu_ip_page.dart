import 'package:flutter/material.dart';
import '../../core/services/meu_ip_service.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class MeuIpPage extends StatefulWidget {
  const MeuIpPage({super.key});

  @override
  State<MeuIpPage> createState() => _MeuIpPageState();
}

class _MeuIpPageState extends State<MeuIpPage> {
  final _service = MeuIpService();
  Map<String, dynamic>? _ipData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    try {
      final data = await _service.fetchIpInfo();
      if (mounted) {
        setState(() {
          _ipData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout04Theme.background,
      appBar: AppBar(
        title: Text('Meu IP', style: Layout04Theme.heading3),
        backgroundColor: Layout04Theme.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _InfoCard(
                    label: 'Endereço IP',
                    value: _ipData?['ip'] ?? 'Indisponível',
                    icon: Icons.public,
                    isCopyable: true,
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    label: 'Provedor',
                    value: _ipData?['isp'] ?? 'Indisponível',
                    icon: Icons.dns_rounded,
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    label: 'Localização',
                    value: _ipData?['city'] ?? 'Indisponível',
                    icon: Icons.location_on_rounded,
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isCopyable;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    this.isCopyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Layout04Theme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Layout04Theme.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Layout04Theme.textPrimary, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Layout04Theme.bodySmall),
                const SizedBox(height: 4),
                Text(value,
                    style: Layout04Theme.heading3.copyWith(fontSize: 16)),
              ],
            ),
          ),
          if (isCopyable)
            IconButton(
              icon: Icon(Icons.copy_rounded, color: Layout04Theme.accent),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Copiado para a área de transferência')),
                );
              },
            ),
        ],
      ),
    );
  }
}
