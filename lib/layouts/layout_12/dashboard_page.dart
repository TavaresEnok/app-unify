import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app_provedor_unified/layouts/layout_12/widgets/glass_card.dart';

class DashboardPage extends StatefulWidget {
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
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Neuroform Gradient Palette
    const color1 = Color(0xFF0F172A); // Deep Slate
    const color2 = Color(0xFF1E1B4B); // Indigo
    const color3 = Color(0xFF0F766E); // Teal

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fluid Background
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(color1, color2, _animController.value)!,
                      Color.lerp(color2, color3, _animController.value)!,
                      Color.lerp(color3, color1, _animController.value)!,
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Main Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh ?? () async {},
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildConnectionStatus(),
                    const SizedBox(height: 20),
                    _buildUsageCard(),
                    const SizedBox(height: 20),
                    _buildActionGrid(),
                    const SizedBox(height: 20),
                    _buildBillCard(),
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
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
            Text(
              'Olá, ${widget.customerName.split(' ')[0]}',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Plano ${widget.planName}',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        CircleAvatar(
          backgroundColor: Colors.white24,
          child: IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () => widget.onNavigate('/notifications'),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    final isOnline = widget.connectionStatus.toLowerCase() == 'online';
    return GlassCard(
      opacity: 0.15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSpeedItem(
              'Download', widget.downloadMbps, Icons.download, Colors.cyan),
          Container(height: 40, width: 1, color: Colors.white24),
          _buildSpeedItem(
              'Upload', widget.uploadMbps, Icons.upload, Colors.purpleAccent),
          Container(height: 40, width: 1, color: Colors.white24),
          Column(
            children: [
              Icon(
                isOnline ? Icons.check_circle : Icons.error,
                color: isOnline ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(height: 4),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSpeedItem(
      String label, double value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          '${value.toInt()} Mbps',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildUsageCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Consumo de Dados',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
              Text('${widget.usedGb.toInt()} / ${widget.totalGb.toInt()} GB',
                  style: GoogleFonts.outfit(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 15),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (widget.usedGb / widget.totalGb).clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.cyan, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.5),
                        blurRadius: 10,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      {
        'icon': FontAwesomeIcons.barcode,
        'label': '2ª Via',
        'route': '/financeiro'
      },
      {
        'icon': FontAwesomeIcons.headset,
        'label': 'Suporte',
        'route': '/suporte'
      },
      {
        'icon': FontAwesomeIcons.gaugeHigh,
        'label': 'Velocidade',
        'route': '/speedtest'
      },
      {'icon': FontAwesomeIcons.wifi, 'label': 'Meu Wi-Fi', 'route': '/wifi'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: () => widget.onNavigate(action['route'] as String),
          child: GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(action['icon'] as IconData,
                    color: Colors.white, size: 28),
                const SizedBox(height: 10),
                Text(
                  action['label'] as String,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBillCard() {
    return GlassCard(
      opacity: 0.1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fatura Atual',
                  style: GoogleFonts.outfit(color: Colors.white70)),
              Text('R\$ ${widget.billAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              Text('Vence em ${_formatDate(widget.billDueDate)}',
                  style: GoogleFonts.outfit(
                      color: Colors.redAccent, fontSize: 12)),
            ],
          ),
          ElevatedButton(
            onPressed: () => widget.onNavigate('/financeiro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child:
                Text('Pagar', style: GoogleFonts.outfit(color: Colors.white)),
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
  }
}
