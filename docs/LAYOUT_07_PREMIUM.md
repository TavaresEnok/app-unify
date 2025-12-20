# Layout 07 – Pôr‑do‑Sol Tropical (Versão ChatGPT)

Código revisado conforme instruções do ChatGPT, com correções técnicas para APIs deprecadas.

## � Características

- **Cards empilhados** (Status e Fatura)
- **Grid de serviços com cores pastéis** (Faturas, Suporte, Wi-Fi, Diagnóstico)
- **BottomNav:** Início, Consumo, Faturas, Suporte
- **Badge do plano semi-transparente** no cabeçalho
- **Botão Diagnóstico Completo** azul sólido

---

## 1. `lib/layouts/layout_07/theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Layout07Theme {
  static const Color headerStart = Color(0xFFFF6B6B);
  static const Color headerMid = Color(0xFFFFB66C);
  static const Color headerEnd = Color(0xFF56CCF2);
  static const Color background = Color(0xFFFFF7EE);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color accent = Color(0xFF2D9CDB);

  static ThemeData getTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      cardColor: cardBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: cardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      iconTheme: const IconThemeData(color: accent),
      cardTheme: CardThemeData(
        color: cardBackground,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static LinearGradient headerGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [headerStart, headerMid, headerEnd],
    );
  }
}
```

---

## 2. `lib/layouts/layout_07/wave_clipper.dart`

```dart
import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height);
    path.quadraticBezierTo(
        size.width * 0.75, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
```

---

## 3. `lib/layouts/layout_07/dashboard_page.dart`

Dashboard com cards empilhados e grid de serviços pastéis.

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';
import 'wave_clipper.dart';

typedef NavigateToPageCallback = void Function(String pageId);

class ProviderDashboardPage extends StatelessWidget {
  final String customerName;
  final String planName;
  final String connectionStatus;
  final double billAmount;
  final double usedGb;
  final double totalGb;
  final double downloadMbps;
  final double uploadMbps;
  final DateTime billDueDate;
  final NavigateToPageCallback onNavigate;
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
    this.onRefresh,
  });

  bool get isConnected =>
      connectionStatus.toLowerCase() == 'ativo' ||
      connectionStatus.toLowerCase() == 'conectado';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => onRefresh?.call(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context, theme),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildStatusCard(context),
                    const SizedBox(height: 16),
                    _buildInvoiceCard(context),
                    const SizedBox(height: 16),
                    _buildServicesGrid(context),
                    const SizedBox(height: 16),
                    _buildDiagnosticButton(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: Layout07Theme.headerGradient()),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      color: Colors.white,
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      color: Colors.white,
                      onPressed: () => onNavigate('notifications'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Olá,', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                Text(customerName, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.signal_cellular_alt, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(planName, style: theme.textTheme.labelMedium?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final connected = isConnected;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (connected ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(connected ? Icons.check_circle : Icons.error, color: connected ? Colors.green.shade700 : Colors.red.shade700, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(connected ? 'Conectado' : 'Desconectado', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(connected ? 'Status Online' : 'Verifique sua rede', style: TextStyle(color: Layout07Theme.textSecondary, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [const Icon(Icons.download, size: 16, color: Layout07Theme.accent), const SizedBox(width: 4), Text('${downloadMbps.toStringAsFixed(1)} Mbps')]),
                Row(children: [const Icon(Icons.upload, size: 16, color: Layout07Theme.accent), const SizedBox(width: 4), Text('${uploadMbps.toStringAsFixed(1)} Mbps')]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context) {
    final daysLeft = billDueDate.difference(DateTime.now()).inDays;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Layout07Theme.accent.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long, color: Layout07Theme.accent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fatura', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('R\$ ${billAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Vence em ${DateFormat("dd/MM/yyyy").format(billDueDate)} (${daysLeft}d)', style: TextStyle(color: Layout07Theme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => onNavigate('invoices'),
              style: ElevatedButton.styleFrom(backgroundColor: Layout07Theme.accent, foregroundColor: Colors.white),
              child: const Text('Ver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 3 / 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _ServiceButton(icon: Icons.receipt_long, label: 'Faturas', color: const Color(0xFFFDECC8), onTap: () => onNavigate('invoices')),
        _ServiceButton(icon: Icons.support_agent, label: 'Suporte', color: const Color(0xFFE0F7FA), onTap: () => onNavigate('support')),
        _ServiceButton(icon: Icons.wifi, label: 'Wi‑Fi', color: const Color(0xFFEFFBF5), onTap: () => onNavigate('wifi')),
        _ServiceButton(icon: Icons.speed, label: 'Diagnóstico', color: const Color(0xFFF6E6F6), onTap: () => onNavigate('network_diagnostic')),
      ],
    );
  }

  Widget _buildDiagnosticButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => onNavigate('network_diagnostic'),
        style: ElevatedButton.styleFrom(backgroundColor: Layout07Theme.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
        child: const Text('Diagnóstico Completo'),
      ),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ServiceButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Layout07Theme.accent, size: 28),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
```

---

## 4. `lib/layouts/layout_07/login_page.dart`

```dart
import 'package:flutter/material.dart';
import 'theme.dart';
import 'wave_clipper.dart';

class LoginPage extends StatefulWidget {
  final Future<void> Function(String cpf)? onLogin;
  final VoidCallback? onBiometricLogin;
  const LoginPage({super.key, this.onLogin, this.onBiometricLogin});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _cpfController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(gradient: Layout07Theme.headerGradient()),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wb_sunny_rounded, size: 64, color: Colors.white.withValues(alpha: 0.9)),
                      const SizedBox(height: 16),
                      Text('Bem‑vindo', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Insira seu CPF/CNPJ', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cpfController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Layout07Theme.cardBackground,
                      hintText: '000.000.000-00',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Layout07Theme.accent)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      final cpf = _cpfController.text.trim();
                      if (cpf.isEmpty) return;
                      setState(() => _isLoading = true);
                      await widget.onLogin?.call(cpf);
                      if (mounted) setState(() => _isLoading = false);
                    },
                    child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Entrar'),
                  ),
                  const SizedBox(height: 24),
                  if (widget.onBiometricLogin != null)
                    OutlinedButton.icon(
                      onPressed: widget.onBiometricLogin,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Entrar com biometria'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎨 Cores do Layout

| Elemento | Cor |
|----------|-----|
| Header Start | `#FF6B6B` (coral) |
| Header Mid | `#FFB66C` (pêssego) |
| Header End | `#56CCF2` (turquesa) |
| Background | `#FFF7EE` (cremoso) |
| Accent | `#2D9CDB` (azul) |
| Faturas | `#FDECC8` (laranja claro) |
| Suporte | `#E0F7FA` (ciano claro) |
| Wi-Fi | `#EFFBF5` (verde claro) |
| Diagnóstico | `#F6E6F6` (rosa claro) |
