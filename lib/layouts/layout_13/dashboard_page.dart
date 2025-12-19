import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // For ImageFilter

class DashboardPage extends StatelessWidget {
  final String customerName;
  final String planName;
  final String connectionStatus;
  final double billAmount;
  final DateTime billDueDate;
  final double usedGb;
  final double totalGb;
  final double downloadMbps;
  final double uploadMbps;
  final Function(String) onNavigate;
  final List<Map<String, dynamic>>? menuItems;
  final Future<void> Function()? onRefresh;

  const DashboardPage({
    super.key,
    required this.customerName,
    required this.planName,
    required this.connectionStatus,
    required this.billAmount,
    required this.billDueDate,
    required this.usedGb,
    required this.totalGb,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.onNavigate,
    this.menuItems,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Layout 13: Futuristic / Clean / Cyber-Industrial
    // AI Inspiration: "Holographic Overlays", "Neon", "Pill Shapes"

    final primaryColor = const Color(0xFF00FFFF); // Cyan
    final bgGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF050A14), Color(0xFF0A1F30)], // Deep Space
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SYSTEM STATUS",
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.7),
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          connectionStatus.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Color(0xFF00FFFF), blurRadius: 10)
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.hub_outlined, color: primaryColor),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Holographic Card
                      _HoloCard(
                        child: Column(
                          children: [
                            Text(
                              "CURRENT CYCLE",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                letterSpacing: 2,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "R\$ ${billAmount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                                fontFamily:
                                    'Courier', // Monospace for tech feel
                              ),
                            ),
                            const SizedBox(height: 20),
                            _CyberButton(
                              label: "AUTHORIZE PAYMENT",
                              onTap: () => onNavigate('invoices'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Speed Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: CircularProgressIndicator(
                              value: 0.75,
                              strokeWidth: 8,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation(primaryColor),
                            ),
                          ),
                          Column(
                            children: [
                              Icon(Icons.speed, color: primaryColor, size: 30),
                              const SizedBox(height: 5),
                              Text(
                                "${downloadMbps.toInt()}",
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text("MBPS",
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 10)),
                            ],
                          )
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Grid Options
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _CyberTile(
                              icon: Icons.wifi,
                              label: "NETWORK",
                              onTap: () => onNavigate('wifi')),
                          _CyberTile(
                              icon: Icons.support_agent,
                              label: "SUPPORT_LINK",
                              onTap: () => onNavigate('support')),
                          _CyberTile(
                              icon: Icons.history,
                              label: "LOGS",
                              onTap: () => onNavigate('invoices')),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoloCard extends StatelessWidget {
  final Widget child;
  const _HoloCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CyberButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CyberButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF00FFFF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(30), // Pill shape
          border: Border.all(color: const Color(0xFF00FFFF)),
          boxShadow: [
            const BoxShadow(
                color: Color(0xFF00FFFF), blurRadius: 5, spreadRadius: -5),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00FFFF),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CyberTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CyberTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
