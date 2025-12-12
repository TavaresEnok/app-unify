// LAYOUT 04 - AURORA - MY IP PAGE

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'aurora_theme.dart';

class MyIpPage extends StatefulWidget {
  const MyIpPage({super.key});

  @override
  State<MyIpPage> createState() => _MyIpPageState();
}

class _MyIpPageState extends State<MyIpPage> {
  String _ip = 'Carregando...';
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _fetchIp();
  }

  Future<void> _fetchIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() => _ip = addr.address);
            return;
          }
        }
      }
      setState(() => _ip = 'Não encontrado');
    } catch (e) {
      setState(() => _ip = 'Erro ao buscar IP');
    }
  }

  void _copyIp() {
    Clipboard.setData(ClipboardData(text: _ip));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          expandedHeight: 100,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Meu IP',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AuroraCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AuroraColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.public_rounded,
                          color: AuroraColors.primary, size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Seu endereço IP',
                      style: TextStyle(
                          color: AuroraColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ip,
                      style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: AuroraButton(
                        label: _copied ? 'Copiado!' : 'Copiar IP',
                        icon: _copied ? Icons.check : Icons.copy,
                        onPressed: _copyIp,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AuroraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Sobre o IP',
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'O endereço IP é um identificador único que permite que seu dispositivo se comunique com outros na internet. Ele é atribuído pelo seu provedor de internet.',
                      style: TextStyle(
                          color: AuroraColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
