import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app_provedor_unified/layouts/layout_13/widgets/cyber_card.dart';

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
    // Cyber Palette
    const bgColor = Color(0xFF050505);
    const accentColor = Color(0xFF00FFFF); // Cyan
    const secondaryAccent = Color(0xFFFF00FF); // Magenta

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          backgroundColor: Colors.black,
          onRefresh: onRefresh ?? () async {},
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(accentColor),
                const SizedBox(height: 30),
                _buildStatusTerminal(accentColor, secondaryAccent),
                const SizedBox(height: 30),
                _buildActionGrid(accentColor),
                const SizedBox(height: 30),
                _buildInvoiceSection(accentColor),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '// WELCOME_USER',
              style: GoogleFonts.robotoMono(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              customerName.toUpperCase(),
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: accent.withValues(alpha: 0.2),
              child: Text(
                'PLAN: ${planName.toUpperCase()}',
                style: GoogleFonts.robotoMono(
                  color: accent,
                  fontSize: 10,
                ),
              ),
            )
          ],
        ),
        IconButton(
          onPressed: () => onNavigate('/notifications'),
          icon: Icon(Icons.notifications, color: accent),
        )
      ],
    );
  }

  Widget _buildStatusTerminal(Color accent, Color secondary) {
    final isOnline = connectionStatus.toLowerCase() == 'online';

    return CyberCard(
      borderColor: isOnline ? accent : Colors.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SYSTEM_STATUS',
                style: GoogleFonts.robotoMono(color: Colors.grey, fontSize: 10),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: isOnline ? accent : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: isOnline ? accent : Colors.red, blurRadius: 10)
                    ]),
              )
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(
                  'DLL', downloadMbps.toInt().toString(), 'MBPS', accent),
              Container(width: 1, height: 30, color: Colors.grey[800]),
              _buildMetric(
                  'UPL', uploadMbps.toInt().toString(), 'MBPS', secondary),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'DATA_USAGE: < ${usedGb.toInt()} / ${totalGb.toInt()} GB >',
            style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: (usedGb / totalGb).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[900],
            color: accent,
            minHeight: 2,
          )
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.robotoMono(color: color, fontSize: 10)),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(unit,
            style: GoogleFonts.robotoMono(color: Colors.grey, fontSize: 8)),
      ],
    );
  }

  Widget _buildActionGrid(Color accent) {
    final actions = [
      {
        'icon': FontAwesomeIcons.barcode,
        'label': 'INVOICES',
        'route': '/financeiro'
      },
      {
        'icon': FontAwesomeIcons.headset,
        'label': 'SUPPORT',
        'route': '/suporte'
      },
      {
        'icon': FontAwesomeIcons.gaugeHigh,
        'label': 'SPEED_TEST',
        'route': '/speedtest'
      },
      {'icon': FontAwesomeIcons.wifi, 'label': 'CONFIG_WIFI', 'route': '/wifi'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.6,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return CyberCard(
          onTap: () => onNavigate(action['route'] as String),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(action['icon'] as IconData, color: accent, size: 24),
              const SizedBox(height: 10),
              Text(
                action['label'] as String,
                style:
                    GoogleFonts.robotoMono(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceSection(Color accent) {
    return CyberCard(
      borderColor: Colors.yellow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PENDING_PAYMENT',
                  style: GoogleFonts.robotoMono(
                      color: Colors.yellow, fontSize: 10)),
              const SizedBox(height: 5),
              Text(
                'R\$ ${billAmount.toStringAsFixed(2)}',
                style: GoogleFonts.robotoMono(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                'DUE: ${_formatDate(billDueDate)}',
                style: GoogleFonts.robotoMono(color: Colors.red, fontSize: 10),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => onNavigate('/financeiro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              side: const BorderSide(color: Colors.yellow),
              shape:
                  const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text('PAY_NOW >>',
                style: GoogleFonts.robotoMono(color: Colors.yellow)),
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}";
  }
}
