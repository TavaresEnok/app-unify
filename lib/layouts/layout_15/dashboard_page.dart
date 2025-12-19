import 'package:flutter/material.dart';

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
    // Layout 15: Dynamic Grid / Modular
    // AI Inspiration: "Bento Grids", "Drag and Drop", "Vibrant"

    // We'll use a standard GridView here instead of StaggeredGrid to avoid missing package issues if not installed.
    // If the user wants true staggered, we'd add it to pubspec.yaml.
    // For now, let's build a nice Masonry-like look with standard columns or a custom view.

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Dynamic Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage(
                            "https://i.pravatar.cc/150?img=12"), // Dynamic avatar placeholder
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Bom dia,",
                          style: TextStyle(color: Colors.grey)),
                      Text(customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.widgets_outlined),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Modular Grid
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (onRefresh != null) await onRefresh!();
                  },
                  child: ListView(
                    children: [
                      // Row 1: Main Status + Plan
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _ModuleCard(
                              height: 180,
                              color: const Color(0xFF6366F1), // Indigo
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.wifi_tethering,
                                      color: Colors.white, size: 30),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(connectionStatus,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20)),
                                      Text(planName,
                                          style: const TextStyle(
                                              color: Colors.white70)),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => onNavigate('wifi'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: _ModuleCard(
                              height: 180,
                              color: Colors.white,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                      value: 0.8, color: Colors.indigo),
                                  const SizedBox(height: 8),
                                  Text("${downloadMbps.toInt()}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22)),
                                  const Text("Mbps",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                              onTap: () => onNavigate('speed_test'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 2: Finance (Wide)
                      _ModuleCard(
                        height: 140,
                        color: const Color(0xFF10B981), // Emerald
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Fatura Atual",
                                    style: TextStyle(color: Colors.white70)),
                                Text("R\$ ${billAmount.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 32)),
                              ],
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.white24,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward,
                                    color: Colors.white),
                                onPressed: () => onNavigate('invoices'),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => onNavigate('invoices'),
                      ),

                      const SizedBox(height: 12),

                      // Row 3: Small Actions
                      Row(
                        children: [
                          Expanded(
                              child: _ModuleCard(
                                  color: Colors.orange,
                                  height: 100,
                                  child: const Icon(Icons.support_agent,
                                      color: Colors.white),
                                  onTap: () => onNavigate('support'))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _ModuleCard(
                                  color: Colors.pink,
                                  height: 100,
                                  child: const Icon(Icons.description,
                                      color: Colors.white),
                                  onTap: () {})),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _ModuleCard(
                                  color: Colors.blue,
                                  height: 100,
                                  child: const Icon(Icons.settings,
                                      color: Colors.white),
                                  onTap: () {})),
                        ],
                      ),
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

class _ModuleCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double height;
  final VoidCallback onTap;

  const _ModuleCard(
      {required this.child,
      required this.color,
      required this.height,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      ),
    );
  }
}
