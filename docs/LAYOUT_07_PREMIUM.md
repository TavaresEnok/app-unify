# Código Completo do Layout 07 (Pôr-do-Sol Tropical) - Premium

Este documento contém todo o código fonte atualizado para o Layout 07 ("Pôr-do-Sol Tropical"), implementado conforme o mockup fornecido.

## 📱 Preview do Mockup

O layout implementa:
- **Cards Status/Fatura lado a lado**
- **Botões de serviço com gradiente** (Internet, Suporte, TV, Config)
- **Badge do plano amarelo/dourado**
- **Botão Diagnóstico Rápido com gradiente coral-laranja**
- **BottomNav:** Inicio, Relatórios, Services, Conta

---

## 1. `lib/layouts/layout_07/theme.dart`

Define a paleta de cores vibrante, tipografia e estilos globais.

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Layout07Theme {
  // Cores principais
  static const Color headerStart = Color(0xFFFF6B6B); // coral quente
  static const Color headerMid = Color(0xFFFFB66C); // tom de pêssego
  static const Color headerEnd = Color(0xFF56CCF2); // azul‑turquesa
  static const Color background = Color(0xFFFFF7EE); // fundo claro cremoso
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color accent = Color(0xFF2D9CDB); // azul‑verde para destaques

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

Clipper personalizado para o efeito de onda no cabeçalho.

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

Dashboard principal com cards lado a lado e botões com gradiente.

```dart
import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: Layout07Theme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          if (onRefresh != null) await onRefresh!();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildStatusAndInvoiceRow(),
                    const SizedBox(height: 24),
                    _buildServicesSection(),
                    const SizedBox(height: 24),
                    _buildDiagnosticButton(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: Layout07Theme.headerGradient()),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, size: 28),
                      color: Colors.white,
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, size: 28),
                          color: Colors.white,
                          onPressed: () => onNavigate('notifications'),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Olá, $customerName!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F), // Gold/yellow badge
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    planName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAndInvoiceRow() {
    return Row(
      children: [
        Expanded(child: _buildStatusCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildInvoiceCard()),
      ],
    );
  }

  Widget _buildStatusCard() {
    final connected = isConnected;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: connected
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              connected ? Icons.check_circle : Icons.error,
              color: connected ? Colors.green : Colors.red,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            connected ? 'Conectado' : 'Desconectado',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Layout07Theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            connected ? 'Tudo funcionando' : 'Verificar rede',
            style: const TextStyle(fontSize: 12, color: Layout07Theme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard() {
    final day = billDueDate.day.toString().padLeft(2, '0');
    final months = ['', 'Jan', 'Fev', 'Mar', 'Abr', 'Maio', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final monthName = months[billDueDate.month];
    return GestureDetector(
      onTap: () => onNavigate('invoices'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 16, color: Layout07Theme.textSecondary),
                const SizedBox(width: 6),
                const Text('Fatura', style: TextStyle(fontSize: 14, color: Layout07Theme.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${billAmount.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Layout07Theme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text('Vencimento: $day $monthName', style: const TextStyle(fontSize: 12, color: Layout07Theme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Serviços', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Layout07Theme.textPrimary)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _ServiceButton(icon: Icons.wifi, label: 'Internet', gradient: const LinearGradient(colors: [Color(0xFFFF8A65), Color(0xFFFF5722)]), onTap: () => onNavigate('internet_usage'))),
            const SizedBox(width: 12),
            Expanded(child: _ServiceButton(icon: Icons.headset_mic, label: 'Suporte', gradient: const LinearGradient(colors: [Color(0xFF4DD0E1), Color(0xFF00ACC1)]), onTap: () => onNavigate('support'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ServiceButton(icon: Icons.tv, label: 'TV', gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFC107)]), onTap: () => onNavigate('contract'))),
            const SizedBox(width: 12),
            Expanded(child: _ServiceButton(icon: Icons.settings, label: 'Config', gradient: const LinearGradient(colors: [Color(0xFFB39DDB), Color(0xFF7E57C2)]), onTap: () => onNavigate('wifi'))),
          ],
        ),
      ],
    );
  }

  Widget _buildDiagnosticButton() {
    return GestureDetector(
      onTap: () => onNavigate('network_diagnostic'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF8A65), Color(0xFFFF5722)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5722).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text('Diagnóstico Rápido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ServiceButton({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
```

---

## 4. `lib/layouts/layout_07/login_page.dart`

Página de login estilizada com ondas e suporte a biometria.

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
                  Text('Insira seu CPF/CNPJ', style: theme.textTheme.titleMedium?.copyWith(color: Layout07Theme.textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cpfController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Layout07Theme.cardBackground,
                      hintText: '000.000.000-00',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      if (widget.onLogin != null) await widget.onLogin!(cpf);
                      if (!mounted) return;
                      setState(() => _isLoading = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Layout07Theme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Entrar', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 24),
                  if (widget.onBiometricLogin != null)
                    OutlinedButton.icon(
                      onPressed: widget.onBiometricLogin,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Entrar com biometria'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Layout07Theme.accent,
                        side: const BorderSide(color: Layout07Theme.accent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
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

## 📌 Configuração no PainelPage

O `lib/core/painel_page.dart` foi atualizado com:

1. **BottomNavigationBar específica para Layout 07:**
   - Inicio, Relatórios, Services, Conta

2. **Métodos de navegação dedicados:**
   - `_getLayout07NavIndex()` - Retorna o índice correto baseado na página atual
   - `_onLayout07NavTap()` - Navega para a página correta ao tocar

---

## 🎨 Cores e Gradientes

| Elemento | Cores |
|----------|-------|
| Header | `#FF6B6B` → `#FFB66C` → `#56CCF2` |
| Internet | `#FF8A65` → `#FF5722` |
| Suporte | `#4DD0E1` → `#00ACC1` |
| TV | `#FFD54F` → `#FFC107` |
| Config | `#B39DDB` → `#7E57C2` |
| Badge Plano | `#FFD54F` (amarelo/dourado) |
| Accent | `#2D9CDB` (azul-turquesa) |
