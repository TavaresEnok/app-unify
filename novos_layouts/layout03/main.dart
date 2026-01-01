import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NetConnectApp());
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 TRUE NEUMORPHISM - As per all AI feedback
// ═══════════════════════════════════════════════════════════════════════════

// THE BASE COLOR - Everything uses this EXACT color
const Color neuBase = Color(0xFFE0E5EC);

// THE SHADOWS - The heart of neumorphism
const Color neuShadowDark = Color(0xFFA3B1C6); // Darker shade for depth
const Color neuShadowLight = Color(0xFFFFFFFF); // White for light highlight

// TEXT - Soft grays, never pure black
const Color neuTextDark = Color(0xFF4A5568);
const Color neuTextMedium = Color(0xFF718096);
const Color neuTextLight = Color(0xFFA0AEC0);

// ACCENT - Only for small details (icons, chips)
const Color neuAccent = Color(0xFF6B7FD7);
const Color neuSuccess = Color(0xFF68D391);
const Color neuWarning = Color(0xFFECC94B);

// COLD COLORS for feature icons (desaturated, muted)
const Color iconBlue = Color(0xFF7B9DBF); // Soft steel blue
const Color iconTeal = Color(0xFF6BA8A0); // Muted teal
const Color iconSlate = Color(0xFF8B9DC3); // Slate blue
const Color iconSage = Color(0xFF8DAA9D); // Sage green
const Color iconMauve = Color(0xFF9B8FA8); // Soft mauve
const Color iconStorm = Color(0xFF7C8DA0); // Storm gray
const Color iconMist = Color(0xFF9CAFB7); // Misty blue
const Color iconDusk = Color(0xFF8A97AA); // Dusk blue
const Color iconFog = Color(0xFF94A3B8); // Fog gray

// ═══════════════════════════════════════════════════════════════════════════
// CONVEX SHADOW - Element rises FROM the surface
// ═══════════════════════════════════════════════════════════════════════════
List<BoxShadow> neuConvex({
  double distance = 8,
  double blur = 15,
  double spread = 1,
}) {
  return [
    // Dark shadow - bottom right (depth)
    BoxShadow(
      color: neuShadowDark,
      offset: Offset(distance, distance),
      blurRadius: blur,
      spreadRadius: spread,
    ),
    // Light shadow - top left (light)
    BoxShadow(
      color: neuShadowLight,
      offset: Offset(-distance, -distance),
      blurRadius: blur,
      spreadRadius: spread,
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// CONCAVE SHADOW - Element sinks INTO the surface (inset)
// ═══════════════════════════════════════════════════════════════════════════
List<BoxShadow> neuConcave({
  double distance = 6,
  double blur = 12,
  double spread = 1,
}) {
  return [
    // Inset dark shadow
    BoxShadow(
      color: neuShadowDark.withOpacity(0.5),
      offset: Offset(distance, distance),
      blurRadius: blur,
      spreadRadius: -spread,
    ),
    // Inset light shadow
    BoxShadow(
      color: neuShadowLight.withOpacity(0.7),
      offset: Offset(-distance, -distance),
      blurRadius: blur,
      spreadRadius: -spread,
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// FLAT SHADOW - Subtle, for smaller elements
// ═══════════════════════════════════════════════════════════════════════════
List<BoxShadow> neuFlat({double distance = 4, double blur = 8}) {
  return [
    BoxShadow(
      color: neuShadowDark.withOpacity(0.6),
      offset: Offset(distance, distance),
      blurRadius: blur,
    ),
    BoxShadow(
      color: neuShadowLight,
      offset: Offset(-distance, -distance),
      blurRadius: blur,
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// PRESSED SHADOW - For active/pressed state
// ═══════════════════════════════════════════════════════════════════════════
List<BoxShadow> neuPressed({double distance = 3, double blur = 6}) {
  return [
    BoxShadow(
      color: neuShadowDark.withOpacity(0.4),
      offset: Offset(distance, distance),
      blurRadius: blur,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: neuShadowLight.withOpacity(0.6),
      offset: Offset(-distance, -distance),
      blurRadius: blur,
      spreadRadius: -2,
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// App
// ═══════════════════════════════════════════════════════════════════════════

class NetConnectApp extends StatelessWidget {
  const NetConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: neuBase),
      home: const HomeScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Home Screen
// ═══════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  bool _expanded = false;
  int _bannerPage = 0;
  late PageController _bannerCtrl;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _features = [
    {'label': 'Velocidade', 'icon': Icons.speed_rounded, 'color': iconBlue},
    {'label': 'Diagnóstico', 'icon': Icons.healing_rounded, 'color': iconTeal},
    {'label': 'Traceroute', 'icon': Icons.route_rounded, 'color': iconSlate},
    {
      'label': 'Contrato',
      'icon': Icons.description_rounded,
      'color': iconMauve,
    },
    {'label': 'Consumo', 'icon': Icons.pie_chart_rounded, 'color': iconSage},
    {'label': 'Meu IP', 'icon': Icons.public_rounded, 'color': iconStorm},
    {'label': 'FAQ', 'icon': Icons.help_outline_rounded, 'color': iconMist},
    {'label': 'Faturas', 'icon': Icons.receipt_long_rounded, 'color': iconDusk},
    {'label': 'Suporte', 'icon': Icons.headset_mic_rounded, 'color': iconFog},
  ];

  @override
  void initState() {
    super.initState();
    _bannerCtrl = PageController();
    _autoScroll();
  }

  void _autoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _bannerCtrl.hasClients) {
        _bannerCtrl.animateToPage(
          (_bannerPage + 1) % 2,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _autoScroll();
      }
    });
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: neuBase,
      drawer: _drawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: 20),
                    _connectionCard(),
                    const SizedBox(height: 18),
                    _promoBanner(),
                    const SizedBox(height: 22),
                    _featuresSection(),
                    const SizedBox(height: 22),
                    _invoicesSection(),
                  ],
                ),
              ),
            ),
            _navbar(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Header - Pure neumorphic buttons
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Menu button - neumorphic
            _NeuButton(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: const Icon(
                Icons.menu_rounded,
                color: neuTextMedium,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'NetConnect',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: neuTextDark,
                  ),
                ),
                Text(
                  'Olá, João! 👋',
                  style: TextStyle(fontSize: 13, color: neuTextMedium),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _NeuButton(
              onTap: () {},
              child: const Icon(
                Icons.notifications_none_rounded,
                color: neuTextMedium,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            _NeuButton(
              onTap: () {},
              child: const Icon(
                Icons.person_outline_rounded,
                color: neuAccent,
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Connection Card - True neumorphic card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _connectionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: neuBase, // SAME color as background!
        borderRadius: BorderRadius.circular(24),
        boxShadow: neuConvex(distance: 10, blur: 20),
      ),
      child: Row(
        children: [
          // Status indicator - CONCAVE (sunken)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: neuBase, // SAME color!
              shape: BoxShape.circle,
              boxShadow: neuConcave(distance: 5, blur: 10),
            ),
            child: const Icon(Icons.wifi_rounded, color: neuSuccess, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: neuSuccess,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Conectado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: neuSuccess,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Plano Ultra • Fibra 500Mbps',
                  style: TextStyle(fontSize: 12, color: neuTextMedium),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '245.8',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: neuTextDark,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      ' Mbps',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: neuTextMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(
                    Icons.signal_cellular_alt_rounded,
                    size: 12,
                    color: neuSuccess,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '12ms',
                    style: TextStyle(fontSize: 11, color: neuTextMedium),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Promo Banner - Neumorphic style (NO gradients on surface!)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _promoBanner() {
    return Column(
      children: [
        // Container afundado usando Stack
        Stack(
          children: [
            // Fundo com sombra invertida (afundado)
            Container(
              height: 155,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: neuBase,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: neuShadowDark.withOpacity(0.25),
                  width: 1,
                ),
                boxShadow: [
                  // Sombra escura dentro (topo-esquerda)
                  BoxShadow(
                    color: neuShadowDark.withOpacity(0.5),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                    spreadRadius: -4,
                  ),
                  // Sombra clara dentro (fundo-direita)
                  BoxShadow(
                    color: neuShadowLight,
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                    spreadRadius: -4,
                  ),
                ],
              ),
            ),
            // PageView com padding
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: PageView(
                    controller: _bannerCtrl,
                    onPageChanged: (i) => setState(() => _bannerPage = i),
                    children: [_bannerUpgrade(), _bannerSupport()],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (i) {
            final active = _bannerPage == i;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? neuAccent : neuShadowDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _bannerUpgrade() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.35),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '🔥 Oferta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Upgrade para 1 Gbps',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Por apenas + R\$ 30/mês',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  size: 26,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerSupport() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38B2AC), Color(0xFF4FD1C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38B2AC).withOpacity(0.35),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '⚡ 24/7',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Suporte Técnico',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Equipe sempre disponível',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  size: 26,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Features - Horizontal slider with neumorphic tiles
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _featuresSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Acesso Rápido',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: neuTextDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _expanded = !_expanded);
              },
              child: Row(
                children: [
                  Text(
                    _expanded ? 'Menos' : 'Ver todos',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: neuAccent,
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: neuAccent,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: SizedBox(
            height: 95,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _features.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, i) => _FeatureTile(
                label: _features[i]['label'] as String,
                icon: _features[i]['icon'] as IconData,
                color: _features[i]['color'] as Color,
              ),
            ),
          ),
          secondChild: Wrap(
            spacing: 16,
            runSpacing: 18,
            children: _features
                .map(
                  (f) => _FeatureTile(
                    label: f['label'] as String,
                    icon: f['icon'] as IconData,
                    color: f['color'] as Color,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Invoices - Neumorphic cards
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _invoicesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Faturas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: neuTextDark,
              ),
            ),
            Text(
              'Ver todas',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: neuAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _invoiceCard(
                'Dez 2024',
                'R\$ 129,90',
                '10/12',
                'Pendente',
                neuWarning,
                isPending: true,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _invoiceCard(
                'Nov 2024',
                'R\$ 129,90',
                '10/11',
                'Pago',
                neuSuccess,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _invoiceCard(
    String month,
    String value,
    String due,
    String status,
    Color statusColor, {
    bool isPending = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: neuBase,
        borderRadius: BorderRadius.circular(18),
        boxShadow: neuConvex(distance: 5, blur: 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: neuBase,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: neuConcave(distance: 2, blur: 5),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  size: 18,
                  color: statusColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            month,
            style: const TextStyle(fontSize: 10, color: neuTextMedium),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: neuTextDark,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_rounded,
                    size: 10,
                    color: neuTextLight,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Venc: $due',
                    style: const TextStyle(fontSize: 9, color: neuTextLight),
                  ),
                ],
              ),
              if (isPending)
                GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pagar',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Navbar - Pure neumorphic
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _navbar() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.speed_rounded, 'label': 'Speed'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Faturas'},
      {'icon': Icons.headset_mic_rounded, 'label': 'Suporte'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: neuBase,
        boxShadow: [
          BoxShadow(
            color: neuShadowDark.withOpacity(0.2),
            offset: const Offset(0, -6),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final selected = _navIndex == i;

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _navIndex = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: neuBase,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: selected ? neuFlat(distance: 4, blur: 8) : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 22,
                      color: selected ? neuAccent : neuTextLight,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selected ? neuAccent : neuTextLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Drawer - Pure neumorphic
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _drawer() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Início', 'selected': true},
      {'icon': Icons.speed_rounded, 'label': 'Velocidade'},
      {'icon': Icons.healing_rounded, 'label': 'Diagnóstico'},
      {'icon': Icons.route_rounded, 'label': 'Traceroute'},
      {'icon': Icons.pie_chart_rounded, 'label': 'Consumo'},
      {'icon': Icons.public_rounded, 'label': 'Meu IP'},
      {'icon': Icons.description_rounded, 'label': 'Contrato'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Faturas'},
      {'icon': Icons.help_outline_rounded, 'label': 'FAQ'},
      {'icon': Icons.headset_mic_rounded, 'label': 'Suporte'},
    ];

    return Drawer(
      backgroundColor: neuBase,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: neuBase,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: neuConvex(distance: 5, blur: 10),
                    ),
                    child: const Icon(
                      Icons.wifi_rounded,
                      color: neuAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'NetConnect',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: neuTextDark,
                        ),
                      ),
                      Text(
                        'Sua internet premium',
                        style: TextStyle(fontSize: 12, color: neuTextMedium),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final selected = item['selected'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: neuBase,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: selected
                          ? neuFlat(distance: 4, blur: 8)
                          : null,
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: selected ? neuAccent : neuTextMedium,
                        size: 22,
                      ),
                      title: Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: selected ? neuAccent : neuTextDark,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => Navigator.pop(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Neumorphic Button Widget - Real press effect
// ═══════════════════════════════════════════════════════════════════════════

class _NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _NeuButton({required this.child, required this.onTap});

  @override
  State<_NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<_NeuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: neuBase, // SAME color!
          borderRadius: BorderRadius.circular(14),
          boxShadow: _pressed ? neuPressed() : neuFlat(),
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Feature Tile Widget - True neumorphic style
// ═══════════════════════════════════════════════════════════════════════════

class _FeatureTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _FeatureTile({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: 75,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: neuBase,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _pressed
                    ? neuPressed()
                    : neuFlat(distance: 5, blur: 10),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: neuTextMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
