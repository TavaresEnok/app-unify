part of '../diagnostic_03_page.dart';

// ═══════════════════════════════════════════════════════════════
// ENUMS & MODELS
// ═══════════════════════════════════════════════════════════════

enum DiagStep { ready, wifi, onu, lan, speed, trace, done }

class StepMeta {
  final String name, desc;
  final IconData icon;
  final Color color;
  const StepMeta(this.name, this.desc, this.icon, this.color);
}

final stepMeta = {
  DiagStep.ready: const StepMeta("Iniciar", "Toque para começar",
      Icons.power_settings_new, Color(0xFF00F5FF)),
  DiagStep.wifi: const StepMeta(
      "Wi-Fi", "Analisando conexão", Icons.wifi, Color(0xFF00F5FF)),
  DiagStep.onu: const StepMeta(
      "Fibra", "Lendo sinal óptico", Icons.router, Color(0xFF8B5CF6)),
  DiagStep.lan: const StepMeta(
      "Rede", "Escaneando dispositivos", Icons.devices, Color(0xFFEC4899)),
  DiagStep.speed: const StepMeta(
      "Velocidade", "Medindo vazão", Icons.speed, Color(0xFF10B981)),
  DiagStep.trace: const StepMeta(
      "Rota", "Traçando caminho", Icons.route, Color(0xFFF59E0B)),
  DiagStep.done: const StepMeta(
      "Concluído", "Diagnóstico finalizado", Icons.verified, Color(0xFF00FF88)),
};

class WifiData {
  final String ssid;
  final int rssi;
  final String freq, gateway;
  WifiData(
      {required this.ssid,
      required this.rssi,
      required this.freq,
      required this.gateway});
}

class OnuData {
  final double rx, tx, temp;
  final String status;
  OnuData(
      {required this.rx,
      required this.tx,
      required this.temp,
      required this.status});
}

class DeviceData {
  final String ip, name, mac;
  DeviceData(this.ip, this.name, this.mac);
}

class SpeedData {
  final double down, up, ping, jitter;
  SpeedData(
      {required this.down,
      required this.up,
      required this.ping,
      required this.jitter});
}

class HopData {
  final int n;
  final String ip;
  final double ms;
  HopData(this.n, this.ip, this.ms);
}

// ═══════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════
