import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

class ConsumoPage extends ConsumerStatefulWidget {
  const ConsumoPage({super.key});

  @override
  ConsumerState<ConsumoPage> createState() => _ConsumoPageState();
}

class _ConsumoPageState extends ConsumerState<ConsumoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final configProvider = ref.watch(configurationProvider);
    final usuario = authState.value;
    final config = configProvider.providerConfig;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh user data if needed
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card principal - Plano Ilimitado
            _buildUnlimitedCard(theme, usuario?.plano ?? 'Plano Fibra',
                config?.name ?? 'Provedor'),

            const SizedBox(height: 16),

            // Card de velocidades
            _buildSpeedCard(theme, usuario),

            const SizedBox(height: 16),

            // Card de status da conexão
            _buildConnectionStatusCard(theme),

            const SizedBox(height: 16),

            // Card de benefícios
            _buildBenefitsCard(theme),

            const SizedBox(height: 180), // Padding for BottomNav
          ],
        ),
      ),
    );
  }

  Widget _buildUnlimitedCard(
      ThemeData theme, String planName, String providerName) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Ícone de infinito animado
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.all_inclusive,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              '∞ ILIMITADO',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Navegue sem limites!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                planName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedCard(ThemeData theme, dynamic usuario) {
    // Extract speed from plan name (e.g., "100 Mega" -> 100)
    String speedValue = '100';
    String planName = usuario?.plano ?? 'Plano Fibra';
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(planName);
    if (match != null) {
      speedValue = match.group(1)!;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: theme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Velocidades Contratadas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSpeedItem(
                    theme,
                    'Download',
                    '$speedValue Mbps',
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: theme.dividerColor,
                ),
                Expanded(
                  child: _buildSpeedItem(
                    theme,
                    'Upload',
                    '$speedValue Mbps',
                    Icons.arrow_upward,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedItem(
      ThemeData theme, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatusCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi, color: theme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Status da Conexão',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Ativo',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatusRow(
                theme, 'Tipo de Conexão', 'Fibra Óptica', Icons.cable),
            _buildStatusRow(
                theme, 'Franquia', 'Ilimitada', Icons.all_inclusive),
            _buildStatusRow(
                theme, 'Fidelidade', 'Sem fidelidade', Icons.lock_open),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
      ThemeData theme, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 12),
                Text(
                  'Benefícios do Seu Plano',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(theme, Icons.all_inclusive, 'Internet ilimitada'),
            _buildBenefitItem(theme, Icons.bolt, 'Velocidade garantida'),
            _buildBenefitItem(theme, Icons.support_agent, 'Suporte 24/7'),
            _buildBenefitItem(theme, Icons.router, 'Wi-Fi de alta qualidade'),
            _buildBenefitItem(theme, Icons.security, 'Conexão segura'),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
