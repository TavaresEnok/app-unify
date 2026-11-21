import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/providers.dart';
import '../vibe/vibe_icon.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialog de avaliação do app
class RatingPromptDialog extends StatefulWidget {
  const RatingPromptDialog({super.key});

  /// Verifica se deve mostrar o prompt de avaliação
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();

    // Nunca mostrar novamente se já avaliou ou disse "não"
    if (prefs.getBool('rating_never_show') == true) return false;

    // Verificar se já mostrou recentemente (a cada 7 dias)
    final lastShown = prefs.getInt('rating_last_shown') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysSinceLastShow = (now - lastShown) / (1000 * 60 * 60 * 24);

    if (daysSinceLastShow < 7) return false;

    // Verificar se usou o app pelo menos 3 vezes
    final usageCount = prefs.getInt('app_usage_count') ?? 0;
    if (usageCount < 3) return false;

    return true;
  }

  /// Incrementa contador de uso do app
  static Future<void> incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('app_usage_count') ?? 0;
    await prefs.setInt('app_usage_count', count + 1);
  }

  /// Mostra o dialog se necessário
  static Future<void> showIfNeeded(BuildContext context) async {
    if (!await shouldShow() || !context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'rating_last_shown', DateTime.now().millisecondsSinceEpoch);
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RatingPromptDialog(),
    );
  }

  @override
  State<RatingPromptDialog> createState() => _RatingPromptDialogState();
}

class _RatingPromptDialogState extends State<RatingPromptDialog> {
  int _selectedRating = 0;

  Future<void> _submitRating() async {
    final prefs = await SharedPreferences.getInstance();

    if (_selectedRating >= 4) {
      // Avaliação positiva - direcionar para Play Store
      await prefs.setBool('rating_never_show', true);
      if (mounted) Navigator.pop(context);

      // A página do próprio app na loja, pelo identificador instalado.
      try {
        final package = (await PackageInfo.fromPlatform()).packageName;
        await launchUrl(
            Uri.parse('https://play.google.com/store/apps/details?id=$package'),
            mode: LaunchMode.externalApplication);
      } catch (_) {
        // Sem loja disponível, a nota fica só registrada como dada.
      }
    } else if (_selectedRating > 0) {
      // Avaliação negativa - agradecer e não mostrar mais
      await prefs.setBool('rating_never_show', true);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Obrigado pela avaliação. Vamos melhorar.')),
        );
      }
    }
  }

  Future<void> _remindLater() async {
    Navigator.pop(context);
  }

  Future<void> _neverShow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rating_never_show', true);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Consumer(builder: (context, ref, _) {
        final t = ref.watch(layoutTokensProvider).vibe;
        final rated = _selectedRating > 0;
        return Dialog(
          backgroundColor: t.card,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.rad < 14 ? 14 : t.rad)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: t.ac, borderRadius: BorderRadius.circular(18)),
                child: VibeIcon('g-star', size: 26, color: t.on),
              ),
              const SizedBox(height: 14),
              Semantics(
                header: true,
                child: Text('Está gostando do app?',
                    textAlign: TextAlign.center,
                    style: vibeText(t, 19, 800, letterSpacingEm: -.01)),
              ),
              const SizedBox(height: 6),
              Text('Sua nota ajuda a melhorar o atendimento pelo app.',
                  textAlign: TextAlign.center,
                  style: vibeText(t, 13.5, 500, color: t.mut, height: 1.45)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var star = 1; star <= 5; star++)
                  Semantics(
                    button: true,
                    selected: star == _selectedRating,
                    label: '$star ${star == 1 ? 'estrela' : 'estrelas'}',
                    excludeSemantics: true,
                    child: InkResponse(
                      radius: 26,
                      onTap: () => setState(() => _selectedRating = star),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: star <= _selectedRating
                                  ? const Color(0xFFFEF0C7)
                                  : t.ink.withValues(alpha: .07),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: VibeIcon('g-star',
                                size: 20,
                                color: star <= _selectedRating
                                    ? const Color(0xFFB54708)
                                    : t.mut),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 18),
              VibePageButton(
                  label: 'Enviar avaliação',
                  onPressed: rated ? _submitRating : null),
              const SizedBox(height: 8),
              VibeTwo(
                VibePageButton(
                    label: 'Depois', ghost: true, onPressed: _remindLater),
                VibePageButton(
                    label: 'Não mostrar', ghost: true, onPressed: _neverShow),
              ),
            ]),
          ),
        );
      });
}
