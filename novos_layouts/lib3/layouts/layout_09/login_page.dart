import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/models/usuario.dart';
import '../../core/models/provider_config.dart';
import '../../core/providers/providers.dart';
import 'widgets/aurora_background.dart';
import 'widgets/frosted_card.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final configProvider = ref.read(configurationProvider);
    final config = configProvider.providerConfig;

    if (_cpfController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Por favor, digite seu CPF/CNPJ');
      HapticFeedback.vibrate();
      return;
    }

    if (config == null) {
      setState(() => _errorMessage = 'Erro de configuração');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await ref
        .read(authNotifierProvider.notifier)
        .login(_cpfController.text.trim(), config);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Falha no login: ${next.error.toString().replaceAll('Exception:', '').trim()}';
        });
      } else if (next is AsyncData && next.value != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
    });

    final ProviderConfig? config = ref.watch(configurationProvider).providerConfig;

    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;

                final content = _LoginFormCard(
                  config: config,
                  cpfController: _cpfController,
                  errorMessage: _errorMessage,
                  isLoading: _isLoading,
                  onSubmit: () {
                    HapticFeedback.lightImpact();
                    _handleLogin();
                  },
                );

                if (!wide) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BrandHeader(config: config),
                        const SizedBox(height: 18),
                        Text(
                          'Acesse sua conta',
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie faturas, suporte e diagnósticos em um só lugar.',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.70),
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        content,
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 18, 28),
                        child: FrostedCard(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BrandHeader(config: config),
                              const Spacer(),
                              Text(
                                'Layout 09',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Um visual novo,\nsem mudar seus fluxos.',
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _FeatureRow(
                                icon: Icons.receipt_long_rounded,
                                text: 'Faturas e pagamentos',
                              ),
                              const SizedBox(height: 10),
                              _FeatureRow(
                                icon: Icons.support_agent_rounded,
                                text: 'Suporte e notificações',
                              ),
                              const SizedBox(height: 10),
                              _FeatureRow(
                                icon: Icons.analytics_rounded,
                                text: 'Diagnóstico, traceroute e velocidade',
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 28, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Acesse sua conta',
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Digite seu CPF/CNPJ para continuar.',
                              style: TextStyle(
                                color: onSurface.withValues(alpha: 0.70),
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 18),
                            content,
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final ProviderConfig? config;

  const _BrandHeader({required this.config});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).cardColor;

    return Center(
      child: Container(
        width: 92,
        height: 92,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
        child: (config?.config.logoUrl != null)
            ? CachedNetworkImage(
                imageUrl: config!.config.logoUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) =>
                    Image.asset('assets/images/ajust.png', fit: BoxFit.contain),
              )
            : Image.asset('assets/images/ajust.png', fit: BoxFit.contain),
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  final ProviderConfig? config;
  final TextEditingController cpfController;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _LoginFormCard({
    required this.config,
    required this.cpfController,
    required this.errorMessage,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CPF / CNPJ',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: cpfController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: '000.000.000-00',
              prefixIcon: Icon(Icons.person_outline_rounded, color: scheme.primary),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.error.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: scheme.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: scheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Text(
                      'Entrar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.80),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
