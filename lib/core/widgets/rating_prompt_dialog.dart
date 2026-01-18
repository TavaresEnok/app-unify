import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    if (await shouldShow()) {
      if (context.mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
            'rating_last_shown', DateTime.now().millisecondsSinceEpoch);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const RatingPromptDialog(),
        );
      }
    }
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

      // Abrir Play Store (substitua pelo package name real)
      const playStoreUrl =
          'https://play.google.com/store/apps/details?id=com.provedor.app';
      if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
        await launchUrl(Uri.parse(playStoreUrl),
            mode: LaunchMode.externalApplication);
      }
    } else if (_selectedRating > 0) {
      // Avaliação negativa - agradecer e não mostrar mais
      await prefs.setBool('rating_never_show', true);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Obrigado pelo feedback! Vamos melhorar.'),
            backgroundColor: Colors.green,
          ),
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
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji animado
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('⭐', style: TextStyle(fontSize: 40)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gostando do App?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sua avaliação nos ajuda a melhorar!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Stars rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = index + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      index < _selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 44,
                      color: index < _selectedRating
                          ? const Color(0xFFFBBF24)
                          : Colors.grey[300],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedRating > 0 ? _submitRating : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Enviar Avaliação',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _remindLater,
                  child: Text(
                    'Depois',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _neverShow,
                  child: Text(
                    'Não mostrar',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
