import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure google_fonts is in pubspec
import 'package:fl_chart/fl_chart.dart'; // Ensure fl_chart is in pubspec

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
    // Theme Constants
    const kBgColor = Color(0xFF050505); // Deep Matte Black
    const kCardStart = Color(0xFF1A1A1A);
    const kGold = Color(0xFFD4AF37); // Metallic Gold
    const kTextGrey = Color(0xFF888888);

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: kGold,
          backgroundColor: kCardStart,
          onRefresh: () async {
            if (onRefresh != null) await onRefresh!();
          },
          child: CustomScrollView(
            slivers: [
              // 1. Elegant AppBar / Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "BEM-VINDO",
                            style: GoogleFonts.inter(
                              color: kGold,
                              fontSize: 10,
                              letterSpacing: 3.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customerName.toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: kGold.withOpacity(0.5), width: 1),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.transparent,
                          child: Icon(Icons.person_outline, color: kGold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Hero Card (Invoice)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _GoldBorderCard(
                    height: 240,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "FATURA ATUAL",
                          style: GoogleFonts.inter(
                            color: kTextGrey,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "R\$ ${billAmount.toStringAsFixed(2).replaceAll('.', ',')}",
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.green.withOpacity(0.1),
                          ),
                          child: Text(
                            "VENCIMENTO ${billDueDate.day}/${billDueDate.month}",
                            style: GoogleFonts.inter(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => onNavigate('invoices'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(4)), // Sharpish
                              elevation: 0,
                            ),
                            child: Text(
                              "PAGAR AGORA",
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // 3. Status & Plan (Grid)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    // Speed Card
                    _GoldBorderCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.speed, color: kGold.withOpacity(0.8)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${downloadMbps.toInt()}",
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "MEGAS",
                                style: GoogleFonts.inter(
                                  color: kTextGrey,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      onTap: () => onNavigate('speed_test'),
                    ),

                    // Connection Status
                    _GoldBorderCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.wifi, color: kGold.withOpacity(0.8)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                connectionStatus.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color:
                                      connectionStatus.toLowerCase() == 'ativo'
                                          ? Colors.white
                                          : Colors.redAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "STATUS",
                                style: GoogleFonts.inter(
                                  color: kTextGrey,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      onTap: () => onNavigate('wifi'), // Or related action
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // 4. Usage Chart (Aesthetic only for now)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text("CONSUMO DE DADOS",
                              style: GoogleFonts.inter(
                                  color: kGold,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold)),
                          Expanded(
                              child: Container(
                                  height: 1,
                                  margin: const EdgeInsets.only(left: 10),
                                  color: kGold.withOpacity(0.2))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            maxY: 6,
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [
                                  FlSpot(0, 3),
                                  FlSpot(1, 1),
                                  FlSpot(2, 4),
                                  FlSpot(3, 2),
                                  FlSpot(4, 5),
                                  FlSpot(5, 3),
                                  FlSpot(6, 4),
                                ],
                                isCurved: true,
                                color: kGold,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: kGold.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Custom Components for Layout 14 ---

class _GoldBorderCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final VoidCallback? onTap;

  const _GoldBorderCard({required this.child, this.height, this.onTap});

  @override
  Widget build(BuildContext context) {
    const kGold = Color(0xFFD4AF37);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Subtle Gold Gradient Border
          border: Border.all(color: kGold.withOpacity(0.3), width: 1),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF0A0A0A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: kGold.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}
