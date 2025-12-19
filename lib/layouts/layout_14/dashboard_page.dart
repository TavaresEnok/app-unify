import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app_provedor_unified/layouts/layout_14/widgets/gold_widgets.dart';

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
    // Velvet Gold Palette
    const bgColor = Color(0xFF101010);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFBF953F),
          backgroundColor: Colors.black,
          onRefresh: onRefresh ?? () async {},
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildStatusCard(),
                const SizedBox(height: 30),
                _buildActionGrid(),
                const SizedBox(height: 30),
                _buildInvoiceCard(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoldGradientText(
              child: Text(
                'Bem-vindo,',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              customerName,
              style: GoogleFonts.cinzel(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 5),
            Text(
              planName.toUpperCase(),
              style: GoogleFonts.lato(
                  fontSize: 12, color: Colors.white38, letterSpacing: 2),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color(0xFFBF953F), Color(0xFFFCF6BA)])),
          child: CircleAvatar(
            backgroundColor: Colors.black,
            child: IconButton(
              icon: const Icon(Icons.notifications_none,
                  color: Color(0xFFBF953F)),
              onPressed: () => onNavigate('/notifications'),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildStatusCard() {
    final isOnline = connectionStatus.toLowerCase() == 'online';

    return VelvetCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STATUS DA CONEXÃO',
                  style: GoogleFonts.lato(
                      color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
              Icon(
                Icons.circle,
                size: 10,
                color: isOnline ? const Color(0xFFBF953F) : Colors.red,
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('DOWNLOAD', downloadMbps.toInt().toString()),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildMetric('UPLOAD', uploadMbps.toInt().toString()),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        _buildGoldIcon(Icons.speed, size: 20),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.cinzel(
              fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: GoogleFonts.lato(color: Colors.white38, fontSize: 10),
        )
      ],
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      {
        'icon': FontAwesomeIcons.fileInvoiceDollar,
        'label': 'Faturas',
        'route': '/financeiro'
      },
      {
        'icon': FontAwesomeIcons.headset,
        'label': 'Suporte',
        'route': '/suporte'
      },
      {
        'icon': FontAwesomeIcons.gauge,
        'label': 'Velocidade',
        'route': '/speedtest'
      },
      {'icon': FontAwesomeIcons.wifi, 'label': 'Wi-Fi', 'route': '/wifi'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.4,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return VelvetCard(
          onTap: () => onNavigate(action['route'] as String),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GoldGradientText(
                  child: FaIcon(action['icon'] as IconData,
                      color: Colors.white, size: 28)),
              const SizedBox(height: 15),
              Text(
                action['label'] as String,
                style: GoogleFonts.cinzel(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceCard() {
    return VelvetCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FATURA ABERTA',
                  style: GoogleFonts.lato(
                      color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 5),
              GoldGradientText(
                child: Text(
                  'R\$ ${billAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.cinzel(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              Text('Vencimento: ${_formatDate(billDueDate)}',
                  style: GoogleFonts.lato(color: Colors.white54, fontSize: 12)),
            ],
          ),
          ElevatedButton(
            onPressed: () => onNavigate('/financeiro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBF953F),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('PAGAR'),
          )
        ],
      ),
    );
  }

  Widget _buildGoldIcon(IconData icon, {double size = 24}) {
    return GoldGradientText(child: Icon(icon, size: size, color: Colors.white));
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
  }
}
