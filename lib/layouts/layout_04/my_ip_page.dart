// LAYOUT 04 - AURORA - MY IP PAGE
// Design: Simple IP display with neon effect

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
  String _ipAddress = 'Carregando...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIpAddress();
  }

  Future<void> _loadIpAddress() async {
    setState(() => _isLoading = true);
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() {
              _ipAddress = addr.address;
              _isLoading = false;
            });
            return;
          }
        }
      }
      setState(() {
        _ipAddress = 'Não disponível';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _ipAddress = 'Erro ao obter IP';
        _isLoading = false;
      });
    }
  }

  void _copyIp() {
    Clipboard.setData(ClipboardData(text: _ipAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text('IP copiado!'),
          ],
        ),
        backgroundColor: AuroraColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: ShaderMask(
            shaderCallback: (bounds) =>
                AuroraColors.primaryGradient.createShader(bounds),
            child: const Text('Meu IP',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GlassCard(
              glowColor: AuroraColors.neonCyan,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AuroraColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AuroraColors.neonCyan.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.language,
                        color: Colors.white, size: 50),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Seu endereço IP',
                    style: TextStyle(color: AuroraColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AuroraColors.neonCyan),
                      ),
                    )
                  else
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AuroraColors.primaryGradient.createShader(bounds),
                      child: Text(
                        _ipAddress,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NeonButton(
                        text: 'Copiar',
                        icon: Icons.copy,
                        onPressed: _copyIp,
                      ),
                      const SizedBox(width: 16),
                      NeonButton(
                        text: 'Atualizar',
                        icon: Icons.refresh,
                        isOutlined: true,
                        onPressed: _loadIpAddress,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
