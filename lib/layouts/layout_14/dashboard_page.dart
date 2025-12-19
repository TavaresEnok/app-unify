import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProviderDashboardPage extends StatelessWidget {
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

  const ProviderDashboardPage({
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
    // Layout 14: Dark Premium / Luxury
    // AI Inspiration: "Carbon Fiber", "Gold Accents", "Sophisticated Cards"

    return Scaffold(
      backgroundColor: const Color(0xFF101010), // Matte Black
      body: SafeArea(
        child: Column(
          children: [
            // Elegant Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF333333))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFD4AF37), // Gold
                        radius: 20,
                        child: Text(
                          customerName.isNotEmpty ? customerName[0] : "C",
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SEJA BEM-VINDO",
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            customerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Playfair Display', // Elegant serif
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Color(0xFFD4AF37)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Premium Card (Golden Gradient)
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2C2C2C),
                            Color(0xFF000000),
                          ],
                        ),
                        border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.wb_sunny_outlined,
                                  color: Color(0xFFD4AF37)),
                              Text(
                                "FATURA MENSAL",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  letterSpacing: 2,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "R\$ ${billAmount.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'Playfair Display',
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => onNavigate('invoices'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFD4AF37),
                                side:
                                    const BorderSide(color: Color(0xFFD4AF37)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text("VISUALIZAR DETALHES"),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Status Section
                    Row(
                      children: [
                        Expanded(
                          child: _PremiumStatusCard(
                            label: "VELOCIDADE",
                            value: "${downloadMbps.toInt()} MB",
                            icon: Icons.speed,
                            onTap: () => onNavigate('speed_test'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _PremiumStatusCard(
                            label: "STATUS",
                            value: connectionStatus,
                            icon: Icons.wifi,
                            isActive: connectionStatus.toLowerCase() == 'ativo',
                            onTap: () => onNavigate('wifi'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Additional Options List (Minimalist List Tiles)
                    _PremiumListTile(
                      icon: Icons.support,
                      title: "Atendimento Exclusive",
                      onTap: () => onNavigate('support'),
                    ),
                    _PremiumListTile(
                      icon: Icons.settings,
                      title: "Configurações",
                      onTap: () {}, // TODO
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumStatusCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool? isActive;
  final VoidCallback onTap;

  const _PremiumStatusCard({
    required this.label,
    required this.value,
    required this.icon,
    this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: isActive == true
                        ? Colors.green
                        : (isActive == false ? Colors.red : Colors.white),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PremiumListTile(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFFD4AF37)),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
    );
  }
}
